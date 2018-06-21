;=================================================================================
; cfs_ivt_run.ncl:
; --------------------------------------------------------------------------------
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncls/cfs_lib_ivt.ncl"
;=================================================================================


begin
    ;---PARAMETERS
    TEST_FLAG   = True
    IVT_MAG_MIN =    250       ; [kg m^-1 s^-1] 
    in_dir      = "/scratch/mmasarik/EXP_JUNE2010/CFS/sandbox/cfsr"
    out_dir     = "/scratch/mmasarik/EXP_JUNE2010/CFS/images"

    ;---RUN CALL
    plotivt     = cfs_ivt(IVT_MAG_MIN, in_dir, out_dir, TEST_FLAG)
end

