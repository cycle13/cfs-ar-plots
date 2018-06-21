;=================================================================================
; cfs_lib_ipv.ncl:
; --------------------------------------------------------------------------------
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib_gen.ncl"
;=================================================================================



; 1) --- get_ipv_vars()
; =====================
undef("get_ipv_vars")
function get_ipv_vars(indir)
local first_file, f1, LEV, all_files, fall, times
begin
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

    ;---Get Variables: U, V, T
    print("Retrieving / joining U...")
    U     = fall[:]->UGRD_P0_L100_GLL0  ; U-component wind, on an isobaric surface [m/s]
    print("Retrieving / joining V...")
    V     = fall[:]->VGRD_P0_L100_GLL0  ; V-component wind, on an isobaric surface [m/s]
    print("Retrieving / joining T...")
    T     = fall[:]->TMP_P0_L100_GLL0   ; Temperature, on an isobaric surface      [K]
    print("Retrieving / joining times...")
    times = fall[:]->TMP_P0_L100_GLL0@initial_time ; get times


    ;---Reverse lat dimension.   orig: 90..-90   |-->   new: -90..90
    print("Reversing lat dimension...")
    U     = U(:,:,::-1,:)             ; reorder to South -> North
    V     = V(:,:,::-1,:)
    T     = T(:,:,::-1,:)

  return [/times, LEV, U, V, T/]
end



; 2) --- calc_ipv()
; =================
undef("calc_ipv")
function calc_ipv(plev,u,v,t,ilev)
local PV, gridType, opt, pv, s, theta
begin
     ;---PARAMETERS
     gridType = 0                           ; 0: gaussian,  1: reqular (?)
     opt      = 1                           ; 0: pv only,   1: list (pv, s, theta)

     ;---Calcualate PV on isobaric surfaces     
     print("Calculating PV on isobaric surfaces...")
     PV     = pot_vort_isobaric(plev, u, v, t, t&lat_0, gridType, opt)
     pv     = PV[0]          ; extract PV (pv)
     s      = PV[1]          ; extract static stability (s)
     theta  = PV[2]          ; extract potential temperature (theta)

     ;---Display summary + min/max values
     printVarSummary(PV)
     printVarSummary(pv)
     printMinMax(pv,0)
     printVarSummary(s)
     printMinMax(s,0)
     printVarSummary(theta)
     printMinMax(theta,0)

     ;---Convert pv to PVU's:  1 PVU == 10^-6 m^2 s^-1 K kg^-1
     pv       = pv * 10^6
     pv@units = "PVU [10^-6 m^2 s^-1 K kg^-1]"

     ; Meta 
     pv@long_name = "Potential Vorticity (Isobaric)"
     pv!1         = "lev"

     printVarSummary(pv)
     printMinMax(pv,0)

     ;---Interpolate pv from isobaric (P) levels to isentropic (theta) levels
     print("Interpolating pv from isobars to isentropes...")
     ipv = int2p_n_Wrap (theta, pv, ilev, 0, 1)
     ipv@long_name = "Isentropic Potential Vorticity"

  return [/ilev, ipv/]
end



; 3) --- plot_ipv()
; =================
undef("plot_ipv")
function plot_ipv(times, ilev, ipv, outdir)
local TEST, ret, junk, dims, ntim, klev, nlat, mlon, ntStrt, ntLast,
      outfile, res, resP, nt, nt_padded, wks, plot, outtype
begin
     ;---PARAMETERS
     TEST     = False
     outtype  = "png"

     ;---Check/create output directory
     ret = systemfunc("test -d " + outdir + "; echo $?")
     if (0 .ne. ret) then
         junk = systemfunc("mkdir -pv " + outdir)
     else
         junk = systemfunc("rm    -rf " + outdir)
         junk = systemfunc("mkdir -pv " + outdir)
     end if

  
     ;---Get ipv dims
     dims = dimsizes(ipv)
     klev = dims(0)
     ntim = dims(1)
     nlat = dims(2)
     mlon = dims(3)

     ;---Time period parameters
     if (TEST) then
         ntStrt      = 0
         ntLast      = 0
     else
         ntStrt = 0
         ntLast = ntim-1
     end if


     ;---General plot resources (res)
     res                      = True
     res@gsnDraw              = True
     res@gsnFrame             = True
     res@cnFillOn             = True                 ; turn on color fill
     res@cnLinesOn            = True
     res@cnLineLabelsOn       = False
     res@cnLevelSelectionMode = "ManualLevels"       ; manually set contour levels
     res@cnMinLevelValF       = 0.5                 ; minimum contour level
     res@cnMaxLevelValF       = 5.0                  ; maximum contour level
     res@cnLevelSpacingF      = 0.25                 ; interval between contours
     res@lbOrientation        = "Vertical"   
     res@gsnCenterString      = "IPV(Theta="+ilev+"K)"

     ;---Location  (currently, centered over Pacific basin)
     res@mpCenterLonF         = 177.5
     res@mpMaxLatF            =  55           ; choose subregion           
     res@mpMinLatF            =   0
     res@mpMaxLonF            = 260
     res@mpMinLonF            =  95
     res@mpFillOn             = True
     res@mpFillColors         = (/0,-1,28,-1/)

     ;---Panel plot resources (resP)
     resP                     = True
     resP@gsnMaximize         = True  


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
        print("Opening workstation...")
        outfile               = outdir + "/" + "cfs_ipv_t" + nt_padded
        wks                   = gsn_open_wks(outtype,outfile)

        ;---Call plot routine
        print("Plotting call...")
        res@gsnLeftString     = times(nt)
        plot = gsn_csm_contour_map(wks,ipv(nt,0,:,:),res)   
        print("Done plotting.")
        print("OUTPUT FILE: "+outfile+"."+outtype)
     end do

  return plot
end

