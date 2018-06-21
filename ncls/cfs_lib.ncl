;=================================================================================
; cfs_lib.ncl:  Library of function related CFS (Climate Forecast System) data
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
;=================================================================================
;
; NOTES:
; * PLEV
;     Psfc = 100000.0 Pa   -- plevel index = (36)
;     Ptop =  30000.0 Pa   -- plevel index = (17), or
;     Ptop =  10000.p Pa   -- plevel index = (10)
; ---------------------------------------------------------------------------------


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

