;=================================================================================
; cfs_lib.ncl:  Library of function related CFS (Climate Forecast System) data
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
;=================================================================================
;
; I. IPV
; x   1) get_ipv_vars()
; x   2) calc_ipv()
; x   3) plot_ipv()
; II. IVT
; x   4) get_ivt_vars()
; x   5) calc_ivt()
;    6) plot_ivt()
; III. IWV
; x   7) get_iwv_vars()
; x   8) calc_iwv()
; x   9) plot_iwv()
;
; ---------------------------------------------------------------------------------


; 1) --- get_ipv_vars()
; =====================
undef("get_ipv_vars")
function get_ipv_vars(indir)
local first_file, f1, LEV, all_files, fall
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

    ;---Reverse lat dimension.   orig: 90..-90   |-->   new: -90..90
    print("Reversing lat dimension...")
    U     = U(:,:,::-1,:)             ; reorder to South -> North
    V     = V(:,:,::-1,:)
    T     = T(:,:,::-1,:)

  return [/LEV, U, V, T/]
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
     printVarSummary(pv)
     printMinMax(pv,0)

     ;---Interpolate pv from isobaric (P) levels to isentropic (theta) levels
     print("Interpolating pv from isobars to isentropes...")
     ipv = int2p_n_Wrap (theta, pv, ilev, 0, 1)

  return [/ilev, ipv/]
end



; 3) --- plot_ipv()
; =================
undef("plot_ipv")
function plot_ipv(ilev, ipv, outdir)
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
     ntim = dims(0)
     klev = dims(1)
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
     res@gsnDraw              = False
     res@gsnFrame             = False
     res@cnFillOn             = True                 ; turn on color fill
     res@cnLinesOn            = True
     res@cnLineLabelsOn       = False
     res@cnLevelSelectionMode = "ManualLevels"       ; manually set contour levels
     res@cnMinLevelValF       = 0.25                 ; minimum contour level
     res@cnMaxLevelValF       = 5.0                  ; maximum contour level
     res@cnLevelSpacingF      = 0.25                 ; interval between contours
     res@lbOrientation        = "Vertical"   
     res@gsnCenterString      = ilev(0)+"K"

     ;---Location  (currently, centered over Pacific basin)
     res@mpCenterLonF         = 177.5
     res@mpMaxLatF            =  55           ; choose subregion           
     res@mpMinLatF            =   0
     res@mpMaxLonF            = 260
     res@mpMinLonF            =  95

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
        outfile               = outdir + "/" + "pv_isentropic_t" + nt_padded
        wks                   = gsn_open_wks(outtype,outfile)

        ;---Call plot routine
        res@gsnLeftString     = "IPV: CFSR - time=" + nt_padded
        plot = gsn_csm_contour_map(wks,ipv(nt,{ilev(0)},:,:),res)   

        print("OUTPUT FILE: "+outfile+"."+outtype)
     end do
  return plot
end



; 4) --- get_ivt_vars()
; =====================
undef("get_ivt_vars")
function get_ivt_vars(indir)
local first_file, f1, LEV, all_files, fall, U, V, q
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

    ;---Reverse lat dimension.   orig: 90..-90   |-->   new: -90..90
    print("Reversing lat dimension...")
    U     = U(:,:,::-1,:)             ; reorder to South -> North
    V     = V(:,:,::-1,:)
    q     = q(:,:,::-1,:)

  return [/LEV, U, V, q/]
end




; 5) --- calc_ivt()
; =================
undef("calc_ivt")
function calc_ivt(PLEV, u, v, q, Psfc, Ptop)
local g, ivt_u, ivt_v, ivt_mag, dp, plev_dim
begin
    ;---DATA DICTIONARY----------------------------------------------
    ;  IVT = 1/g S_p V*q*dp [kg/ms]
    ;----------------------------------------------------------------

    ;---PARAMETERS
    g                 = 9.81   ; gravitational acc. [m s^-2]
    vopt              = 1      ; vertical opt:  1 = weighted sum (integral)
    
    ;---Calculate dp
    dp = dpres_plevel(PLEV, Psfc, Ptop, 0)

    ;---Integrate V*q (velocity, specific humidity) over vertical column
    plev_dim          = 1        ; q(time,plev,lat,lon) --> plev dim = 1

    ;---IVT_u, u-component
    q_u               = q * u
    ivt_u             = (1/g) * wgt_vertical_n(q_u, dp, vopt, plev_dim)
    ivt_u@long_name   = "Integrated Vapor Transport - U-component"
    ivt@units         = "kg m^-1 s^-1"

    ;---IVT_v, v-component
    q_v               = q * v
    ivt_v             = (1/g) * wgt_vertical_n(q_v, dp, vopt, plev_dim)
    ivt_v@long_name   = "Integrated Vapor Transport - V-component"
    ivt@units         = "kg m^-1 s^-1"


    ;---IVT_mag, magnitude (total vector)
    QV_mag            = sqrt( (q_u * q_u) + (q_v * q_v) )
    ivt_mag           = (1/g) * wgt_vertical_n(QV_mag, dp, vopt, plev_dim)
    ivt_mag@long_name = "Integrated Vapor Transport - magnitude"
    ivt_mag@units     = "kg m^-1 s^-1"

  return [/ivt_u, ivt_v, ivt_mag/]
