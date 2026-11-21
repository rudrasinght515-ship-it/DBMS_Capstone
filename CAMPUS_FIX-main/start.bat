@echo off
title CAMPUSFIX - Smart Campus DBMS Live Showcase
color 0B

echo ===============================================================================
echo            CAMPUSFIX: SMART CAMPUS COMPLAINT & MAINTENANCE SYSTEM
echo                         ONE-CLICK INSTANT LAUNCHER
echo ===============================================================================
echo.
echo [*] Initializing CAMPUSFIX Database...
echo [*] Seeding 8 Relational Tables (208 records)...
echo [*] Starting Local Web Dashboard on http://127.0.0.1:5000...
echo [*] Opening your browser automatically...
echo.
echo ===============================================================================
echo   To stop the server: close this window or press Ctrl + C.
echo   All original MySQL 8.0 scripts (01 to 11) are preserved in the 'database' folder.
echo ===============================================================================
echo.

python app.py

if %ERRORLEVEL% neq 0 (
    echo.
    echo [!] Python was not detected in PATH.
    echo     Please make sure Python 3 is installed, or run:
    echo     python app.py
    echo.
    pause
)
