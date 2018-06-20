;=================================================================================
; cfs_iwv.ncl:  Calculates and plots contours of Integrated Water Vapor (IWV).
; --------------------------------------------------------------------------------
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib_gen.ncl"
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib_iwv.ncl"
;=================================================================================

begin
    ;---PARAMETERS
    dirtag  = "test3"
    TEST    = False
    Psfc    = 100001.0     ; [Pa]   Must be > 100000.0
    Ptop    =  30000.0     ; [Pa]
    indir   = "/scratch/mmasarik/EXP_JUNE2010/CFS/sandbox/cfsr"
    outimg  = "/scratch/mmasarik/EXP_JUNE2010/CFS/images"
    outdir  = outimg + "/" + "iwv" + "/" + dirtag



    ;---GET VARIABLES
    print("Getting variable: q...")
    Q       = get_iwv_vars(indir)
    Times   = Q[0]
    PLEV    = Q[1]
    q       = Q[2]
    delete(Q)
    if (TEST) then
        printVarSummary(PLEV)
        printVarSummary(q)
    end if

    ;---CALC IWV
    print("Calculating IWV...")
    iwv     = calc_iwv(PLEV, Psfc, Ptop, q)
    if (TEST) then
        printVarSummary(iwv)
    end if


    ;---PLOT IWV
    print("Plotting IWV...")
    plotiwv = plot_iwv(Times, Psfc, Ptop, iwv, outdir)

end

