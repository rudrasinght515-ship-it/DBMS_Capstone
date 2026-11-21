# ===============================================================================
# CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
# PowerShell Automated Database Runner
# ===============================================================================

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "            CAMPUSFIX: SMART CAMPUS COMPLAINT & MAINTENANCE SYSTEM" -ForegroundColor Yellow
Write-Host "                     Automated One-Click Database Runner" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Locate MySQL Client
$mysqlExe = $null

if (Get-Command mysql -ErrorAction SilentlyContinue) {
    $mysqlExe = "mysql"
} elseif (Test-Path "C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe") {
    $mysqlExe = "C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe"
} elseif (Test-Path "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe") {
    $mysqlExe = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
} else {
    $mysqlExe = Read-Host "Enter full path to mysql.exe"
}

Write-Host "[*] Using MySQL Client: $mysqlExe" -ForegroundColor Green
Write-Host ""

$dbHost = "127.0.0.1"
$dbPort = "3306"
$dbUser = "root"
$dbPass = Read-Host "Enter MySQL password for '$dbUser' (press Enter if no password)"

# Build argument array
function Run-MysqlScript([string]$scriptPath, [string]$database = "") {
    $argsList = @("-h", $dbHost, "-P", $dbPort, "-u", $dbUser)
    if (![string]::IsNullOrEmpty($dbPass)) {
        $argsList += "-p$dbPass"
    }
    if (![string]::IsNullOrEmpty($database)) {
        $argsList += $database
    }

    Get-Content $scriptPath | & $mysqlExe $argsList
}

Write-Host "[*] Testing connection to MySQL Server..." -ForegroundColor Yellow
$testArgs = @("-h", $dbHost, "-P", $dbPort, "-u", $dbUser, "-e", "SELECT 1;")
if (![string]::IsNullOrEmpty($dbPass)) { $testArgs += "-p$dbPass" }

& $mysqlExe $testArgs 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ERROR: Cannot connect to MySQL on $dbHost:$dbPort." -ForegroundColor Red
    Write-Host "    Make sure the MySQL service is started (e.g. 'net start MySQL80' or via services.msc)." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Connected successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "[1/3] Deploying master schema, tables, indexes, 208 seed records, views, and procedures..." -ForegroundColor Cyan
Run-MysqlScript "database\00_run_all.sql"
Write-Host "      -> Deployment completed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "[2/3] Executing 16-point automated data integrity test suite..." -ForegroundColor Cyan
Run-MysqlScript "database\10_data_validation.sql" "campusfix"
Write-Host "      -> Integrity tests completed!" -ForegroundColor Green
Write-Host ""

Write-Host "[3/3] Generating executive management reports..." -ForegroundColor Cyan
Run-MysqlScript "database\11_management_reports.sql" "campusfix"
Write-Host "      -> Reports generated!" -ForegroundColor Green
Write-Host ""

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "        CAMPUSFIX DATABASE DEPLOYMENT & VERIFICATION FULLY COMPLETE!" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "To run the interactive menu showcase, run: .\demo.bat" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to finish"
