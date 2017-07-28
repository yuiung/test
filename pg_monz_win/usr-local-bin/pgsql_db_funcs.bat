@echo off
setlocal enabledelayedexpansion

set APP_NAME=%~1
set PGSHELL_CONFDIR=%~2
set HOST_NAME="%~3"
set ZABBIX_AGENTD_CONF=%~4
set DBNAME=%~5

set TIMESTAMP_QUERY=extract(epoch from now())::int

set sql_stat=select '"%HOST_NAME%"', 'psql.db_connections[%DBNAME%]', %TIMESTAMP_QUERY%, (select numbackends from pg_stat_database where datname = '%DBNAME%') 	^
			union all 	^
			select '"%HOST_NAME%"', 'psql.cachehit_ratio[%DBNAME%]', %TIMESTAMP_QUERY%, (SELECT round(blks_hit*100/(blks_hit+blks_read), 2) AS cache_hit_ratio FROM pg_stat_database WHERE datname = '%DBNAME%' and blks_read ^> 0 union all select 0.00 AS cache_hit_ratio order by cache_hit_ratio desc limit 1) 	union all 	select '"%HOST_NAME%"', 'psql.db_tx_commited[%DBNAME%]', %TIMESTAMP_QUERY%, (select xact_commit from pg_stat_database where datname = '%DBNAME%') 	^
			union all 	^
			select '"%HOST_NAME%"', 'psql.db_deadlocks[%DBNAME%]', %TIMESTAMP_QUERY%, (select deadlocks from pg_stat_database where datname = '%DBNAME%') 	^
			union all 	^
			select '"%HOST_NAME%"', 'psql.db_tx_rolledback[%DBNAME%]', %TIMESTAMP_QUERY%, (select xact_rollback from pg_stat_database where datname = '%DBNAME%') 	^
			union all 	^
			select '"%HOST_NAME%"', 'psql.db_temp_bytes[%DBNAME%]', %TIMESTAMP_QUERY%, (select temp_bytes from pg_stat_database where datname = '%DBNAME%') 	^
			union all 	^
			select '"%HOST_NAME%"', 'psql.db_deleted[%DBNAME%]', %TIMESTAMP_QUERY%, (select tup_deleted from pg_stat_database where datname = '%DBNAME%') 	^
			union all 	^
			select '"%HOST_NAME%"', 'psql.db_fetched[%DBNAME%]', %TIMESTAMP_QUERY%, (select tup_fetched from pg_stat_database where datname = '%DBNAME%') 	^
			union all 	^
			select '"%HOST_NAME%"', 'psql.db_inserted[%DBNAME%]', %TIMESTAMP_QUERY%, (select tup_inserted from pg_stat_database where datname = '%DBNAME%') 	^
			union all 	^
			select '"%HOST_NAME%"', 'psql.db_returned[%DBNAME%]', %TIMESTAMP_QUERY%, (select tup_returned from pg_stat_database where datname = '%DBNAME%') 	^
			union all 	^
			select '"%HOST_NAME%"', 'psql.db_updated[%DBNAME%]', %TIMESTAMP_QUERY%, (select tup_updated from pg_stat_database where datname = '%DBNAME%')

rem Load the pgsql connection option parameters.
for /f "tokens=1,2 delims==" %%i in (%PGSHELL_CONFDIR%\pgsql_funcs.conf) do set %%i=%%j

if %APP_NAME%==pg.stat_database (
	psql -U %PGROLE% -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -A --field-separator=" " -t -c "%sql_stat%">sending_data 2>&1
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
for /f "tokens=1 delims=;" %%i in ('findstr "info" result') do (
	set var=%%i
	for /f "tokens=5 delims= " %%j in ("!var!") do set response=%%j
)
if defined response (
echo %response%
)else type result
del result sending_data