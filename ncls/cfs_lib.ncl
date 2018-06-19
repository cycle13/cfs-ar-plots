;=================================================================================
; cfs_lib.ncl:  Library of function related CFS (Climate Forecast System) data
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
;=================================================================================
;
; x   0) vert_p_intgrl()
; I. IPV
; x   1) get_ipv_vars()
; x   2) calc_ipv()
; x   3) plot_ipv()
; II. IVT
; x   4) get_ivt_vars()
;    5) calc_ivt()
;    6) plot_ivt()
; III. IWV
; x   7) get_iwv_vars()
; x   8) calc_iwv()
; x   9) plot_iwv()
; IV. Misc.
;    10)
;
; NOTES:
; * PLEV
;     Psfc = 100000.0 Pa   -- plevel index = (36)
;     Ptop =  30000.0 Pa   -- plevel index = (17), or
;     Ptop =  10000.p Pa   -- plevel index = (10)
;
;
; ---------------------------------------------------------------------------------


; 0) --- vert_p_intgrl()
; ======================
undef("vert_p_intgrl")
function vert_p_intgrl(Plevels,Psfc,Ptop,X)
local P0, P100, dims, ntim, klev, ylat, xlon, dp, X_vert
begin
    ;---DATA DICTIONARY----------------------------------------------
    ;        FAILED ATTEMPTS...?
    ; * Integrate over vertical column
    ;     vopt      = 1  ; vert opt:  1 = weighted sum for all non-missing vals
    ;     plev_dim  = 1  ; q(time,plev,lat,lon) --> plev dim = 1
    ;                          0 ,  1 , 2 , 3
    ;
    ; iwv  = (1/g) * wgt_vertical_n(q, dp, vopt=1, plev_dim=1)    
    ; iwv  = (1/g) * dim_sum_wgt_n_Wrap(q_reorder, dp, sopt=1, 1)
    ;
    ;----------------------------------------------------------------

    ;---PARAMETERS
    g     =      9.81  ; [m s^-2],  gravity acc.
    P0    = 100000.0   ; [Pa],      reference pressure of surface
    P100  =  10000.0   ; [Pa],      100 hPa

    ;---Meta data for X
    X!0  = "time"
    X!1  = "lev"
    X!2  = "lat"
    X!3  = "lon"
    dims = dimsizes(X)
    ntim = dims(0)
    klev = dims(1)
    ylat = dims(2)
    xlon = dims(3)

    ;---Create new:  X_vert
    X_vert = new((/ntim,ylat,xlon/),float,0.0)  ; assign zero to start, for summing

    ;---Calculate dp
    dp = dpres_plevel_Wrap(Plevels, Psfc, Ptop, 0)  ; func(): requires Psfc > P0


    ;   ---   VERTICAL INTEGRATION     ---     ;
    ; =========================================;

    ;---Select pressure level index range
    if (Ptop .eq. P100) then
      lvStart = 10            ; (10): 10000.0 [Pa]       
    else
      lvStart = 17            ; (17): 30000.0 [Pa]
    end if
    lvStop  = 36              ; (36):  100000.0 [Pa]
    do tt=0,ntim-1            ;---LOOP: time
      X_vert(tt,:,:)    =  (1/g) * X(tt,lvStart,:,:) * dp(lvStart)
      do ll=lvStart+1,lvStop  ;---LOOP: lev 
        X_vert(tt,:,:)  = X_vert(tt,:,:)  +  (1/g) * X(tt,ll,:,:) * dp(ll)
      end do
    end do

    ;---Meta data for X_vert
    copy_VarCoords_1(X(time|:, lat|:, lon|:, lev|:), X_vert)
    X_vert!0           = "time"
    X_vert!1           = "lat"    
    X_vert!2           = "lon"
    X_vert&lat         = X&lat
    X_vert&lon         = X&lon
    X_vert&lat@units   = "degrees_north"    
    X_vert&lon@units   = "degrees_east"
    X_vert@_FillValue  = X@_FillValue

  return X_vert
