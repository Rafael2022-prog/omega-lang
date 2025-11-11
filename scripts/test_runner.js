#!/usr/bin/env node

/**
 * OMEGA Memory Management Test Runner
 * 
 * This script runs all memory management tests and generates comprehensive reports.
 * It validates the implementation of memory pool, garbage collector, and memory manager.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Test configuration
const TEST_CONFIG = {
    omegaCompiler: process.env.OMEGA_COMPILER || 'omega',
    testDir: path.join(__dirname, '../tests/memory'),
    outputDir: path.join(__dirname, '../test_output'),
    timeout: 300000, // 5 minutes timeout for each test
    verbose: process.argv.includes('--verbose') || process.env.VERBOSE === 'true',
    generateReport: process.argv.includes('--report') || process.env.GENERATE_REPORT === 'true',
    runSpecific: process.argv.find(arg => arg.startsWith('--test='))?.split('=')[1],
    skipIntegration: process.argv.includes('--skip-integration'),
    skipStress: process.argv.includes('--skip-stress'),
    skipBenchmark: process.argv.includes('--skip-benchmark')
};

// Test files to run
const TEST_FILES = [
    'test_main.mega',
    'test_memory_manager.mega',
    'test_runner.mega',
    'test_config.mega'
];

// Test categories
const TEST_CATEGORIES = [
    'basic_allocation',
    'memory_pool',
    'garbage_collector',
    'integration',
    'stress',
    'edge_cases',
    'performance',
    'security',
    'regression'
];

// Color codes for terminal output
const COLORS = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m'
};

// Test results storage
let testResults = {
    startTime: new Date(),
    totalTests: 0,
    passedTests: 0,
    failedTests: 0,
    skippedTests: 0,
    executionTime: 0,
    categories: {},
    details: []
};

/**
 * Initialize the test environment
 */
function initializeTestEnvironment() {
    console.log(`${COLORS.bright}${COLORS.blue}🚀 Initializing OMEGA Memory Management Test Environment${COLORS.reset}`);
    
    // Create output directory
    if (!fs.existsSync(TEST_CONFIG.outputDir)) {
        fs.mkdirSync(TEST_CONFIG.outputDir, { recursive: true });
    }
    
    // Check if OMEGA compiler is available
    try {
        execSync(`${TEST_CONFIG.omegaCompiler} --version`, { stdio: 'ignore' });
        logInfo('✅ OMEGA compiler found and working');
    } catch (error) {
        logError('❌ OMEGA compiler not found or not working');
        logInfo(`   Please ensure OMEGA compiler is installed and accessible as '${TEST_CONFIG.omegaCompiler}'`);
        process.exit(1);
    }
    
    // Check test files
    const missingFiles = TEST_FILES.filter(file => {
        const filePath = path.join(TEST_CONFIG.testDir, file);
        return !fs.existsSync(filePath);
    });
    
    if (missingFiles.length > 0) {
        logError(`❌ Missing test files: ${missingFiles.join(', ')}`);
        process.exit(1);
    }
    
    logInfo('✅ Test environment initialized successfully');
}

/**
 * Run individual test file
 */
