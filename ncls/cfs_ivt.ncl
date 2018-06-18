;=================================================================================
; cfs_ivt.ncl:  Computes and plots vectors of Integrated Vapor Transport (IVT).
; --------------------------------------------------------------------------------
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib.ncl"
;=================================================================================

begin
    ;---PARAMETERS
    TEST    = False
    Psfc    = 100000.0     ; [Pa] 
    Ptop    =  30000.0     ; [Pa]
    indir   = "/scratch/mmasarik/EXP_JUNE2010/CFS/sandbox/cfsr"
    outdir  = indir + "/" + "images/ivt"



    ;---GET VARIABLES
    print("Getting variables: U, V, q...")
    UVQ     = get_ivt_vars(indir)
    PLEV    = UVQ[0]
    U       = UVQ[1]
    V       = UVQ[2]
    q       = UVQ[3]
    delete(UVQ)
    if (TEST) then
	printVarSummary(PLEV)
	printVarSummary(U)
	printVarSummary(V)
	printVarSummary(q)
    end if


    ;---CALC IVT
    print("Calculating IVT...")
    IVT     = calc_ivt(PLEV,U,V,q,Psfc,Ptop)
    ivt_u   = IVT[0]
    ivt_v   = IVT[1] 
    ivt_mag = IVT[2] 
    delete([/ IVT, U, V, q /])
    if (TEST) then
        printVarSummary(ivt_u)
        printVarSummary(ivt_v)
        printVarSummary(ivt_mag)
    end if


    ;---PLOT IVT
    print("Plotting IVT...")
    plotivt = plot_ivt(ivt_u, ivt_v, ivt_mag, outdir)
end

