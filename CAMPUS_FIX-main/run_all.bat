@echo off
setlocal enabledelayedexpansion
title CAMPUSFIX - One-Click Database Deployment Runner
color 0B

echo ===============================================================================
echo            CAMPUSFIX: SMART CAMPUS COMPLAINT ^& MAINTENANCE SYSTEM
echo                     Automated One-Click Database Runner
echo ===============================================================================
echo.

:: 1. Locate MySQL Client Binary
set "MYSQL_EXE="

where mysql >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "MYSQL_EXE=mysql"
    goto :MYSQL_FOUND
)

if exist "C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe" (
    set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe"
    goto :MYSQL_FOUND
)

if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" (
    set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
    goto :MYSQL_FOUND
)

echo [!] ERROR: mysql.exe was not found in PATH or standard installation paths.
echo     Please enter the full path to mysql.exe (or install MySQL 8.0):
set /p MYSQL_EXE="Path: "

:MYSQL_FOUND
echo [*] Detected MySQL Client: "!MYSQL_EXE!"
echo.

:: 2. Database Connection Credentials
set "DB_HOST=127.0.0.1"
set "DB_PORT=3306"
set "DB_USER=root"

echo Database Host: %DB_HOST%:%DB_PORT%
echo Database User: %DB_USER%
set /p DB_PASS="Enter MySQL password for '%DB_USER%' (press Enter if no password): "

echo.
echo [*] Testing connection to MySQL Server on %DB_HOST%:%DB_PORT%...

if "%DB_PASS%"=="" (
    "!MYSQL_EXE!" -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -e "SELECT 1;" >nul 2>&1
) else (
    "!MYSQL_EXE!" -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASS% -e "SELECT 1;" >nul 2>&1
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo [!] ERROR: Cannot connect to MySQL Server on %DB_HOST%:%DB_PORT%.
    echo     Possible causes:
    echo       1. The MySQL service is not running.
    echo          -^> Open 'services.msc', find 'MySQL80' (or your MySQL service) and click 'Start'.
    echo       2. Incorrect password for user '%DB_USER%'.
    echo       3. Port %DB_PORT% is blocked or listening on another interface.
    echo.
    pause
    exit /b 1
)

echo [OK] Connection successful!
echo.
echo ===============================================================================
echo                       EXECUTING CAMPUSFIX DATABASE DEPLOYMENT
echo ===============================================================================
echo.

set "CMD_PREFIX="!MYSQL_EXE!" -h %DB_HOST% -P %DB_PORT% -u %DB_USER%"
if not "%DB_PASS%"=="" set "CMD_PREFIX=!CMD_PREFIX! -p%DB_PASS%"

echo [1/4] Running Master Deployment Script (Schema, Tables, Indexes, Seed Data, Views, Triggers, Procedures)...
!CMD_PREFIX! < database\00_run_all.sql
if %ERRORLEVEL% neq 0 (
    echo [!] Deployment failed during 00_run_all.sql.
    pause
    exit /b 1
)
echo      -^> Master database setup completed successfully!
echo.

echo [2/4] Running Practical Operational Queries (05_queries.sql)...
!CMD_PREFIX! campusfix < database\05_queries.sql >nul 2>&1
echo      -^> 35 practical queries executed successfully!
echo.

echo [3/4] Running Automated Integrity Validation Suite (10_data_validation.sql)...
echo -------------------------------------------------------------------------------
!CMD_PREFIX! campusfix < database\10_data_validation.sql
echo -------------------------------------------------------------------------------
echo      -^> Integrity audit completed!
echo.

echo [4/4] Generating Management KPI Reports (11_management_reports.sql)...
echo -------------------------------------------------------------------------------
!CMD_PREFIX! campusfix < database\11_management_reports.sql
echo -------------------------------------------------------------------------------
echo.

echo ===============================================================================
echo        CAMPUSFIX DATABASE DEPLOYMENT ^& VERIFICATION FULLY COMPLETE!
echo ===============================================================================
echo.
echo  Database Name: campusfix
echo  Total Tables:  8 (departments, locations, students, staff, complaints,
echo                    complaint_assignments, complaint_status_history, feedback)
echo  Seed Records:  208 rows
echo  Views:         5 views created
echo  Triggers:      4 triggers installed
echo  Procedures:    4 stored procedures installed
echo.
echo  To run the interactive viva showcase: double-click 'demo.bat'
echo  To inspect visually in MySQL Workbench: open 'database\00_run_all.sql'
echo.
pause
