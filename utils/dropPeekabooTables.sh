#!/usr/bin/env bash

echo "
show tables;
drop table _meta;
drop table analysis_jobs_v2;
drop table sample_info_v2;
drop table analysis_result_v2;
show tables;
" | mysql peekaboo && echo "OK: restart Peekaboo" || echo "ERROR"
