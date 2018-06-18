;=================================================================================
; cfs_iwv.ncl:  Calculates and plots contours of Integrated Water Vapor (IWV).
; --------------------------------------------------------------------------------
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib.ncl"
;=================================================================================

begin
    ;---PARAMETERS
    TEST    = False
    Psfc    = 100000.0     ; [Pa] 
    Ptop    =  30000.0     ; [Pa]
    indir   = "/scratch/mmasarik/EXP_JUNE2010/CFS/sandbox/cfsr"
    outdir  = indir + "/" + "images/iwv"



    ;---GET VARIABLES
    print("Getting variable: q...")
    Q       = get_iwv_vars(indir)
    PLEV    = Q[0]
    q       = Q[1]
    delete(Q)
    if (TEST) then
        printVarSummary(PLEV)
        printVarSummary(q)
    end if

    ;---CALC IWV
    print("Calculating IVT...")
    iwv     = calc_iwv(PLEV, q, Psfc, Ptop)
    if (TEST) then
        printVarSummary(iwv)
    end if

    ;---PLOT IWV
    print("Plotting IVT...")
    plotiwv = plot_iwv(iwv, Psfc, Ptop, outdir)

end

