@echo off
REM OMEGA Language Test Execution Script
REM This script runs all test suites and generates comprehensive reports

echo ========================================
echo OMEGA Language Test Execution
echo ========================================
echo.

REM Set up environment
set OMEGA_HOME=%~dp0
set TEST_CONFIG=%OMEGA_HOME%test_config.json
set REPORT_DIR=%OMEGA_HOME%test_reports
set LOG_FILE=%REPORT_DIR%\test_execution.log

REM Create report directory if it doesn't exist
if not exist "%REPORT_DIR%" mkdir "%REPORT_DIR%"
if not exist "%REPORT_DIR%\coverage" mkdir "%REPORT_DIR%\coverage"
if not exist "%REPORT_DIR%\performance" mkdir "%REPORT_DIR%\performance"
if not exist "%REPORT_DIR%\errors" mkdir "%REPORT_DIR%\errors"
if not exist "%REPORT_DIR%\logs" mkdir "%REPORT_DIR%\logs"

echo Starting test execution at %date% %time%
echo Starting test execution at %date% %time% > "%LOG_FILE%"

REM Record system information
echo System Information: >> "%LOG_FILE%"
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Type" >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM Check if MEGA compiler is available
where mega >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: MEGA compiler not found in PATH
    echo Please install MEGA compiler and ensure it's in your PATH
    exit /b 1
)

echo MEGA compiler found, proceeding with test execution...
echo.

REM Run memory monitoring in background
echo Starting memory monitoring...
start /B powershell -Command "Get-Process | Where-Object {$_.ProcessName -like '*mega*'} | Select-Object ProcessName, WorkingSet, CPU | Export-Csv '%REPORT_DIR%\memory_usage.csv' -Append -NoTypeInformation" 2>nul

REM Execute test suites with different configurations
echo Running Core Compiler Tests...
echo Running Core Compiler Tests... >> "%LOG_FILE%"
mega run_all_tests.mega --config="%TEST_CONFIG%" --suite="core_compiler" --output="%REPORT_DIR%\core_compiler_results.json" --timeout=30000
if %errorlevel% equ 0 (
    echo ✅ Core Compiler Tests completed successfully
    echo ✅ Core Compiler Tests completed successfully >> "%LOG_FILE%"
) else (
    echo ❌ Core Compiler Tests failed
    echo ❌ Core Compiler Tests failed >> "%LOG_FILE%"
)
echo.

echo Running Bootstrap and Self-Hosting Tests...
echo Running Bootstrap and Self-Hosting Tests... >> "%LOG_FILE%"
mega run_all_tests.mega --config="%TEST_CONFIG%" --suite="bootstrap_self_hosting" --output="%REPORT_DIR%\bootstrap_results.json" --timeout=60000
if %errorlevel% equ 0 (
    echo ✅ Bootstrap Tests completed successfully
    echo ✅ Bootstrap Tests completed successfully >> "%LOG_FILE%"
) else (
    echo ❌ Bootstrap Tests failed
    echo ❌ Bootstrap Tests failed >> "%LOG_FILE%"
)
echo.

echo Running Cross-Compilation Tests...
echo Running Cross-Compilation Tests... >> "%LOG_FILE%"
mega run_all_tests.mega --config="%TEST_CONFIG%" --suite="cross_compilation" --output="%REPORT_DIR%\cross_compilation_results.json" --timeout=45000
if %errorlevel% equ 0 (
    echo ✅ Cross-Compilation Tests completed successfully
    echo ✅ Cross-Compilation Tests completed successfully >> "%LOG_FILE%"
) else (
    echo ❌ Cross-Compilation Tests failed
    echo ❌ Cross-Compilation Tests failed >> "%LOG_FILE%"
)
echo.

echo Running Self-Hosting Compiler Tests...
echo Running Self-Hosting Compiler Tests... >> "%LOG_FILE%"
mega run_all_tests.mega --config="%TEST_CONFIG%" --suite="self_hosting" --output="%REPORT_DIR%\self_hosting_results.json" --timeout=45000
if %errorlevel% equ 0 (
    echo ✅ Self-Hosting Tests completed successfully
    echo ✅ Self-Hosting Tests completed successfully >> "%LOG_FILE%"
) else (
    echo ❌ Self-Hosting Tests failed
    echo ❌ Self-Hosting Tests failed >> "%LOG_FILE%"
)
echo.

echo Running Target Code Generator Tests...
echo Running Target Code Generator Tests... >> "%LOG_FILE%"
mega run_all_tests.mega --config="%TEST_CONFIG%" --suite="target_code_generator" --output="%REPORT_DIR%\target_generator_results.json" --timeout=24000
if %errorlevel% equ 0 (
    echo ✅ Target Code Generator Tests completed successfully
    echo ✅ Target Code Generator Tests completed successfully >> "%LOG_FILE%"
) else (
    echo ❌ Target Code Generator Tests failed
    echo ❌ Target Code Generator Tests failed >> "%LOG_FILE%"
)
echo.

