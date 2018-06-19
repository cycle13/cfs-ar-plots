;===================================================================================
; cfs_ipv.ncl:  Computes and plots contours of Isentropic Potential Vorticity (IPV).
; ----------------------------------------------------------------------------------
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib.ncl"
;===================================================================================

begin
    ;---PARAMETERS
    TEST    = False
    ilevel  = 325.0     ; [K]
    indir   = "/scratch/mmasarik/EXP_JUNE2010/CFS/sandbox/cfsr"
    outdir  = indir + "/" + "images/ipv"



    ;---GET VARIABLES
    print("Getting variables: U, V, T...")
    UVT  = get_ipv_vars(indir)
    PLEV = UVT[0]
    U    = UVT[1]
    V    = UVT[2]
    T    = UVT[3]
    delete(UVT)
    if (TEST) then
	printVarSummary(PLEV)
	printVarSummary(U)
	printVarSummary(V)
	printVarSummary(T)
    end if


    ;---CALC IPV
    print("Calculating IPV...")
    ipv   = calc_ipv(PLEV,U,V,T,ilevel)
    delete([/ U, V, T /])
    if (TEST) then
      printVarSummary(ipv)
    end if


    ;---PLOT IPV
    print("Plotting IPV...")
    plotipv = plot_ipv(ilevel, ipv, outdir)
end

