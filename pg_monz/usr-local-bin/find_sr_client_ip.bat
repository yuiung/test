@echo off
setlocal enabledelayedexpansion
set PGSHELL_CONFDIR=%~1

set GETTABLE="select row_to_json(t) from (select client_addr as \"{#SRCLIENT}\" from pg_stat_replication) as t"

# Load the psql connection option parameters.
for /f "tokens=1,2 delims==" %%i in (%PGSHELL_CONFDIR%\pgsql_funcs.conf) do set %%i=%%j

psql -h %PGHOST% -p %PGPORT% -U %PGROLE% -d %PGDATABASE% -t -c %GETTABLE%>result 2>$1
if %errorlevel% NEQ 0 (
	type result 
	del result
	exit 
)

for /f "tokens=*" %%i in (result) do (
	set sr_client_list=!sr_client_list!,%%i
)
del result
if defined sr_client_list set sr_client_list=%sr_client_list:~1%
echo {"data":[%sr_client_list%]}