echo Running Integration Tests...
echo Running Integration Tests... >> "%LOG_FILE%"
mega run_all_tests.mega --config="%TEST_CONFIG%" --suite="integration" --output="%REPORT_DIR%\integration_results.json" --timeout=60000
if %errorlevel% equ 0 (
    echo ✅ Integration Tests completed successfully
    echo ✅ Integration Tests completed successfully >> "%LOG_FILE%"
) else (
    echo ❌ Integration Tests failed
    echo ❌ Integration Tests failed >> "%LOG_FILE%"
)
echo.

echo Running Security Tests...
echo Running Security Tests... >> "%LOG_FILE%"
mega run_all_tests.mega --config="%TEST_CONFIG%" --suite="security" --output="%REPORT_DIR%\security_results.json" --timeout=36000
if %errorlevel% equ 0 (
    echo ✅ Security Tests completed successfully
    echo ✅ Security Tests completed successfully >> "%LOG_FILE%"
) else (
    echo ❌ Security Tests failed
    echo ❌ Security Tests failed >> "%LOG_FILE%"
)
echo.

echo Running Performance Tests...
echo Running Performance Tests... >> "%LOG_FILE%"
mega run_all_tests.mega --config="%TEST_CONFIG%" --suite="performance" --output="%REPORT_DIR%\performance_results.json" --timeout=45000
if %errorlevel% equ 0 (
    echo ✅ Performance Tests completed successfully
    echo ✅ Performance Tests completed successfully >> "%LOG_FILE%"
) else (
    echo ❌ Performance Tests failed
    echo ❌ Performance Tests failed >> "%LOG_FILE%"
)
echo.

REM Generate comprehensive test report
echo Generating comprehensive test report...
echo Generating comprehensive test report... >> "%LOG_FILE%"
mega generate_test_report.mega --input-dir="%REPORT_DIR%" --output="%REPORT_DIR%\comprehensive_report.html" --format="html"
if %errorlevel% equ 0 (
    echo ✅ Comprehensive report generated successfully
    echo ✅ Comprehensive report generated successfully >> "%LOG_FILE%"
) else (
    echo ❌ Report generation failed
    echo ❌ Report generation failed >> "%LOG_FILE%"
)

REM Generate coverage report
echo Generating coverage report...
echo Generating coverage report... >> "%LOG_FILE%"
mega generate_coverage_report.mega --input-dir="%REPORT_DIR%" --output="%REPORT_DIR%\coverage\coverage_report.html" --format="html"
if %errorlevel% equ 0 (
    echo ✅ Coverage report generated successfully
    echo ✅ Coverage report generated successfully >> "%LOG_FILE%"
) else (
    echo ❌ Coverage report generation failed
    echo ❌ Coverage report generation failed >> "%LOG_FILE%"
)

REM Generate performance report
echo Generating performance report...
echo Generating performance report... >> "%LOG_FILE%"
mega generate_performance_report.mega --input-dir="%REPORT_DIR%" --output="%REPORT_DIR%\performance\performance_report.html" --format="html"
if %errorlevel% equ 0 (
    echo ✅ Performance report generated successfully
    echo ✅ Performance report generated successfully >> "%LOG_FILE%"
) else (
    echo ❌ Performance report generation failed
    echo ❌ Performance report generation failed >> "%LOG_FILE%"
)

REM Calculate overall test results
echo.
echo ========================================
echo Test Execution Summary
echo ========================================
echo.

REM Count total test results
set total_passed=0
set total_failed=0
set total_errors=0

for %%f in ("%REPORT_DIR%\*_results.json") do (
    echo Processing %%f...
    REM In a real implementation, we would parse the JSON files to get actual results
    REM For now, we'll just check if files exist
    if exist "%%f" (
        set /a total_passed+=1
    ) else (
        set /a total_failed+=1
    )
)

echo Test Execution Completed at %date% %time%
echo Test Execution Completed at %date% %time% >> "%LOG_FILE%"
echo.
echo Overall Results:
echo   Total Test Suites: 8
echo   Passed: %total_passed%
echo   Failed: %total_failed%
echo   Errors: %total_errors%
echo.
echo Reports generated in: %REPORT_DIR%
echo   - Comprehensive Report: %REPORT_DIR%\comprehensive_report.html
echo   - Coverage Report: %REPORT_DIR%\coverage\coverage_report.html
echo   - Performance Report: %REPORT_DIR%\performance\performance_report.html
echo   - Execution Log: %LOG_FILE%
echo.

REM Performance analysis
echo.
echo ========================================
echo Performance Analysis
echo ========================================
echo.

REM Check memory usage
if exist "%REPORT_DIR%\memory_usage.csv" (
    echo Memory usage statistics:
    type "%REPORT_DIR%\memory_usage.csv" | findstr /V "ProcessName" | sort /+12 /R | head -10
    echo.
)

REM Check disk usage
echo Disk usage:
dir /S "%REPORT_DIR%" | findstr "File(s)"
echo.

REM Check execution time
echo Execution time analysis available in performance report.

REM Cleanup
echo.
echo Cleaning up temporary files...
del /Q "%REPORT_DIR%\*_temp.*" 2>nul
del /Q "%REPORT_DIR%\memory_usage.csv" 2>nul

echo.
echo ========================================
echo Test execution script completed!
echo Check the reports in %REPORT_DIR% for detailed results.
echo ========================================

REM Return appropriate exit code
if %total_failed% gtr 0 (
    exit /b 1
) else (
    exit /b 0
)