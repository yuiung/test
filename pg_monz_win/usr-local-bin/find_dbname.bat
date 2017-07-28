@echo off
setlocal enabledelayedexpansion
set PGSHELL_CONFDIR=%~1

rem Get list of Database Name which you want to monitor.
rem The default settings are excepted template databases(template0/template1).
rem
rem :Example
rem
rem If you want to monitor "foo" and "bar" databases, you set the GETDB as
rem GETDB="select datname from pg_database where datname in ('foo','bar');"


set GETDB="select datname from pg_database where datistemplate = 'f';"

rem Load the pgsql connection option parameters.
for /f "tokens=1,2 delims==" %%i in (%PGSHELL_CONFDIR%\pgsql_funcs.conf) do set %%i=%%j

psql -h %PGHOST% -p %PGPORT% -U %PGROLE% -d %PGDATABASE% -t -c %GETDB%>db.list 2>&1
if %errorlevel% NEQ 0 (
	type db.list 
	del db.list
	exit 
)

for /f "tokens=1 delims= " %%i in (db.list) do (
	set dblist=!dblist!,{"{#DBNAME}":"%%i"}
)
del db.list
if defined dblist set dblist=%dblist:~1%
echo {"data":[%dblist% ]}
