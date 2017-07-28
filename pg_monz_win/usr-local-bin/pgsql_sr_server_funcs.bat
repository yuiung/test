@echo off
setlocal enabledelayedexpansion

set APP_NAME=%~1
set PGSHELL_CONFDIR=%~2
set HOST_NAME="%~3"
set ZABBIX_AGENTD_CONF=%~4

set TIMESTAMP_QUERY=extract(epoch from now())::int

set sql_stat_replication=select * from ( ^
			select '"%HOST_NAME%"', 'psql.write_diff['^|^|host(client_addr)^|^|']', %TIMESTAMP_QUERY%, pg_xlog_location_diff(sent_location, write_location) as value from pg_stat_replication ^
			union all ^
			select '"%HOST_NAME%"', 'psql.replay_diff['^|^|host(client_addr)^|^|']', %TIMESTAMP_QUERY%, pg_xlog_location_diff(sent_location, replay_location) as value from pg_stat_replication ^
			union all ^
			select '"%HOST_NAME%"', 'psql.sync_priority['^|^|host(client_addr)^|^|']', %TIMESTAMP_QUERY%, sync_priority as value from pg_stat_replication ^
			) as t where value is not null

set sql_status=select '"%HOST_NAME%"', 'psql.block_query', %TIMESTAMP_QUERY%, (select CASE count(setting) when 0 then 1 ELSE (select CASE (select pg_is_in_recovery()::int) when 1 then 1 ELSE (select CASE (select count(*) from pg_stat_replication where sync_priority ^> 0) when 0 then 0 else 1 END) END) END from pg_settings where name ^='synchronous_standby_names' and setting ^^^^^^!^^^='') ^
			union all ^
			SELECT '"%HOST_NAME%"','psql.confl_tablespace[' ^|^| datname ^|^| ']',%TIMESTAMP_QUERY%,confl_tablespace from pg_stat_database_conflicts where datname not in ('template1','template0') ^
			union all ^
			SELECT '"%HOST_NAME%"','psql.confl_lock[' ^|^| datname ^|^| ']',%TIMESTAMP_QUERY%,confl_lock from pg_stat_database_conflicts where datname not in ('template1','template0') ^
			union all ^
			SELECT '"%HOST_NAME%"','psql.confl_snapshot[' ^|^| datname ^|^| ']',%TIMESTAMP_QUERY%,confl_snapshot from pg_stat_database_conflicts where datname not in ('template1','template0') ^
			union all ^
			SELECT '"%HOST_NAME%"','psql.confl_bufferpin[' ^|^| datname ^|^| ']',%TIMESTAMP_QUERY%,confl_bufferpin from pg_stat_database_conflicts where datname not in ('template1','template0') ^
			union all ^
			SELECT '"%HOST_NAME%"','psql.confl_deadlock[' ^|^| datname ^|^| ']',%TIMESTAMP_QUERY%,confl_deadlock from pg_stat_database_conflicts where datname not in ('template1','template0')

rem Load the pgsql connection option parameters.
for /f "tokens=1,2 delims==" %%i in (%PGSHELL_CONFDIR%\pgsql_funcs.conf) do set %%i=%%j

if %APP_NAME%==pg.stat_replication (
	psql -U %PGROLE% -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -A --field-separator=" " -t -c "%sql_stat_replication%">sending_data 2>&1
	goto :next
)
if %APP_NAME%==pg.sr.status (
	psql -U %PGROLE% -h %PGHOST% -p %PGPORT% -d %PGDATABASE% -A --field-separator=" " -t -c "%sql_status%">sending_data 2>&1
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
