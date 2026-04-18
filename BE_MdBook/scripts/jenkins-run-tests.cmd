@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0.."
set "SERVICES_DIR=%ROOT_DIR%\services"

where mvn >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: 'mvn' is not available in PATH.
    echo Install Maven on the Jenkins agent or configure a Jenkins Maven tool.
    exit /b 1
)

if not exist "%SERVICES_DIR%" (
    echo ERROR: services directory not found at %SERVICES_DIR%
    exit /b 1
)

set "FOUND=0"

for /d %%D in ("%SERVICES_DIR%\*") do (
    if exist "%%~fD\pom.xml" (
        set "FOUND=1"
        echo.
        echo ==================================================
        echo Running tests for %%~nxD
        echo ==================================================
        pushd "%%~fD"
        call mvn -B -ntp clean test
        if errorlevel 1 (
            popd
            exit /b 1
        )
        popd
    )
)

if "%FOUND%"=="0" (
    echo ERROR: no Maven services found under %SERVICES_DIR%
    exit /b 1
)

echo.
echo All Maven service tests completed successfully.
