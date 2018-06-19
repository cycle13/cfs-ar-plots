;=================================================================================
; pv_iso.ncl 
;
; 
; [pv_isobaric_2.ncl - original]
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
;
;=================================================================================

begin
     ;---Parameters
     TEST     = False                       ; test mode
     outtype  = "png"                       ; graphic output type
     ilev     = (/325.0/) ; isentropic levels [K]
     ilevs    = dimsizes(ilev)              ; number of isentropic levels
     gridType = 0                           ; 0: gaussian,  1: reqular (?)
     opt      = 1                           ; 0: pv only,   1: list (pv, s, theta)


     indirbase = "/scratch/mmasarik/EXP_JUNE2010/CFS"
     indir1    = indirbase + "/" + "reanalysis"
     indir2    = indirbase + "/" + "cfsrr_2010-05-16_12__2010-06-07_00" 
     indir3    = indirbase + "/" + "cfsrr_2010-05-21_12__2010-06-07_00"
     indir4    = indirbase + "/" + "cfsrr_2010-05-26_12__2010-06-07_00"
     outdir    = indirbase    + "/" + "images"


     ;---Read in pressure levels from first file
     first_file = systemfunc("ls " + indir1 + "/" + "*.grb2 | head -1")     
     f1         = addfile(first_file, "r")
     LEV        = f1->lv_ISBL0    ; Pa
     printVarSummary(LEV)



     ;************************************************
     ; FILE I/O:  Read in variables from files
     ;************************************************
;----1
     ;---Use systemfunc/ls
     print("Getting file list from directory: " + indir1 + "...")
     all_files1 = systemfunc("ls " + indir1 + "/" + "pgb*.grb2")
     printVarSummary(all_files1)
  
     ;---Open files using addfiles
     print("Adding files: " + all_files1 + "...")
     fall1 = addfiles (all_files1, "r")
     printVarSummary(fall1)

     ;---Read in files using "join" mode
     print("Joining along time dim 1...")
     ListSetType (fall1, "join")
     printVarSummary(fall1)

     ;---Get Variables: U, V, T
     print("Retrieving / joining U1...")
     U1  = fall1[:]->UGRD_P0_L100_GLL0  ; U-component wind, on an isobaric surface [m/s]
     print("Retrieving / joining V1...")
     V1  = fall1[:]->VGRD_P0_L100_GLL0  ; V-component wind, on an isobaric surface [m/s]
     print("Retrieving / joining T1...")
     T1  = fall1[:]->TMP_P0_L100_GLL0   ; Temperature, on an isobaric surface      [K]

     ;---Reverse lat dimension.   orig: 90..-90   |-->   new: -90..90
     print("Reversing lat dimension 1...")
     U1     = U1(:,:,::-1,:)            ; reorder to South -> North
     V1     = V1(:,:,::-1,:)
     T1     = T1(:,:,::-1,:)

;----2
     ;---Use systemfunc/ls
     print("Getting file list from directory: " + indir2 + "...")
     all_files2 = systemfunc("ls " + indir2 + "/" + "pgb*.grb2")
     printVarSummary(all_files2)
  
     ;---Open files using addfiles
     print("Adding files: " + all_files2 + "...")
     fall2 = addfiles (all_files2, "r")
     printVarSummary(fall2)

     ;---Read in files using "join" mode
     print("Joining along time dim 2...")
     ListSetType (fall2, "join")
     printVarSummary(fall2)

     ;---Get Variables: U, V, T
     print("Retrieving / joining U2...")
     U2  = fall2[:]->UGRD_P0_L100_GLL0  ; U-component wind, on an isobaric surface [m/s]
     print("Retrieving / joining V2...")
     V2  = fall2[:]->VGRD_P0_L100_GLL0  ; V-component wind, on an isobaric surface [m/s]
     print("Retrieving / joining T2...")
     T2  = fall2[:]->TMP_P0_L100_GLL0   ; Temperature, on an isobaric surface      [K]

     ;---Reverse lat dimension.   orig: 90..-90   |-->   new: -90..90
     print("Reversing lat dimension 2...")
     U2     = U2(:,:,::-1,:)            ; reorder to South -> North
     V2     = V2(:,:,::-1,:)
     T2     = T2(:,:,::-1,:)

;----3
     ;---Use systemfunc/ls
     print("Getting file list from directory: " + indir3 + "...")
     all_files3 = systemfunc("ls " + indir3 + "/" + "pgb*.grb2")
     printVarSummary(all_files3)
  
     ;---Open files using addfiles
     print("Adding files: " + all_files3 + "...")
     fall3 = addfiles (all_files3, "r")
     printVarSummary(fall3)

     ;---Read in files using "join" mode
     print("Joining along time dim 3...")
     ListSetType (fall3, "join")
     printVarSummary(fall3)

     ;---Get Variables: U, V, T
     print("Retrieving / joining U3...")
     U3  = fall3[:]->UGRD_P0_L100_GLL0  ; U-component wind, on an isobaric surface [m/s]
     print("Retrieving / joining V3...")
     V3  = fall3[:]->VGRD_P0_L100_GLL0  ; V-component wind, on an isobaric surface [m/s]
     print("Retrieving / joining T3...")
     T3  = fall3[:]->TMP_P0_L100_GLL0   ; Temperature, on an isobaric surface      [K]

     ;---Reverse lat dimension.   orig: 90..-90   |-->   new: -90..90
     print("Reversing lat dimension 3...")
     U3     = U3(:,:,::-1,:)            ; reorder to South -> North
     V3     = V3(:,:,::-1,:)
     T3     = T3(:,:,::-1,:)