end



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
    q_u               = q * u
    ivt_u             = vert_p_intgrl(PLEV, Psfc, Ptop, q_u)
    ivt_u@long_name   = "Integrated Vapor Transport - U-component"
    ivt@units         = "kg m^-1 s^-1"



    ;---IVT_v, v-component
    q_v               = q * v
    ivt_v             = vert_p_intgrl(PLEV, Psfc, Ptop, q_v)
    ivt_v@long_name   = "Integrated Vapor Transport - V-component"
    ivt@units         = "kg m^-1 s^-1"



    ;---IVT_mag, magnitude (total vector)
    QV_mag            = sqrt( (q_u * q_u) + (q_v * q_v) )
    ivt_mag@long_name = "Integrated Vapor Transport - magnitude"
    ivt_mag@units     = "kg m^-1 s^-1"

  return [/ivt_u, ivt_v, ivt_mag/]
end





; 6) --- plot_ivt()
; =================
; undef("plot_ivt")
; function plot_ivt()
; local 
; begin
;     ;---DATA DICTIONARY----------------------------------------------
;     ;
;     ;----------------------------------------------------------------

;     ;---PARAMETERS
;     tmpvar = "IMPLEMENT: plot_ivt()"
;     print(tmpvar)

;   return tmpvar
; end






; 7) --- get_iwv_vars()
; =====================
undef("get_iwv_vars")
function get_iwv_vars(indir)
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
function plot_iwv(iwv, Psfc, Ptop, outdir)
local TEST, ret, junk, dims, ntim, nlat, mlon, ntStrt, ntLast,
      outfile, res, resP, nt, nt_padded, wks, plot, outtype, outbase
begin
     ;---PARAMETERS
     TEST     = False
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
     res@gsnDraw              = True
     res@gsnFrame             = True
     res@cnFillOn             = True                 ; turn on color fill
     res@cnLinesOn            = True
     res@cnLineLabelsOn       = False
     res@cnLevelSelectionMode = "ManualLevels"       ; manually set contour levels
     res@cnMinLevelValF       = 20.0                 ; minimum contour level
     res@cnMaxLevelValF       = 70.0                 ; maximum contour level
     res@cnLevelSpacingF      =  5.0                 ; interval between contours
     res@lbOrientation        = "Vertical"   
     res@gsnCenterString      = "Psfc: " + Psfc + "Pa, Ptop: " + Ptop + "Pa"

     ;---Location  (currently, centered over Pacific basin)
     res@mpCenterLonF         = 177.5
     res@mpMaxLatF            =  55           ; choose subregion           
     res@mpMinLatF            =   0
     res@mpMaxLonF            = 260
     res@mpMinLonF            =  95

     ;---Panel plot resources (resP)
;     resP                     = True
;     resP@gsnMaximize         = True  



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
        res@gsnLeftString     = "IWV:  " + iwv@initial_time + " UTC"
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


; Dimensions and sizes:[lv_ISBL0 | 37]
; Coordinates: 
;             lv_ISBL0: [100..100000]
; Number Of Attributes: 2
; units :Pa
; long_name :Isobaric surface
; (0)100
; (1)200
; (2)300
; (3)500
; (4)700
; (5)1000
; (6)2000
; (7)3000
; (8)5000
; (9)7000
; (10)10000
; (11)12500
; (12)15000
; (13)17500
; (14)20000
; (15)22500
; (16)25000
; (17)30000
; (18)35000
; (19)40000
; (20)45000
; (21)50000
; (22)55000
; (23)60000
; (24)65000
; (25)70000
; (26)75000
; (27)77500
; (28)80000
; (29)82500
; (30)85000
; (31)87500
; (32)90000
; (33)92500
; (34)95000
; (35)97500
; (36)100000


;     ;---Calculate dp
;     dp = dpres_plevel_Wrap(Plevels, Psfc, Ptop, 0)  ; func(): requires Psfc > P0

;     ;---Select pressure level index range
;     if (Ptop .eq. P100) then
;       lvStart = 10   ; (10): 10000.0 [Pa]       
;     else
;       lvStart = 17   ; (17): 30000.0 [Pa]
;     end if
;     lvStop  = 36          ; (36):  100000.0 [Pa]
; ;    Psfc    = P0          ; After dpres_plevel_Wrap(), set Psfc = P0
;     do tt=0,ntim-1
;       iwv(tt,:,:) =  (1/g) * q(tt,lvStart,:,:) * dp(lvStart)

;       do ll=lvStart+1,lvStop
;         iwv(tt,:,:)   = iwv(tt,:,:)  +  (1/g) * q(tt,ll,:,:) * dp(ll)

;       end do
;     end do

