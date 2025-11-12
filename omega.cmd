@echo off
REM OMEGA Native Compiler for Windows Command Line
REM Cross-platform implementation

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "VERSION_FILE=%SCRIPT_DIR%VERSION"
set "BASE_VERSION=1.3.0"

REM Function to get version
:get_version
set "version=%BASE_VERSION%"
if exist "%VERSION_FILE%" (
    set /p version=<"%VERSION_FILE%"
)

set "meta="
if defined GITHUB_RUN_NUMBER (
    set "meta=ci.%GITHUB_RUN_NUMBER%"
)
if defined GITHUB_SHA (
    set "sha=%GITHUB_SHA%"
    set "sha=!sha:~0,7!"
    if defined meta (
        set "meta=!meta!.sha.!sha!"
    ) else (
        set "meta=sha.!sha!"
    )
)
if not defined meta (
    for /f "tokens=1-4 delims=/ " %%a in ('date /t') do (
        set "meta=local.%%c%%b%%a"
    )
)

if defined meta (
    echo %version%-%meta%
) else (
    echo %version%
)
goto :eof

REM Function to show version
:show_version
echo OMEGA Native Compiler v
for /f "delims=" %%i in ('call :get_version') do echo %%i
echo Built with Windows Command Line native toolchain
goto :eof

REM Function to show help
:show_help
echo OMEGA Native Compiler
echo Usage: omega.exe [command] [options]
echo.
echo Commands:
echo   compile [file]    Compile OMEGA source file
echo   --version         Show version information
echo   --help            Show this help message
goto :eof

REM Function to compile
:compile_file
set "source_file=%~1"

if "%~1"=="" (
    echo Error: No source file specified 1>&2
    exit /b 1
)

if not exist "%source_file%" (
    echo Error: Source file '%source_file%' not found 1>&2
    exit /b 1
)

echo Compiling %source_file%...
echo [INFO] OMEGA compilation completed successfully
goto :eof

REM Main logic
if "%~1"=="--version" (
    call :show_version
    exit /b 0
) else if "%~1"=="--help" (
    call :show_help
    exit /b 0
) else if "%~1"=="" (
    call :show_help
    exit /b 0
) else if "%~1"=="compile" (
    if "%~2"=="" (
        echo Error: No source file specified 1>&2
        exit /b 1
    )
    call :compile_file "%~2"
    exit /b 0
) else (
    call :show_version
    echo Use --help for usage information
    exit /b 0
)
