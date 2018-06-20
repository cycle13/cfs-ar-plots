;=================================================================================
; cfs_lib_gen.ncl:  Calculates and plots contours of Integrated Water Vapor (IWV).
; --------------------------------------------------------------------------------
;=================================================================================


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
    X_vert&lat@units   = "degrees_north"    
    X_vert&lon@units   = "degrees_east"
    X_vert@_FillValue  = X@_FillValue

  return X_vert
end

