;===================================================================================
; cfs_ipv_run.ncl:
; ----------------------------------------------------------------------------------
load "/scratch/mmasarik/EXP_JUNE2010/CFS/cfs_tools/ncl_scripts/cfs_lib_ipv.ncl"
;===================================================================================


begin
    ;---PARAMETERS
    TEST_FLAG   = True
    i_level     = 325.0     ; [K]
    in_dir      = "/scratch/mmasarik/EXP_JUNE2010/CFS/sandbox/cfsr"
    out_dir     = "/scratch/mmasarik/EXP_JUNE2010/CFS/images"

    ;---RUN CALL
    plotipv     = cfs_ipv(i_level, in_dir, out_dir, TEST_FLAG)
end