;----4
     ;---Use systemfunc/ls
     print("Getting file list from directory: " + indir4 + "...")
     all_files4 = systemfunc("ls " + indir4 + "/" + "pgb*.grb2")
     printVarSummary(all_files4)
  
     ;---Open files using addfiles
     print("Adding files: " + all_files4 + "...")
     fall4 = addfiles (all_files4, "r")
     printVarSummary(fall4)

     ;---Read in files using "join" mode
     print("Joining along time dim 4...")
     ListSetType (fall4, "join")
     printVarSummary(fall4)

     ;---Get Variables: U, V, T
     print("Retrieving / joining U4...")
     U4  = fall4[:]->UGRD_P0_L100_GLL0  ; U-component wind, on an isobaric surface [m/s]
     print("Retrieving / joining V4...")
     V4  = fall4[:]->VGRD_P0_L100_GLL0  ; V-component wind, on an isobaric surface [m/s]
     print("Retrieving / joining T4...")
     T4  = fall4[:]->TMP_P0_L100_GLL0   ; Temperature, on an isobaric surface      [K]

     ;---Reverse lat dimension.   orig: 90..-90   |-->   new: -90..90
     print("Reversing lat dimension 4...")
     U4     = U4(:,:,::-1,:)            ; reorder to South -> North
     V4     = V4(:,:,::-1,:)
     T4     = T4(:,:,::-1,:)







     ;************************************************
     ; CALC:  Isobaric Potential Vorticity (p) 
     ;************************************************
;---1
     ;---Calcualate PV on isobaric surfaces     
     print("Calculating PV on isobaric surfaces...")
     PV1    = pot_vort_isobaric(LEV, U1, V1, T1, T1&lat_0, gridType, opt)
     pv1    = PV1[0]          ; extract PV (pv)
     s1     = PV1[1]          ; extract static stability (s)
     theta1 = PV1[2]          ; extract potential temperature (theta)

     ;---Display summary + min/max values
     printVarSummary(PV1)
     printVarSummary(pv1)
     printMinMax(pv1,0)
     printVarSummary(s1)
     printMinMax(s1,0)
     printVarSummary(theta1)
     printMinMax(theta1,0)

     ;---Convert pv to PVU's:  1 PVU == 10^-6 m^2 s^-1 K kg^-1
     pv1 = pv1 * 10^6
     pv1@units = "PVU [10^-6 m^2 s^-1 K kg^-1]"
     printVarSummary(pv1)
     printMinMax(pv1,0)

;---2
     ;---Calcualate PV on isobaric surfaces     
     print("Calculating PV on isobaric surfaces...")
     PV2    = pot_vort_isobaric(LEV, U2, V2, T2, T2&lat_0, gridType, opt)
     pv2    = PV2[0]          ; extract PV (pv)
     s2     = PV2[1]          ; extract static stability (s)
     theta2 = PV2[2]          ; extract potential temperature (theta)

     ;---Display summary + min/max values
     printVarSummary(PV2)
     printVarSummary(pv2)
     printMinMax(pv2,0)
     printVarSummary(s2)
     printMinMax(s2,0)
     printVarSummary(theta2)
     printMinMax(theta2,0)

     ;---Convert pv to PVU's:  1 PVU == 10^-6 m^2 s^-1 K kg^-1
     pv2 = pv2 * 10^6
     pv2@units = "PVU [10^-6 m^2 s^-1 K kg^-1]"
     printVarSummary(pv2)
     printMinMax(pv2,0)

;---3
     ;---Calcualate PV on isobaric surfaces     
     print("Calculating PV on isobaric surfaces...")
     PV3    = pot_vort_isobaric(LEV, U3, V3, T3, T3&lat_0, gridType, opt)
     pv3    = PV3[0]          ; extract PV (pv)
     s3     = PV3[1]          ; extract static stability (s)
     theta3 = PV3[2]          ; extract potential temperature (theta)

     ;---Display summary + min/max values
     printVarSummary(PV3)
     printVarSummary(pv3)
     printMinMax(pv3,0)
     printVarSummary(s3)
     printMinMax(s3,0)
     printVarSummary(theta3)
     printMinMax(theta3,0)

     ;---Convert pv to PVU's:  1 PVU == 10^-6 m^2 s^-1 K kg^-1
     pv3 = pv3 * 10^6
     pv3@units = "PVU [10^-6 m^2 s^-1 K kg^-1]"
     printVarSummary(pv3)
     printMinMax(pv3,0)

