@echo off
setlocal enabledelayedexpansion
title CAMPUSFIX - Interactive Showcase ^& Viva Demonstration Console
color 0A

:: Locate MySQL Client
set "MYSQL_EXE="
where mysql >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "MYSQL_EXE=mysql"
) else (
    if exist "C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe" (
        set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe"
    ) else if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" (
        set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
    ) else (
        echo [!] mysql.exe not found automatically.
        set /p MYSQL_EXE="Enter path to mysql.exe: "
    )
)

set "DB_HOST=127.0.0.1"
set "DB_PORT=3306"
set "DB_USER=root"

echo ===============================================================================
echo            CAMPUSFIX: SMART CAMPUS COMPLAINT ^& MAINTENANCE SYSTEM
echo                   Interactive Showcase ^& Evaluation Console
echo ===============================================================================
echo.
set /p DB_PASS="Enter MySQL password for '%DB_USER%' (press Enter if no password): "

set "CMD_PREFIX="!MYSQL_EXE!" -h %DB_HOST% -P %DB_PORT% -u %DB_USER%"
if not "%DB_PASS%"=="" set "CMD_PREFIX=!CMD_PREFIX! -p%DB_PASS%"

:MENU
cls
echo ===============================================================================
echo            CAMPUSFIX: SMART CAMPUS COMPLAINT ^& MAINTENANCE SYSTEM
echo                                MAIN MENU
echo ===============================================================================
echo.
echo   [1] One-Click Setup / Reset Database (Deploys 00_run_all.sql)
echo   [2] View Active Triage Queue (View: v_pending_complaints)
echo   [3] View Staff Workload ^& Performance (View: v_staff_workload)
echo   [4] View Department Reliability Statistics (View: v_department_statistics)
echo   [5] Run Live Interactive Workflow Demo (Assign -^> Progress -^> Audit -^> Review)
echo   [6] Run Automated 16-Point Data Integrity Audit (10_data_validation.sql)
echo   [7] View Executive Management KPI Reports (11_management_reports.sql)
echo   [8] Open MySQL Workbench GUI
echo   [9] Exit
echo.
echo ===============================================================================
set /p CHOICE="Select an option [1-9]: "

if "%CHOICE%"=="1" goto :SETUP_DB
if "%CHOICE%"=="2" goto :VIEW_TRIAGE
if "%CHOICE%"=="3" goto :VIEW_WORKLOAD
if "%CHOICE%"=="4" goto :VIEW_DEPT_STATS
if "%CHOICE%"=="5" goto :LIVE_DEMO
if "%CHOICE%"=="6" goto :RUN_AUDIT
if "%CHOICE%"=="7" goto :RUN_REPORTS
if "%CHOICE%"=="8" goto :OPEN_WORKBENCH
if "%CHOICE%"=="9" goto :EXIT
goto :MENU

:SETUP_DB
cls
echo [*] Deploying full CAMPUSFIX schema, tables, indexes, 208 records, views, and procedures...
echo.
!CMD_PREFIX! < database\00_run_all.sql
echo.
echo [OK] Database deployment completed!
pause
goto :MENU

:VIEW_TRIAGE
cls
echo [*] Fetching Active Triage Queue (View 2)...
echo.
!CMD_PREFIX! -t campusfix -e "SELECT complaint_id, title, category, priority, status, age_hours, student_name, department_name, location_summary FROM v_pending_complaints LIMIT 10;"
echo.
pause
goto :MENU

:VIEW_WORKLOAD
cls
echo [*] Fetching Maintenance Technician Workload (View 3)...
echo.
!CMD_PREFIX! -t campusfix -e "SELECT staff_id, staff_name, staff_role, department_name, total_assigned_complaints, active_complaints, resolved_complaints FROM v_staff_workload ORDER BY active_complaints DESC;"
echo.
pause
goto :MENU

:VIEW_DEPT_STATS
cls
echo [*] Fetching Academic Department Reliability & Satisfaction Statistics (View 4)...
echo.
!CMD_PREFIX! -t campusfix -e "SELECT department_name, total_complaints, resolved_complaints, pending_complaints, average_feedback_rating FROM v_department_statistics;"
echo.
pause
goto :MENU

:LIVE_DEMO
cls
echo [*] Executing Live Step-by-Step Interactive Workflow Demo...
echo.
!CMD_PREFIX! -t campusfix < database\12_interactive_demo.sql
echo.
echo [OK] Interactive workflow completed!
pause
goto :MENU

:RUN_AUDIT
cls
echo [*] Executing 16-Point Data Integrity Assertion Suite...
echo.
!CMD_PREFIX! -t campusfix < database\10_data_validation.sql
echo.
pause
goto :MENU

:RUN_REPORTS
cls
echo [*] Generating 10 Executive Management & MTTR Reports...
echo.
!CMD_PREFIX! -t campusfix < database\11_management_reports.sql
echo.
pause
goto :MENU

:OPEN_WORKBENCH
if exist "C:\Program Files\MySQL\MySQL Workbench 8.0 CE\MySQLWorkbench.exe" (
    start "" "C:\Program Files\MySQL\MySQL Workbench 8.0 CE\MySQLWorkbench.exe"
    echo [OK] Launched MySQL Workbench!
) else (
    echo [!] MySQL Workbench executable not found at standard path.
)
pause
goto :MENU

:EXIT
echo.
echo Thank you for evaluating CAMPUSFIX!
exit /b 0
