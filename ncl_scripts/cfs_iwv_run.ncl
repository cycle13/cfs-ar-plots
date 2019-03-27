;=================================================================================
; cfs_iwv_run.ncl:
; --------------------------------------------------------------------------------
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncl_scripts/cfs_lib_iwv.ncl"
;=================================================================================

begin
    ;---PARAMETERS
    TEST_FLAG   = True
    IWV_MAG_MIN = 20       ; [kg m^-2 = mm] 
    in_dir      = "/scratch/mmasarik/EXP_JUNE2010/CFS/sandbox/cfsr"
    out_dir     = "/scratch/mmasarik/EXP_JUNE2010/CFS/images"

    ;---RUN CALL
    plotiwv     = cfs_iwv(IWV_MAG_MIN, in_dir, out_dir, TEST_FLAG)
end
