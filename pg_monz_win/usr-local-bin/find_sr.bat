@echo off
setlocal enabledelayedexpansion
set PGSHELL_CONFDIR=%~1

set GETROW="select count(*) from pg_stat_replication"

rem Load the psql connection option parameters.
for /f "tokens=1,2 delims==" %%i in (%PGSHELL_CONFDIR%\pgsql_funcs.conf) do set %%i=%%j

psql -h %PGHOST% -p %PGPORT% -U %PGROLE% -d %PGDATABASE% -t -c %GETROW%>result 2>$1
if %errorlevel% NEQ 0 (
	type result 
	del result
	exit 
)
set /p sr=<result
del result
set sr=%sr: =%
if %sr% GEQ 1 (
	echo {"data":[{"{#MODE}":"streaming"} ]}
	exit
)
echo {"data":[ ]}