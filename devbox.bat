@echo off
REM DevBox Sandboxer Windows Batch Wrapper
REM This provides a simple way to run DevBox commands from Command Prompt

setlocal

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Check if PowerShell is available
where powershell >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: PowerShell is not available in PATH
    echo Please ensure PowerShell is installed and accessible
    exit /b 1
)

REM Check if devbox.ps1 exists
if not exist "%SCRIPT_DIR%devbox.ps1" (
    echo Error: devbox.ps1 not found in %SCRIPT_DIR%
    exit /b 1
)

REM Pass all arguments to PowerShell script
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%devbox.ps1" %*

endlocal
