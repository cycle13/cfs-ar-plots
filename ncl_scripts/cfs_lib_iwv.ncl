;=================================================================================
; cfs_lib_iwv.ncl:
; --------------------------------------------------------------------------------
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncl_scripts/cfs_lib_gen.ncl"
;=================================================================================


; 7) --- get_iwv_vars()
; =====================
undef("get_iwv_vars")
function get_iwv_vars(indir, TEST_FLAG)
local first_file, f1, LEV, all_files, fall, q, times
begin
    ;---DATA DICTIONARY----------------------------------------------
    ;
    ;  q-spc_hum:   SPFH_P0_L100_GLL0(plev, lat, lon)  [kg/kg]
    ;
    ;  IWV:         IWV(lat, lon)                      [kg/m^2 = mm]
    ;----------------------------------------------------------------

    ;---PARAMETERS
    ;---Read in pressure levels from first file
    first_file = systemfunc("ls " + indir + "/" + "pgb*.grb2 | head -1")     
    f1         = addfile(first_file, "r")
    LEV        = f1->lv_ISBL0    ; Pa
    printVarSummary(LEV)


    ;---Use systemfunc/ls
    print("Getting file list from directory: " + indir + "...")
    if (TEST_FLAG) then
        all_files = systemfunc("ls " + indir + "/" + "pgb*.grb2 | head -2")
    else
        all_files = systemfunc("ls " + indir + "/" + "pgb*.grb2")
    end if
    printVarSummary(all_files)

    ;---Open files using addfiles
    print("Adding files: " + all_files + "...")
    fall = addfiles (all_files, "r")
    printVarSummary(fall)

    ;---Read in files using "join" mode
    print("Joining along time dim...")
    ListSetType (fall, "join")
    printVarSummary(fall)

    ;---Get Variable: q
    print("Retrieving / joining q...")
    q     = fall[:]->SPFH_P0_L100_GLL0     ; q specific humidity, on an isobaric surface [kg/kg]
    print("Retrieving / joining times...")
    times = fall[:]->SPFH_P0_L100_GLL0@initial_time ; get times

    ;---Reverse lat dimension.   orig: 90..-90   |-->   new: -90..90
    print("Reversing lat dimension...")
    q     = q(:,:,::-1,:)

  return [/times, LEV, q/]
end



; 8) --- calc_iwv()
; =================
undef("calc_iwv")
function calc_iwv(Plev, Psfc, Ptop, q)
local iwv
begin
    ;---DATA DICTIONARY----------------------------------------------
    ;  IWV = 1/g S_p q*dp [kg m^-2 == mm]
    ;----------------------------------------------------------------

    ; Vertical pressure integration
    iwv              =  vert_p_intgrl(Plev, Psfc, Ptop, q)

    ; Meta data fiddling
    q!0  = "time"
    q!1  = "lev"
    q!2  = "lat"
    q!3  = "lon"
    q_reorder        = q(time|:, lat|:, lon|:, lev|:)
    copy_VarCoords_1(q_reorder, iwv)
    iwv@long_name    = "Integrated Water Vapor"
    iwv@units        = "mm"
    iwv@initial_time = q@initial_time
  
    printVarSummary(iwv)
    printMinMax(iwv,1)
  return iwv
end



; 9) --- plot_iwv()
; =================
undef("plot_iwv")                     
function plot_iwv(Times, Psfc, Ptop, iwv, IWV_MIN, outdir)
local ret, junk, dims, ntim, nlat, mlon, ntStrt, ntLast,
      outfile, res, resP, nt, nt_padded, wks, plot, outtype, outbase
