;===================================================================================
; cfs_ipv.ncl:  Computes and plots contours of Isentropic Potential Vorticity (IPV).
; ----------------------------------------------------------------------------------
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib_gen.ncl"
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib_ipv.ncl"
;===================================================================================

begin
    ;---PARAMETERS
    dirtag  = "test"
    TEST    = False
    ilevel  = 325.0     ; [K]
    indir   = "/scratch/mmasarik/EXP_JUNE2010/CFS/sandbox/cfsr"
    outimg  = "/scratch/mmasarik/EXP_JUNE2010/CFS/images"
    outdir  = outimg + "/" + "ipv" + "/" + dirtag




    ;---GET VARIABLES
    print("Getting variables: U, V, T...")
    UVT     = get_ipv_vars(indir)
    Times   = UVT[0]
    PLEV    = UVT[1]
    U       = UVT[2]
    V       = UVT[3]
    T       = UVT[4]
    delete(UVT)
    if (TEST) then
	printVarSummary(Times)
	printVarSummary(PLEV)
	printVarSummary(U)
	printVarSummary(V)
	printVarSummary(T)
    end if


    ;---CALC IPV
    print("Calculating IPV...")
    IPV   = calc_ipv(PLEV,U,V,T,ilevel)
    ilev  = IPV[0]
    ipv   = IPV[1]
    delete([/ U, V, T, IPV /])
    if (TEST) then
      printVarSummary(ipv)
    end if


    ;---PLOT IPV
    print("Plotting IPV...")
    plotipv = plot_ipv(Times, ilev, ipv, outdir)
end