;---4
     ;---Calcualate PV on isobaric surfaces     
     print("Calculating PV on isobaric surfaces...")
     PV4    = pot_vort_isobaric(LEV, U4, V4, T4, T4&lat_0, gridType, opt)
     pv4    = PV4[0]          ; extract PV (pv)
     s4     = PV4[1]          ; extract static stability (s)
     theta4 = PV4[2]          ; extract potential temperature (theta)

     ;---Display summary + min/max values
     printVarSummary(PV4)
     printVarSummary(pv4)
     printMinMax(pv4,0)
     printVarSummary(s4)
     printMinMax(s4,0)
     printVarSummary(theta4)
     printMinMax(theta4,0)

     ;---Convert pv to PVU's:  1 PVU == 10^-6 m^2 s^-1 K kg^-1
     pv4 = pv4 * 10^6
     pv4@units = "PVU [10^-6 m^2 s^-1 K kg^-1]"
     printVarSummary(pv4)
     printMinMax(pv4,0)




     ;************************************************
     ; INTERP:  isobars(p)  -->  isentropes(theta)
     ;************************************************
;---1
     ;---Interpolate pv from isobaric (P) levels to isentropic (theta) levels
     print("Interpolating pv from isobars to isentropes...")
     ipv1 = int2p_n_Wrap (theta1, pv1, ilev, 0, 1)

;---2
     ;---Interpolate pv from isobaric (P) levels to isentropic (theta) levels
     print("Interpolating pv from isobars to isentropes...")
     ipv2 = int2p_n_Wrap (theta2, pv2, ilev, 0, 1)

;---3
     ;---Interpolate pv from isobaric (P) levels to isentropic (theta) levels
     print("Interpolating pv from isobars to isentropes...")
     ipv3 = int2p_n_Wrap (theta3, pv3, ilev, 0, 1)

;---4
     ;---Interpolate pv from isobaric (P) levels to isentropic (theta) levels
     print("Interpolating pv from isobars to isentropes...")
     ipv4 = int2p_n_Wrap (theta4, pv4, ilev, 0, 1)






     ;************************************************
     ; create plots
     ;************************************************
     print("Create plots...")
     print(" ")
     ret = systemfunc("test -d " + outdir + "; echo $?")
     if (0 .ne. ret) then
         junk = systemfunc("mkdir -pv " + outdir)
     else
         junk = systemfunc("rm    -rf " + outdir)
         junk = systemfunc("mkdir -pv " + outdir)
     end if

  
     ;---Get ipv dims
     dims = dimsizes(ipv1)
     ntim = dims(0)
     klev = dims(1)
     nlat = dims(2)
     mlon = dims(3)

     ;---Time period parameters
     if (TEST) then
         ntStrt = 0
         ntLast = 0
     else
         ntStrt = 0
         ntLast = ntim-1
     end if

     cnLevs = (/ 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0 /)
     ;---General plot resources (res)
     res                      = True
     res@gsnDraw              = False
     res@gsnFrame             = False
     res@cnFillOn             = True                 ; turn on color fill
     res@cnLinesOn            = True
     res@cnLineLabelsOn       = False
     res@cnLevelSelectionMode = "ExplicitLevels"       ; manually set contour levels
     res@cnLevels             = cnLevs
     ; res@cnLevelSelectionMode = "ManualLevels"       ; manually set contour levels
     ; res@cnMinLevelValF       = 0.25                  ; minimum contour level
     ; res@cnMaxLevelValF       = 5.0                  ; maximum contour level
     ; res@cnLevelSpacingF      = 0.25                 ; interval between contours
     res@lbOrientation        = "Vertical"   
     res@gsnCenterString = ilev(0)+"K"

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
        plot                  = new(4,graphic)  ; graphic: number of panels
        wks                   = gsn_open_wks("png",outfile)



        ;---1:  CFSRR 2010-05-16
        res@gsnLeftString     = "IPV: CFSRR 2010-05-16 - time=" + nt_padded        
        plot(0) = gsn_csm_contour_map(wks,ipv2(nt,{ilev(0)},:,:),res)   

        ;---2:  CFSRR: 2010-05-21
        res@gsnLeftString     = "IPV: CFSRR 2010-05-21  - time=" + nt_padded        
        plot(1) = gsn_csm_contour_map(wks,ipv3(nt,{ilev(0)},:,:),res)   

        ;---3:  CFSRR: 2010-05-26
        res@gsnLeftString     = "IPV: CFSRR 2010-05-26 - time=" + nt_padded        
        plot(2) = gsn_csm_contour_map(wks,ipv4(nt,{ilev(0)},:,:),res)           

        ;---0:  CFSR
        res@gsnLeftString     = "IPV: CFSR - time=" + nt_padded
        plot(3) = gsn_csm_contour_map(wks,ipv1(nt,{ilev(0)},:,:),res)   



        
        ;---Plot panels as one plot
        print(" ")
        print("PLOT PANELS, time="+nt_padded+" of "+ ntim +"...")
        gsn_panel(wks,plot,  (/4, 1/),  resP)
        print("OUTPUT FILE: "+outfile+"."+outtype)
     end do
end
