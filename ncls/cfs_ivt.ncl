;=================================================================================
; cfs_ivt.ncl:  Uses funtions from cfs_lib.ncl to compute/plot IVT.
;=================================================================================
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib.ncl"




begin

;---PARAMETERS
testin  = "/scratch/mmasarik/EXP_JUNE2010/CFS/sandbox/cfsr"
testout = testin + "/" + "images/ivt"
ilevels = (/ 330.0 /)


;---GET VARIABLES
UVT  = cfs_get_ipv_vars(testin)
PLEV = UVT[0]
U    = UVT[1]
V    = UVT[2]
T    = UVT[3]
delete(UVT)
printVarSummary(PLEV)
printVarSummary(U)
printVarSummary(V)
printVarSummary(T)


;---CALC IPV
IPV   = cfs_calc_ipv(PLEV,U,V,T,ilevels)
ilevs = IPV[0]
ipv   = IPV[1]
delete(IPV)
printVarSummary(ilevs)
printVarSummary(ipv)


;---PLOT IPV
plotstub = cfs_plot_ipv(ilevs, ipv, testout)


end

