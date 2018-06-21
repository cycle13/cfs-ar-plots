;=================================================================================
; cfs_lib_ivt.ncl:
; --------------------------------------------------------------------------------
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib_gen.ncl"
;=================================================================================




; 4) --- get_ivt_vars()
; =====================
undef("get_ivt_vars")
function get_ivt_vars(indir)
local first_file, f1, LEV, all_files, fall, U, V, q, times
begin
    ;---DATA DICTIONARY----------------------------------------------
    ;
    ;  U-wind:      UGRD_P0_L100_GLL0(plev, lat, lon)  [m/s]
    ;  V-wind:      VGRD_P0_L100_GLL0(plev, lat, lon)  [m/s]
    ;  q-spc_hum:   SPFH_P0_L100_GLL0(plev, lat, lon)  [kg/kg]
    ;
    ;  IVT:         IVT(lat, lon)                      [kg/ms]
    ;----------------------------------------------------------------

    ;---PARAMETERS
    ;---Read in pressure levels from first file
    first_file = systemfunc("ls " + indir + "/" + "pgb*.grb2 | head -1")     
    f1         = addfile(first_file, "r")
    LEV        = f1->lv_ISBL0    ; Pa
    printVarSummary(LEV)


    ;---Use systemfunc/ls
    print("Getting file list from directory: " + indir + "...")
    all_files = systemfunc("ls " + indir + "/" + "pgb*.grb2")
    printVarSummary(all_files)

    ;---Open files using addfiles
    print("Adding files: " + all_files + "...")
    fall = addfiles (all_files, "r")
    printVarSummary(fall)

    ;---Read in files using "join" mode
    print("Joining along time dim...")
    ListSetType (fall, "join")
    printVarSummary(fall)

    ;---Get Variables: U, V, q
    print("Retrieving / joining U...")
    U     = fall[:]->UGRD_P0_L100_GLL0     ; U-component wind, on an isobaric surface [m/s]
    print("Retrieving / joining V...")
    V     = fall[:]->VGRD_P0_L100_GLL0     ; V-component wind, on an isobaric surface [m/s]
    print("Retrieving / joining q...")
    q     = fall[:]->SPFH_P0_L100_GLL0     ; q specific humidity, on an isobaric surface [kg/kg]
    print("Retrieving / joining times...")
    times = fall[:]->SPFH_P0_L100_GLL0@initial_time ; get times


    ;---Reverse lat dimension.   orig: 90..-90   |-->   new: -90..90
    print("Reversing lat dimension...")
    U     = U(:,:,::-1,:)             ; reorder to South -> North
    V     = V(:,:,::-1,:)
    q     = q(:,:,::-1,:)

  return [/times, LEV, U, V, q/]
end




; 5) --- calc_ivt()
; =================
undef("calc_ivt")
function calc_ivt(PLEV, u, v, q, Psfc, Ptop)
local g, ivt_u, ivt_v, ivt_mag, dp, plev_dim
begin
    ;---DATA DICTIONARY----------------------------------------------
    ;  IVT = 1/g S_p V*q*dp [kg/ms]
    ;
    ;  FAILDE
    ;  ivt_u    = (1/g) * wgt_vertical_n(q_u, dp, vopt, plev_dim)
    ;  ivt_v    = (1/g) * wgt_vertical_n(q_v, dp, vopt, plev_dim)
    ;  ivt_mag  = (1/g) * wgt_vertical_n(QV_mag, dp, vopt, plev_dim)
    ;----------------------------------------------------------------


    ;---IVT_u, u-component
    q_u                 = q * u
    copy_VarAtts(u,   q_u)
    copy_VarCoords(u, q_u)
    ivt_u               = vert_p_intgrl(PLEV, Psfc, Ptop, q_u)
    ivt_u@long_name     = "Integrated Vapor Transport - U-component"
    ivt_u@units         = "kg m^-1 s^-1"



    ;---IVT_v, v-component: vertical integral
    q_v                 = q * v
    copy_VarAtts(v,   q_v)
    copy_VarCoords(v, q_v)
    ivt_v               = vert_p_intgrl(PLEV, Psfc, Ptop, q_v)
    ivt_v@long_name     = "Integrated Vapor Transport - V-component"
    ivt_v@units         = "kg m^-1 s^-1"



    ;---IVT_mag, magnitude (total vector): vertical integration
    QV_mag            = sqrt( (q_u * q_u) + (q_v * q_v) )
    copy_VarAtts(v,   QV_mag)
    copy_VarCoords(v, QV_mag)
    ivt_mag           = vert_p_intgrl(PLEV, Psfc, Ptop, QV_mag)
    ivt_mag@long_name = "Integrated Vapor Transport - Magnitude"
    ivt_mag@units     = "kg m^-1 s^-1"

  return [/ivt_u, ivt_v, ivt_mag/]