begin
     ;---PARAMETERS
     outtype  = "png"
     outbase  = "iwv"

     ;---Check/create output directory
     ret = systemfunc("test -d " + outdir + "; echo $?")
     if (0 .ne. ret) then
         junk = systemfunc("mkdir -pv " + outdir)
     else
         junk = systemfunc("rm    -rf " + outdir)
         junk = systemfunc("mkdir -pv " + outdir)
     end if
  
     ;---Get iwv dims
     dims = dimsizes(iwv)
     ntim = dims(0)
     nlat = dims(1)
     mlon = dims(2)

     ;---Time period parameters
     ntStrt = 0
     ntLast = ntim-1

     ; get integer values for P levels, and units in hPa (= mb) for display
     if ( Psfc .ge. 100000.0 ) then
         Psfc = 1000
     end if
     if ( Ptop .ge. 30000.0 ) then
         Ptop = 300
     else
         Ptop = 100
     end if


     ;---General plot resources (res)
     res                      = True
     res@gsnDraw              = True
     res@gsnFrame             = True
     res@cnFillOn             = True                 ; turn on color fill
     res@cnLinesOn            = True
     res@cnLineLabelsOn       = False
     res@cnLevelSelectionMode = "ManualLevels"       ; manually set contour levels
     res@cnMinLevelValF       = IWV_MIN                 ; minimum contour level
     res@cnMaxLevelValF       = 70.0                 ; maximum contour level
     res@cnLevelSpacingF      =  5.0                 ; interval between contours
     res@lbOrientation        = "Vertical"   
     res@gsnCenterString      = "IWV(Psfc:" + Psfc + "mb, Ptop:" + Ptop + "mb)"

     ;---Location  (currently, centered over Pacific basin)
     res@mpCenterLonF         = 177.5
     res@mpMaxLatF            =  55           ; choose subregion           
     res@mpMinLatF            =   0
     res@mpMaxLonF            = 260
     res@mpMinLonF            =  95
     res@mpFillOn             = True
     res@mpFillColors         = (/0,-1,28,-1/)



     ;---LOOP(time)
     print(" ")
     print("LOOP over dim: time=" + ntStrt + ".." + ntLast)
     do nt=ntStrt,ntLast

        ;---Get time step, padded if necessary. 3-digit default.
        if (nt .lt. 10) then
            nt_padded = "00" + nt
        else if (nt .lt. 100) then
            nt_padded = "0"  + nt
        else
            nt_padded =        nt
        end if
        end if
        print(" ")
        print("t=" + nt_padded)


        ;---Get plot workstation, related
        print("Opening a workstation...")
        outfile               = outdir + "/" + "cfs_iwv_t" + nt_padded
        wks                   = gsn_open_wks(outtype,outfile)
        gsn_define_colormap(wks,"matlab_jet")
        gsn_reverse_colormap(wks)           ; Reverse the color map.

        ;---Call plot routine
        print("Call to plot routine...")
        res@gsnLeftString     = Times(nt) + " UTC"
        plot = gsn_csm_contour_map(wks,iwv(nt,:,:),res)   

        print("OUTPUT FILE: "+outfile+"."+outtype)
     end do

  return plot
end




;=================================================================================
; cfs_iwv():  Calculates and plots contours of Integrated Water Vapor (IWV).
; --------------------------------------------------------------------------------
undef("cfs_iwv")
function cfs_iwv(IWV_MIN, indir, outpth, TEST)
local dirtag, fidtag, Psfc, Ptop, outdir, Q, Times, PLEV, q, iwv, plotiwv
begin
    ;---PARAMETERS
    dirtag  = "test"
    fidtag  = "iwv"
    Psfc    = 100001.0     ; [Pa]   Must be > 100000.0
    Ptop    =  30000.0     ; [Pa]
    outdir  = outpth + "/" + fidtag + "/" + dirtag



    ;---GET VARIABLES
    print("Getting variable: q...")
    Q       = get_iwv_vars(indir, TEST)
    Times   = Q[0]
    PLEV    = Q[1]
    q       = Q[2]
    delete(Q)
    if (TEST) then
        printVarSummary(PLEV)
        printVarSummary(q)
    end if

    ;---CALC IWV
    print("Calculating IWV...")
    iwv     = calc_iwv(PLEV, Psfc, Ptop, q)
    if (TEST) then
        printVarSummary(iwv)
    end if


    ;---PLOT IWV
    print("Plotting IWV...")
    plotiwv = plot_iwv(Times, Psfc, Ptop, iwv, IWV_MIN, outdir)

    return plotiwv
end