function runTestFile(testFile) {
    const filePath = path.join(TEST_CONFIG.testDir, testFile);
    const outputFile = path.join(TEST_CONFIG.outputDir, `${path.parse(testFile).name}.output`);
    const errorFile = path.join(TEST_CONFIG.outputDir, `${path.parse(testFile).name}.error`);
    
    logInfo(`\n📄 Running test file: ${testFile}`);
    
    try {
        const startTime = Date.now();
        
        // Compile the test file
        const compileCommand = `${TEST_CONFIG.omegaCompiler} compile "${filePath}" --output "${outputFile}"`;
        
        if (TEST_CONFIG.verbose) {
            logInfo(`   Compiling: ${compileCommand}`);
        }
        
        const compileOutput = execSync(compileCommand, {
            timeout: TEST_CONFIG.timeout,
            encoding: 'utf8',
            stdio: TEST_CONFIG.verbose ? 'inherit' : 'pipe'
        });
        
        // Run the compiled test
        const runCommand = `${TEST_CONFIG.omegaCompiler} run "${outputFile}"`;
        
        if (TEST_CONFIG.verbose) {
            logInfo(`   Running: ${runCommand}`);
        }
        
        const runOutput = execSync(runCommand, {
            timeout: TEST_CONFIG.timeout,
            encoding: 'utf8',
            stdio: TEST_CONFIG.verbose ? 'inherit' : 'pipe'
        });
        
        const executionTime = Date.now() - startTime;
        
        // Parse test results from output
        const testResult = parseTestOutput(runOutput, testFile);
        testResult.executionTime = executionTime;
        
        // Store results
        testResults.details.push(testResult);
        testResults.totalTests += testResult.totalTests;
        testResults.passedTests += testResult.passedTests;
        testResults.failedTests += testResult.failedTests;
        testResults.skippedTests += testResult.skippedTests;
        
        // Update category results
        if (!testResults.categories[testResult.category]) {
            testResults.categories[testResult.category] = {
                total: 0,
                passed: 0,
                failed: 0,
                skipped: 0
            };
        }
        
        testResults.categories[testResult.category].total += testResult.totalTests;
        testResults.categories[testResult.category].passed += testResult.passedTests;
        testResults.categories[testResult.category].failed += testResult.failedTests;
        testResults.categories[testResult.category].skipped += testResult.skippedTests;
        
        logInfo(`   ✅ Test completed in ${executionTime}ms`);
        
        if (testResult.failedTests > 0) {
            logError(`   ❌ ${testResult.failedTests} tests failed`);
            if (testResult.failures.length > 0) {
                testResult.failures.forEach(failure => {
                    logError(`      - ${failure}`);
                });
            }
        }
        
        return testResult.failedTests === 0;
        
    } catch (error) {
        const executionTime = Date.now() - startTime;
        
        logError(`   ❌ Test failed after ${executionTime}ms`);
        logError(`   Error: ${error.message}`);
        
        // Store failure result
        const testResult = {
            testFile: testFile,
            category: 'compilation',
            totalTests: 1,
            passedTests: 0,
            failedTests: 1,
            skippedTests: 0,
            executionTime: executionTime,
            failures: [error.message],
            output: '',
            success: false
        };
        
        testResults.details.push(testResult);
        testResults.totalTests += 1;
        testResults.failedTests += 1;
        
        return false;
    }
}

/**
 * Parse test output to extract results
 */
function parseTestOutput(output, testFile) {
    const lines = output.split('\n');
    const result = {
        testFile: testFile,
        category: 'unknown',
        totalTests: 0,
        passedTests: 0,
        failedTests: 0,
        skippedTests: 0,
        executionTime: 0,
        failures: [],
        output: output,
        success: false
    };
    
    let inFailureSection = false;
    
    lines.forEach(line => {
        line = line.trim();
        
        // Extract category
        if (line.includes('Category:')) {
            result.category = line.split('Category:')[1].trim();
        }
        
        // Extract test counts
        if (line.includes('Tests Run:')) {
            result.totalTests = parseInt(line.split('Tests Run:')[1].trim()) || 0;
        }
        if (line.includes('Tests Passed:')) {
            result.passedTests = parseInt(line.split('Tests Passed:')[1].trim()) || 0;
        }
        if (line.includes('Tests Failed:')) {
            result.failedTests = parseInt(line.split('Tests Failed:')[1].trim()) || 0;
        }
        if (line.includes('Tests Skipped:')) {
            result.skippedTests = parseInt(line.split('Tests Skipped:')[1].trim()) || 0;
        }
        
        // Extract failures
        if (line.includes('Failed Tests:')) {
            inFailureSection = true;
        } else if (inFailureSection && line.startsWith('- ')) {
            result.failures.push(line.substring(2));
        } else if (inFailureSection && line === '') {
            inFailureSection = false;
        }
        
        // Determine overall success
        if (line.includes('All tests passed') || line.includes('✅ ALL TESTS PASSED')) {
            result.success = true;
        }
    });
    
    // If we couldn't parse counts from output, try to infer from success/failure indicators
    if (result.totalTests === 0) {
        const successMatches = output.match(/✅|PASSED/g) || [];
        const failureMatches = output.match(/❌|FAILED/g) || [];
        
        result.passedTests = successMatches.length;
        result.failedTests = failureMatches.length;
        result.totalTests = result.passedTests + result.failedTests;
        result.success = result.failedTests === 0;
    }
    
    return result;
}

