@echo off
setlocal enabledelayedexpansion
rem ===============================================================================
rem   GLOBAL DECLARATIONS
rem ===============================================================================


set APP_NAME=%~1
set PGSHELL_CONFDIR=%~2
set HOST_NAME="%~3"
set ZABBIX_AGENTD_CONF=%~4
set PARAM1=%~5

rem Load the pgsql connection option parameters.
for /f "tokens=1,2 delims==" %%i in (%PGSHELL_CONFDIR%\pgsql_funcs.conf) do set %%i=%%j

set TIMESTAMP_QUERY=extract(epoch from now())::int

set sql_transactions=select '"%HOST_NAME%"', 'psql.tx_commited', %TIMESTAMP_QUERY%, (select sum(xact_commit) from pg_stat_database) ^
						union all ^
						select '"%HOST_NAME%"', 'psql.tx_rolledback', %TIMESTAMP_QUERY%, (select sum(xact_rollback) from pg_stat_database) ^
						union all ^
						select '"%HOST_NAME%"', 'psql.active_connections', %TIMESTAMP_QUERY%, (select count(*) from pg_stat_activity where state = 'active') ^
						union all ^
						select '"%HOST_NAME%"', 'psql.server_connections', %TIMESTAMP_QUERY%, (select count(*) from pg_stat_activity) ^
						union all ^
						select '"%HOST_NAME%"', 'psql.idle_connections', %TIMESTAMP_QUERY%, (select count(*) from pg_stat_activity where state = 'idle') ^
						union all ^
						select '"%HOST_NAME%"', 'psql.idle_tx_connections', %TIMESTAMP_QUERY%, (select count(*) from pg_stat_activity where state = 'idle in transaction') ^
						union all ^
						select '"%HOST_NAME%"', 'psql.locks_waiting', %TIMESTAMP_QUERY%, (select count(*) from pg_stat_activity where waiting = 'true') ^
						union all ^
						select '"%HOST_NAME%"', 'psql.server_maxcon', %TIMESTAMP_QUERY%, (select setting::int from pg_settings where name = 'max_connections')
						
set sql_bgwriter=select '"%HOST_NAME%"', 'psql.buffers_alloc', %TIMESTAMP_QUERY%, (select buffers_alloc from pg_stat_bgwriter) ^
						union all ^
						select '"%HOST_NAME%"', 'psql.buffers_backend', %TIMESTAMP_QUERY%, (select buffers_backend from pg_stat_bgwriter) ^
						union all ^
						select '"%HOST_NAME%"', 'psql.buffers_backend_fsync' , %TIMESTAMP_QUERY%, (select buffers_backend_fsync from pg_stat_bgwriter) ^
						union all ^
						select '"%HOST_NAME%"', 'psql.buffers_checkpoint', %TIMESTAMP_QUERY%, (select buffers_checkpoint from pg_stat_bgwriter) ^
						union all ^
						select '"%HOST_NAME%"', 'psql.buffers_clean', %TIMESTAMP_QUERY%, (select buffers_clean from pg_stat_bgwriter) ^
						union all ^
						select '"%HOST_NAME%"', 'psql.checkpoints_req', %TIMESTAMP_QUERY%, (select checkpoints_req from pg_stat_bgwriter) ^
						union all ^
						select '"%HOST_NAME%"', 'psql.checkpoints_timed', %TIMESTAMP_QUERY%, (select checkpoints_timed from pg_stat_bgwriter) ^
						union all ^
						select '"%HOST_NAME%"', 'psql.maxwritten_clean', %TIMESTAMP_QUERY%, (select maxwritten_clean from pg_stat_bgwriter)
						
set sql_slow_query=select '"%HOST_NAME%"', 'psql.slow_dml_queries', %TIMESTAMP_QUERY%, (select count(*) from pg_stat_activity where state = 'active' and now() - query_start ^> '%PARAM1% sec'::interval and query ~* '^^(insert^|update^|delete)') ^
						union all ^
						select '"%HOST_NAME%"', 'psql.slow_queries', %TIMESTAMP_QUERY%, (select count(*) from pg_stat_activity where state = 'active' and now() - query_start ^> '%PARAM1% sec'::interval) ^
						union all ^
						select '"%HOST_NAME%"', 'psql.slow_select_queries', %TIMESTAMP_QUERY%, (select count(*) from pg_stat_activity where state = 'active' and now() - query_start ^> '%PARAM1% sec'::interval and query ilike 'select%')
rem ===============================================================================
rem   MAIN SCRIPT
rem ===============================================================================
if %APP_NAME%==pg.transactions (
	psql -U %PGROLE% -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -A --field-separator=" " -t -c "%sql_transactions%">sending_data 2>&1
	goto :next
)
if %APP_NAME%==pg.bgwriter (
	psql -U %PGROLE% -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -A --field-separator=" " -t -c "%sql_bgwriter%">sending_data 2>&1
	goto :next
)
if %APP_NAME%==pg.slow_query (
	psql -U %PGROLE% -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -A --field-separator=" " -t -c "%sql_slow_query%">sending_data 2>&1
	goto :next
)
echo "%APP_NAME% did not match anything."
exit

:next
if %errorlevel% NEQ 0 (
	type sending_data 
	del sending_data
	exit 
)

C:\zabbix_agents\bin\win64\zabbix_sender.exe -c %ZABBIX_AGENTD_CONF% -v -T -i sending_data>result 2>&1
for /f "tokens=1 delims=;" %%i in ('findstr "info" result') do (
	set var=%%i
	for /f "tokens=5 delims= " %%j in ("!var!") do set response=%%j
)
if defined response ( echo %response% ) else type result
del result sending_data
