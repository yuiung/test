@echo off
setlocal enabledelayedexpansion

set APP_NAME=%~1
set PGSHELL_CONFDIR=%~2
set HOST_NAME="%~3"
set ZABBIX_AGENTD_CONF=%~4
set DBNAME=%~5
set SCHEMANAME=%~6
set TABLENAME=%~7

set TIMESTAMP_QUERY=extract(epoch from now())::int

set sql_stat_table=select '"%HOST_NAME%"', 'psql.table_analyze_count[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select analyze_count from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_autoanalyze_count[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select autoanalyze_count from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_autovacuum_count[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select autovacuum_count from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_heap_cachehit_ratio[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select CASE heap_blks_hit+heap_blks_read WHEN 0 then 100 else round(heap_blks_hit*100/(heap_blks_hit+heap_blks_read), 2) end from pg_statio_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_idx_cachehit_ratio[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select CASE WHEN idx_blks_read is NULL then 0 when idx_blks_hit+idx_blks_read=0 then 100 else round(idx_blks_hit*100/(idx_blks_hit+idx_blks_read + 0.0001), 2) end from pg_statio_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_n_dead_tup[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select n_dead_tup from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_n_tup_del[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select n_tup_del from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_n_tup_hot_upd[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select n_tup_hot_upd from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_idx_scan[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select coalesce(idx_scan,0) from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_seq_tup_read[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select coalesce(seq_tup_read,0) from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_idx_tup_fetch[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select coalesce(idx_tup_fetch,0) from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_n_tup_ins[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select n_tup_ins from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_n_live_tup[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select n_live_tup from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_seq_scan[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select seq_scan from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_n_tup_upd[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select n_tup_upd from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_vacuum_count[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select vacuum_count from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_garbage_ratio[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select round(100*(CASE (n_live_tup+n_dead_tup) WHEN 0 THEN 0 ELSE (n_dead_tup/(n_live_tup+n_dead_tup)::numeric) END),2) from pg_stat_user_tables where schemaname = '%SCHEMANAME%' and relname = '%TABLENAME%') ^
				union all ^
				select '"%HOST_NAME%"', 'psql.table_total_size[%DBNAME%,%SCHEMANAME%,%TABLENAME%]', %TIMESTAMP_QUERY%, (select  pg_total_relation_size('%SCHEMANAME%.%TABLENAME%'))

rem Load the pgsql connection option parameters.
for /f "tokens=1,2 delims==" %%i in (%PGSHELL_CONFDIR%\pgsql_funcs.conf) do set %%i=%%j

if %APP_NAME%==pg.stat_table (
	psql -U %PGROLE% -h %PGHOST% -p %PGPORT% -d %DBNAME% -A --field-separator=" " -t -c "%sql_stat_table%">sending_data 2>&1
)else (
echo "%APP_NAME% did not match anything."
exit
)
if %errorlevel% NEQ 0 (
	type sending_data 
	del sending_data
	exit 
)

C:\zabbix_agents\bin\win64\zabbix_sender.exe -c %ZABBIX_AGENTD_CONF% -v -T -i sending_data>result 2>&1
for /f "tokens=1 delims=;" %%i in ('find /I "info" result') do (
	set var=%%i
	for /f "tokens=5 delims= " %%j in ("!var!") do set response=%%j
)
if defined response (
echo %response%
)else type result
del result sending_data
