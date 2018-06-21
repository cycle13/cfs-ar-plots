;=================================================================================
; cfs_ivt.ncl:  Computes and plots vectors of Integrated Vapor Transport (IVT).
; --------------------------------------------------------------------------------
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib_gen.ncl"
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib_ivt.ncl"
;=================================================================================

begin
    ;---PARAMETERS
    dirtag  = "test"
    TEST    = True
    IVT_MAG_MIN = 250          ; [kg m^-1 s^-1] 
    Psfc    = 100001.0     ; [Pa] 
    Ptop    =  30000.0     ; [Pa]
    indir   = "/scratch/mmasarik/EXP_JUNE2010/CFS/sandbox/cfsr"
    outimg  = "/scratch/mmasarik/EXP_JUNE2010/CFS/images"
    outdir  = outimg + "/" + "ivt" + "/" + dirtag




    ;---GET VARIABLES
    print("Getting variables: U, V, q...")
    UVQ     = get_ivt_vars(indir, TEST)
    Times   = UVQ[0]
    PLEV    = UVQ[1]
    U       = UVQ[2]
    V       = UVQ[3]
    q       = UVQ[4]
    delete(UVQ)
    if (TEST) then
    	printVarSummary(Times)
	printVarSummary(PLEV)
	printVarSummary(U)
	printVarSummary(V)
	printVarSummary(q)
    end if


    ;---CALC IVT
    print("Calculating IVT...")
    IVT     = calc_ivt(PLEV, U, V, q, Psfc, Ptop)
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
    plotivt = plot_ivt(Times, Psfc, Ptop, ivt_u, ivt_v, ivt_mag, IVT_MAG_MIN, outdir)
end

