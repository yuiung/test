@echo off
setlocal enabledelayedexpansion
set PGSHELL_CONFDIR=%~1


rem Load the pgsql connection option parameters.
for /f "tokens=1,2 delims==" %%i in (%PGSHELL_CONFDIR%\pgsql_funcs.conf) do set %%i=%%j

psql -A -t -h %PGHOST% -p %PGPORT% -U %PGROLE% -d %PGDATABASE% -c "select pg_is_in_recovery()::int">result 2>$1
type result
del result
