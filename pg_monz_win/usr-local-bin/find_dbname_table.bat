@echo off
setlocal enabledelayedexpansion
set PGSHELL_CONFDIR=%~1

rem For using this rules, you set the status to enable from
rem [Configuration]->[Hosts]->[Discovery]->[DB and Table Name List]
rem at Zabbix WEB.

rem Get list of Database Name which you want to monitor.
rem The default settings are excepted template databases(template0/template1).
rem
rem :Customize Example
rem
rem For "foo" and "bar" databases, set the GETDB as
rem GETDB="select datname from pg_database where datname in ('foo','bar');"

set GETDB="select datname from pg_database where datistemplate = 'f';"

rem Get List of Table Name
rem Using the default setting, Zabbix make a discovery "ALL" user tables.
rem If you want to specify the tables, you can change the $GETTABLE query.
rem
rem :Customize Example
rem
rem For pgbench tables, set the GETTABLE as
rem GETTABLE="select \
rem            row_to_json(t) \
rem          from (
rem            select current_database() as "{#DBNAME}\",schemaname as \"{#SCHEMANAME}\",tablename as \"{#TABLENAME}\" \
rem            from \
rem              pg_tables \
rem            where \
rem              schemaname not in ('pg_catalog','information_schema') \
rem            and \
rem              tablename in ('pgbench_accounts','pgbench_branches','pgbench_history','pgbench_tellers') \
rem           ) as t"

set GETTABLE="select row_to_json(t) from (select current_database() as \"{#DBNAME}\",schemaname as \"{#SCHEMANAME}\",tablename as \"{#TABLENAME}\" from pg_tables where schemaname not in ('pg_catalog','information_schema')) as t"

rem Load the psql connection option parameters.
for /f "tokens=1,2 delims==" %%i in (%PGSHELL_CONFDIR%/pgsql_funcs.conf) do set %%i=%%j

rem This low level discovery rules are disabled by deafult.
psql -h %PGHOST% -p %PGPORT% -U %PGROLE% -d %PGDATABASE% -t -c %GETDB%>db.list 2>&1
if %errorlevel% NEQ 0  (
	type db.list 
	del db.list
	exit 
)


for /f "tokens=1 delims= " %%x in (db.list) do (
	psql -h %PGHOST% -p %PGPORT% -U %PGROLE% -d %%x -t -c %GETTABLE%>table.list 2>&1
	if %errorlevel% NEQ 0 (
		type table.list 
		del table.list
		exit
	)
	for /f "tokens=1 delims= " %%y in (table.list) do (
		set tablelist=!tablelist!,%%y
	)	
)
del /q *.list
if defined tablelist set tablelist=%tablelist:~1%
echo {"data":[%tablelist% ]}