end





; 6) --- plot_ivt()
; =================
undef("plot_ivt")
function plot_ivt(Times, ivt_u, ivt_v, ivt_mag, outdir)
local TEST, outtype, outbase, ret, junk, Tdim, Tsize, nt, 
      ntStrt, ntLast, res, nt_padded, outfile, nt_padded, 
      wks, vector_ivt
begin
    ;---DATA DICTIONARY----------------------------------------------
    ;
    ;----------------------------------------------------------------
    ;---PARAMETERS
    TEST     = True
    outtype  = "png"
    outbase  = "cfs_ivt"

    ;---Check/create output directory
    ret = systemfunc("test -d " + outdir + "; echo $?")
    if (0 .ne. ret) then
	junk = systemfunc("mkdir -pv " + outdir)
    else
	junk = systemfunc("rm    -rf " + outdir)
	junk = systemfunc("mkdir -pv " + outdir)
    end if

    ; get number of time steps
    Tdim  = dimsizes(Times)
    Tsize = Tdim(0)
   
    ;---Time period parameters
    if (TEST) then
	ntStrt = 0
	ntLast = 0
    else
	ntStrt = 0
	ntLast = Tsize-1
    end if


    ; ***************************************
    ;       PLOT SET-UP
    ; **************************************
    ;---Set common resources for all plots
    res                       = True
    res@gsnFrame              = True
    res@gsnDraw               = True
    res@gsnRightString        = ivt_u@units

    ;---Location  (currently, centered over Pacific basin)
    res@mpCenterLonF          = 177.5
    res@mpMaxLatF             =  55           ; choose subregion           
    res@mpMinLatF             =   0
    res@mpMaxLonF             = 260
    res@mpMinLonF             =  95

    ;---Wind vector plot
    res                       = res
    res@vcMinDistanceF        = 0.1
    res@vcRefLengthF          = 0.04
    res@vcMinFracLengthF      = 0.2
    res@vcLineArrowThicknessF = 3.0
    res@vcGlyphStyle          = "LineArrow"
    res@vcRefAnnoOn           = False




    ;---LOOP(time)
    print(" ")
    print("LOOP over dim: time=" + ntStrt + ".." + ntLast)
    do nt=ntStrt,ntLast

        ;---Get time step, padded if necessary. 3-digit default.
        if (nt .lt. 10) then
            nt_padded         = "00" + nt
        else if (nt .lt. 100) then
            nt_padded         = "0"  + nt
        else
            nt_padded         = nt
        end if
        end if
        print(" ")
        print("t=" + nt_padded)

        ;---Get plot workstation, related
        print("Opening workstation...")
        outfile               = outdir + "/" + outbase + "_t" + nt_padded
        wks                   = gsn_open_wks(outtype,outfile)

        res@gsnLeftString     = Times(nt) + "    IVT"
        print("Plotting call...")
        vector_ivt            = gsn_csm_vector_map(wks,ivt_u(nt,:,:),ivt_v(nt,:,:),res)
        print("Done plotting.")
    end do

  return vector_ivt
end