/**
 * Run all tests
 */
function runAllTests() {
    logInfo(`\n${COLORS.bright}${COLORS.blue}🧪 Starting OMEGA Memory Management Test Suite${COLORS.reset}`);
    
    const startTime = Date.now();
    let allTestsPassed = true;
    
    // Filter tests if specific test requested
    const testsToRun = TEST_CONFIG.runSpecific 
        ? TEST_FILES.filter(file => file.includes(TEST_CONFIG.runSpecific))
        : TEST_FILES;
    
    if (TEST_CONFIG.skipIntegration) {
        logInfo('   ⚠️  Skipping integration tests');
    }
    
    if (TEST_CONFIG.skipStress) {
        logInfo('   ⚠️  Skipping stress tests');
    }
    
    if (TEST_CONFIG.skipBenchmark) {
        logInfo('   ⚠️  Skipping benchmark tests');
    }
    
    // Run each test file
    testsToRun.forEach(testFile => {
        const testPassed = runTestFile(testFile);
        if (!testPassed) {
            allTestsPassed = false;
        }
    });
    
    testResults.executionTime = Date.now() - startTime;
    
    // Generate final report
    generateFinalReport(allTestsPassed);
    
    return allTestsPassed;
}

/**
 * Generate final test report
 */
function generateFinalReport(allTestsPassed) {
    const endTime = new Date();
    
    console.log(`\n${COLORS.bright}${COLORS.blue}${'='.repeat(70)}${COLORS.reset}`);
    console.log(`${COLORS.bright}${COLORS.blue}🏁 OMEGA MEMORY MANAGEMENT TEST SUITE - FINAL REPORT${COLORS.reset}`);
    console.log(`${COLORS.bright}${COLORS.blue}${'='.repeat(70)}${COLORS.reset}`);
    
    console.log(`\n${COLORS.bright}📊 Overall Test Summary:${COLORS.reset}`);
    console.log(`   Start Time: ${testResults.startTime.toISOString()}`);
    console.log(`   End Time: ${endTime.toISOString()}`);
    console.log(`   Total Execution Time: ${testResults.executionTime}ms`);
    console.log(`   Total Test Files: ${TEST_FILES.length}`);
    console.log(`   Total Tests Run: ${testResults.totalTests}`);
    console.log(`   Tests Passed: ${COLORS.green}${testResults.passedTests}${COLORS.reset}`);
    console.log(`   Tests Failed: ${COLORS.red}${testResults.failedTests}${COLORS.reset}`);
    console.log(`   Tests Skipped: ${COLORS.yellow}${testResults.skippedTests}${COLORS.reset}`);
    console.log(`   Overall Success Rate: ${getSuccessRate()}%`);
    
    console.log(`\n${COLORS.bright}📋 Results by Category:${COLORS.reset}`);
    Object.keys(testResults.categories).forEach(category => {
        const cat = testResults.categories[category];
        const successRate = cat.total > 0 ? Math.round((cat.passed / cat.total) * 100) : 0;
        const status = successRate === 100 ? COLORS.green + '✅' : 
                      successRate >= 80 ? COLORS.yellow + '⚠️' : COLORS.red + '❌';
        
        console.log(`   ${category}: ${status}${COLORS.reset}`);
        console.log(`     Total: ${cat.total}, Passed: ${COLORS.green}${cat.passed}${COLORS.reset}, ` +
                   `Failed: ${COLORS.red}${cat.failed}${COLORS.reset}, Skipped: ${COLORS.yellow}${cat.skipped}${COLORS.reset}`);
        console.log(`     Success Rate: ${successRate}%`);
    });
    
    console.log(`\n${COLORS.bright}🏆 Final Result: ${allTestsPassed ? COLORS.green + '✅ ALL TESTS PASSED' : COLORS.red + '❌ SOME TESTS FAILED'}${COLORS.reset}`);
    
    if (!allTestsPassed) {
        console.log(`\n${COLORS.bright}${COLORS.red}🔍 Failed Test Analysis:${COLORS.reset}`);
        testResults.details.forEach(result => {
            if (result.failedTests > 0) {
                console.log(`   ${COLORS.red}❌ ${result.testFile}:${COLORS.reset}`);
                console.log(`     Failed: ${result.failedTests}, Passed: ${result.passedTests}`);
                if (result.failures.length > 0) {
                    result.failures.forEach(failure => {
                        console.log(`       - ${failure}`);
                    });
                }
            }
        });
    }
    
    console.log(`\n${COLORS.bright}📈 Performance Summary:${COLORS.reset}`);
    console.log(`   Average Test Execution Time: ${Math.round(testResults.executionTime / testResults.totalTests)}ms`);
    console.log(`   Memory Manager: ${getComponentStatus('memory_manager')}`);
    console.log(`   Memory Pool: ${getComponentStatus('memory_pool')}`);
    console.log(`   Garbage Collector: ${getComponentStatus('garbage_collector')}`);
    console.log(`   Integration: ${getComponentStatus('integration')}`);
    
    console.log(`\n${COLORS.bright}${COLORS.blue}${'='.repeat(70)}${COLORS.reset}`);
    
    // Generate detailed report if requested
    if (TEST_CONFIG.generateReport) {
        generateDetailedReport();
    }
    
    // Write results to file
    writeResultsToFile();
}