end





; 6) --- plot_ivt()
; =================
undef("plot_ivt")
function plot_ivt()
local 
begin
    ;---DATA DICTIONARY----------------------------------------------
    ;
    ;----------------------------------------------------------------

    ;---PARAMETERS
    tmpvar = "IMPLEMENT: plot_ivt()"
    print(tmpvar)

  return tmpvar
end





; 7) --- get_iwv_vars()
; =====================
undef("get_iwv_vars")
function get_iwv_vars(indir)
local first_file, f1, LEV, all_files, fall, q
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

    ;---Get Variable: q
    print("Retrieving / joining q...")
    q     = fall[:]->SPFH_P0_L100_GLL0     ; q specific humidity, on an isobaric surface [kg/kg]

    ;---Reverse lat dimension.   orig: 90..-90   |-->   new: -90..90
    print("Reversing lat dimension...")
    q     = q(:,:,::-1,:)

  return [/LEV, q/]
end



; 8) --- calc_iwv()
; =================
undef("calc_iwv")
function calc_iwv(PLEV, q, Psfc, Ptop)
local g, iwv, dp, plev_dim
begin
    ;---DATA DICTIONARY----------------------------------------------
    ;  IWV = 1/g S_p q*dp [kg m^-2 == mm]
    ;----------------------------------------------------------------

    ;---PARAMETERS
    g     = 9.81   ; gravitational acc. [m s^-2]
    vopt  = 1      ; vertical opt:  1 = weighted sum (integral)
    
    ;---Calculate dp
    dp = dpres_plevel(PLEV, Psfc, Ptop, 0)

    ;---Integrate q (specific humidity) over vertical column
    plev_dim = 1        ; q(time,plev,lat,lon) --> plev dim = 1
    iwv      = (1/g) * wgt_vertical_n(q, dp, vopt, plev_dim)

    iwv@long_name = "Integrated Water Vapor"
    iwv@units     = "mm"

  return iwv
end



; 9) --- plot_iwv()
; =================
undef("plot_iwv")
function plot_iwv(iwv, Psfc, Ptop, outdir)
local TEST, ret, junk, dims, ntim, nlat, mlon, ntStrt, ntLast,
      outfile, res, resP, nt, nt_padded, wks, plot, outtype, outbase
begin
     ;---PARAMETERS
     TEST     = True
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
     if (TEST) then
         ntStrt = 0
         ntLast = 0
     else
         ntStrt = 0
         ntLast = ntim-1
     end if

     ;---General plot resources (res)
     res                      = True
     res@gsnDraw              = False
     res@gsnFrame             = False
     res@cnFillOn             = True                 ; turn on color fill
     res@cnLinesOn            = True
     res@cnLineLabelsOn       = False
     res@cnLevelSelectionMode = "ManualLevels"       ; manually set contour levels
     res@cnMinLevelValF       = 10.0                 ; minimum contour level
     res@cnMaxLevelValF       = 40.0                 ; maximum contour level
     res@cnLevelSpacingF      =  2.0                 ; interval between contours
     res@lbOrientation        = "Vertical"   
     res@gsnCenterString      = "Psfc: " + Psfc + "Pa, Ptop: " + Ptop + "Pa"

     ;---Location  (currently, centered over Pacific basin)
     res@mpCenterLonF         = 177.5
     res@mpMaxLatF            =  55           ; choose subregion           
     res@mpMinLatF            =   0
     res@mpMaxLonF            = 260
     res@mpMinLonF            =  95

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
        outfile               = outdir + "/" + "iwv_t" + nt_padded
        wks                   = gsn_open_wks(outtype,outfile)
        gsn_define_colormap(wks,"MPL_Paired")

        ;---Call plot routine
        res@gsnLeftString     = "IWV: time=" + nt_padded
        plot = gsn_csm_contour_map(wks,iwv(nt,:,:),res)   

        print("OUTPUT FILE: "+outfile+"."+outtype)
     end do
  return plot
end





;;; RESOURCES

; ; ) --- ...()
; ; =================
; undef("...")
; function ...()
; local ...
; begin
;     ;---DATA DICTIONARY----------------------------------------------
;     ;
;     ;----------------------------------------------------------------

;     ;---PARAMETERS

;   return ...
; end

