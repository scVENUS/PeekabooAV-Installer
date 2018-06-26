#!/usr/bin/env bash

echo "
show tables;
drop table _meta;
drop table analysis_jobs_v3;
drop table sample_info_v3;
drop table analysis_result_v3;
show tables;
" | mysql peekaboo && echo "OK: restart Peekaboo" || echo "ERROR"