/**
 * Get success rate as percentage
 */
function getSuccessRate() {
    if (testResults.totalTests === 0) return 0;
    return Math.round((testResults.passedTests / testResults.totalTests) * 100);
}

/**
 * Get component status
 */
function getComponentStatus(component) {
    const relatedTests = testResults.details.filter(result => 
        result.testFile.includes(component) || result.category.includes(component)
    );
    
    if (relatedTests.length === 0) return 'Not Tested';
    
    const totalRelated = relatedTests.reduce((sum, test) => sum + test.totalTests, 0);
    const passedRelated = relatedTests.reduce((sum, test) => sum + test.passedTests, 0);
    
    if (passedRelated === totalRelated) {
        return COLORS.green + '✅ Operational' + COLORS.reset;
    } else if (passedRelated >= totalRelated * 0.8) {
        return COLORS.yellow + '⚠️  Partial Issues' + COLORS.reset;
    } else {
        return COLORS.red + '❌ Issues Detected' + COLORS.reset;
    }
}

/**
 * Generate detailed HTML report
 */
function generateDetailedReport() {
    const reportPath = path.join(TEST_CONFIG.outputDir, 'test_report.html');
    
    const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OMEGA Memory Management Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .header { background-color: #2c3e50; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .summary { background-color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .category { background-color: white; padding: 15px; border-radius: 8px; margin-bottom: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .success { color: #27ae60; }
        .failure { color: #e74c3c; }
        .warning { color: #f39c12; }
        .metric { display: inline-block; margin: 10px 20px 10px 0; }
        .metric-value { font-size: 24px; font-weight: bold; }
        .metric-label { font-size: 12px; color: #7f8c8d; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; }
        .progress-bar { width: 100%; height: 20px; background-color: #ecf0f1; border-radius: 10px; overflow: hidden; }
        .progress-fill { height: 100%; background-color: #27ae60; transition: width 0.3s; }
    </style>
</head>
<body>
    <div class="header">
        <h1>OMEGA Memory Management Test Report</h1>
        <p>Generated: ${new Date().toISOString()}</p>
    </div>
    
    <div class="summary">
        <h2>Overall Summary</h2>
        <div class="metric">
            <div class="metric-value ${allTestsPassed ? 'success' : 'failure'}">${getSuccessRate()}%</div>
            <div class="metric-label">Success Rate</div>
        </div>
        <div class="metric">
            <div class="metric-value">${testResults.totalTests}</div>
            <div class="metric-label">Total Tests</div>
        </div>
        <div class="metric">
            <div class="metric-value success">${testResults.passedTests}</div>
            <div class="metric-label">Passed</div>
        </div>
        <div class="metric">
            <div class="metric-value failure">${testResults.failedTests}</div>
            <div class="metric-label">Failed</div>
        </div>
        <div class="metric">
            <div class="metric-value">${Math.round(testResults.executionTime / 1000)}s</div>
            <div class="metric-label">Execution Time</div>
        </div>
    </div>
    
    <div class="summary">
        <h2>Results by Category</h2>
        ${Object.keys(testResults.categories).map(category => {
            const cat = testResults.categories[category];
            const successRate = cat.total > 0 ? Math.round((cat.passed / cat.total) * 100) : 0;
            return `
                <div class="category">
                    <h3>${category}</h3>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${successRate}%"></div>
                    </div>
                    <p>Success Rate: ${successRate}% (${cat.passed}/${cat.total})</p>
                </div>
            `;
        }).join('')}
    </div>
    
    <div class="summary">
        <h2>Detailed Results</h2>
        <table>
            <thead>
                <tr>
                    <th>Test File</th>
                    <th>Category</th>
                    <th>Total</th>
                    <th>Passed</th>
                    <th>Failed</th>
                    <th>Skipped</th>
                    <th>Time (ms)</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                ${testResults.details.map(result => `
                    <tr>
                        <td>${result.testFile}</td>
                        <td>${result.category}</td>
                        <td>${result.totalTests}</td>
                        <td class="success">${result.passedTests}</td>
                        <td class="failure">${result.failedTests}</td>
                        <td class="warning">${result.skippedTests}</td>
                        <td>${result.executionTime}</td>
                        <td class="${result.success ? 'success' : 'failure'}">${result.success ? '✅ PASSED' : '❌ FAILED'}</td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    </div>
</body>
</html>
    `;
    
    fs.writeFileSync(reportPath, htmlContent);
    logInfo(`\n📄 Detailed HTML report generated: ${reportPath}`);
}

/**
 * Write results to file
 */
function writeResultsToFile() {
    const resultsPath = path.join(TEST_CONFIG.outputDir, 'test_results.json');
    
    const resultsData = {
        timestamp: new Date().toISOString(),
        summary: {
            totalTests: testResults.totalTests,
            passedTests: testResults.passedTests,
            failedTests: testResults.failedTests,
            skippedTests: testResults.skippedTests,
            successRate: getSuccessRate(),
            executionTime: testResults.executionTime
        },
        categories: testResults.categories,
        details: testResults.details,
        configuration: TEST_CONFIG
    };
    
    fs.writeFileSync(resultsPath, JSON.stringify(resultsData, null, 2));
    logInfo(`📊 Test results saved to: ${resultsPath}`);
}

/**
 * Logging functions
 */
function logInfo(message) {
    console.log(`${COLORS.cyan}ℹ️  ${message}${COLORS.reset}`);
}

function logSuccess(message) {
    console.log(`${COLORS.green}✅ ${message}${COLORS.reset}`);
}

function logError(message) {
    console.log(`${COLORS.red}❌ ${message}${COLORS.reset}`);
}

function logWarning(message) {
    console.log(`${COLORS.yellow}⚠️  ${message}${COLORS.reset}`);
}

/**
 * Main execution
 */
function main() {
    try {
        initializeTestEnvironment();
        const allTestsPassed = runAllTests();
        
        process.exit(allTestsPassed ? 0 : 1);
    } catch (error) {
        logError(`\n💥 Fatal error during test execution: ${error.message}`);
        console.error(error.stack);
        process.exit(1);
    }
}

// Handle command line arguments
if (process.argv.includes('--help') || process.argv.includes('-h')) {
    console.log(`
OMEGA Memory Management Test Runner

Usage: node test_runner.js [options]

Options:
  --help, -h              Show this help message
  --verbose               Enable verbose output
  --report                Generate detailed HTML report
  --test=<name>           Run specific test (partial match)
  --skip-integration      Skip integration tests
  --skip-stress           Skip stress tests
  --skip-benchmark        Skip benchmark tests

Environment Variables:
  OMEGA_COMPILER          Path to OMEGA compiler (default: omega)
  VERBOSE                 Enable verbose output (true/false)
  GENERATE_REPORT         Generate detailed report (true/false)

Examples:
  node test_runner.js --verbose --report
  node test_runner.js --test=memory_pool
  node test_runner.js --skip-stress --skip-benchmark
    `);
    process.exit(0);
}

// Run main function
main();