@echo off
setlocal enabledelayedexpansion

set APP_NAME=%~1
set PGSHELL_CONFDIR=%~2
set HOST_NAME="%~3"
set ZABBIX_AGENTD_CONF=%~4
set DBNAME=%~5

set TIMESTAMP_QUERY=extract(epoch from now())::int

set sql_size=select '"%HOST_NAME%"', 'psql.db_size[%DBNAME%]', %TIMESTAMP_QUERY%, (select pg_database_size('%DBNAME%')) ^
			union all ^
			select '"%HOST_NAME%"', 'psql.db_garbage_ratio[%DBNAME%]', %TIMESTAMP_QUERY%, ( ^
			SELECT round(100*sum( ^
			CASE (a.n_live_tup+a.n_dead_tup) WHEN 0 THEN 0 ^
			ELSE c.relpages*(a.n_dead_tup/(a.n_live_tup+a.n_dead_tup)::numeric) ^
			END ^
			)/ sum(c.relpages),2) ^
			FROM ^
			pg_class as c join pg_stat_all_tables as a on(c.oid = a.relid) where relpages ^> 0)

rem Load the pgsql connection option parameters.
for /f "tokens=1,2 delims==" %%i in (%PGSHELL_CONFDIR%\pgsql_funcs.conf) do set %%i=%%j

if %APP_NAME%==pg.size (
	psql -U %PGROLE% -h %PGHOST% -p %PGPORT% -d %DBNAME% -A --field-separator=" " -t -c "%sql_size%">sending_data 2>&1
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
