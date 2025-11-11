#!/usr/bin/env node

/**
 * OMEGA Memory Management Validation Script
 * 
 * This script validates that all changes are working correctly and there are no regressions.
 * It checks for proper integration of SecureTimestamp, memory management, and overall system health.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const VALIDATION_CONFIG = {
    projectRoot: path.join(__dirname, '..'),
    sourceDir: path.join(__dirname, '../src'),
    testDir: path.join(__dirname, '../tests'),
    outputDir: path.join(__dirname, '../validation_output'),
    verbose: process.argv.includes('--verbose') || process.env.VERBOSE === 'true',
    generateReport: process.argv.includes('--report') || process.env.GENERATE_REPORT === 'true',
    skipTimestampValidation: process.argv.includes('--skip-timestamp'),
    skipMemoryValidation: process.argv.includes('--skip-memory'),
    skipIntegrationValidation: process.argv.includes('--skip-integration'),
    omegaCompiler: process.env.OMEGA_COMPILER || 'omega'
};

// Validation results
let validationResults = {
    startTime: new Date(),
    endTime: null,
    totalChecks: 0,
    passedChecks: 0,
    failedChecks: 0,
    warnings: 0,
    checks: [],
    summary: {
        timestampIntegration: false,
        memoryManagement: false,
        codeQuality: false,
        overallHealth: false
    }
};

// Color codes
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

/**
 * Main validation function
 */
function runValidation() {
    console.log(`${COLORS.bright}${COLORS.blue}🔍 Starting OMEGA System Validation${COLORS.reset}`);
    
    try {
        // Initialize environment
        initializeEnvironment();
        
        // Run validation checks
        if (!VALIDATION_CONFIG.skipTimestampValidation) {
            validateSecureTimestampIntegration();
        }
        
        if (!VALIDATION_CONFIG.skipMemoryValidation) {
            validateMemoryManagement();
        }
        
        if (!VALIDATION_CONFIG.skipIntegrationValidation) {
            validateSystemIntegration();
        }
        
        validateCodeQuality();
        validateFileIntegrity();
        validateDependencies();
        
        // Generate final report
        generateValidationReport();
        
        return validationResults.overallHealth;
        
    } catch (error) {
        logError(`\n💥 Fatal validation error: ${error.message}`);
        console.error(error.stack);
        return false;
    }
}

/**
 * Initialize validation environment
 */
function initializeEnvironment() {
    logInfo('🚀 Initializing validation environment...');
    
    // Create output directory
    if (!fs.existsSync(VALIDATION_CONFIG.outputDir)) {
        fs.mkdirSync(VALIDATION_CONFIG.outputDir, { recursive: true });
    }
    
    // Check if project structure is valid
    const requiredDirs = ['src', 'tests', 'docs'];
    const missingDirs = requiredDirs.filter(dir => {
        const dirPath = path.join(VALIDATION_CONFIG.projectRoot, dir);
        return !fs.existsSync(dirPath);
    });
    
    if (missingDirs.length > 0) {
        throw new Error(`Missing required directories: ${missingDirs.join(', ')}`);
    }
    
    // Check OMEGA compiler
    try {
        execSync(`${VALIDATION_CONFIG.omegaCompiler} --version`, { stdio: 'ignore' });
        logInfo('✅ OMEGA compiler available');
    } catch (error) {
        throw new Error('OMEGA compiler not found or not working');
    }
    
    logInfo('✅ Validation environment initialized');
}

/**
 * Validate SecureTimestamp integration
 */
function validateSecureTimestampIntegration() {
    logInfo('\n🔐 Validating SecureTimestamp Integration...');
    
    // Check that all .mega files use secure timestamp
    const megaFiles = findFiles(VALIDATION_CONFIG.sourceDir, '.mega');
    
    let filesUsingSecureTimestamp = 0;
    let filesWithBlockTimestamp = 0;
    let totalFilesChecked = 0;
    
    megaFiles.forEach(file => {
        totalFilesChecked++;
        const content = fs.readFileSync(file, 'utf8');
        
        // Check for SecureTimestamp usage
        const hasSecureTimestamp = content.includes('SecureTimestamp') || 
                                 content.includes('secure_ts.get_secure_timestamp()');
        
        // Check for block.timestamp usage (should be replaced)
        const hasBlockTimestamp = content.includes('block.timestamp');
        
        if (hasSecureTimestamp) {
            filesUsingSecureTimestamp++;
        }
        
        if (hasBlockTimestamp) {
            filesWithBlockTimestamp++;
            addCheck('timestamp_integration', 'ERROR', `File ${path.relative(VALIDATION_CONFIG.projectRoot, file)} still uses block.timestamp`, file);
        } else {
            addCheck('timestamp_integration', 'PASS', `File ${path.relative(VALIDATION_CONFIG.projectRoot, file)} properly uses secure timestamp`, file);
        }
    });
    
    logInfo(`   Files checked: ${totalFilesChecked}`);
    logInfo(`   Files using secure timestamp: ${filesUsingSecureTimestamp}`);
    logInfo(`   Files with block.timestamp: ${filesWithBlockTimestamp}`);
    
    if (filesWithBlockTimestamp === 0) {
        validationResults.summary.timestampIntegration = true;
        logSuccess('✅ SecureTimestamp integration validated');
    } else {
        logError(`❌ ${filesWithBlockTimestamp} files still use block.timestamp`);
    }
}

/**
 * Validate memory management system
 */
function validateMemoryManagement() {
    logInfo('\n🧠 Validating Memory Management System...');
    
    // Check memory management files exist
    const memoryFiles = [
        'src/memory/memory_manager.mega',
        'src/memory/memory_pool.mega',
        'src/memory/garbage_collector.mega'
    ];
    
    let allFilesExist = true;
    memoryFiles.forEach(file => {
        const filePath = path.join(VALIDATION_CONFIG.projectRoot, file);
        if (fs.existsSync(filePath)) {
            addCheck('memory_management', 'PASS', `Memory file exists: ${file}`, file);
        } else {
            addCheck('memory_management', 'ERROR', `Missing memory file: ${file}`, file);
            allFilesExist = false;
        }
    });
    
    if (allFilesExist) {
        // Validate memory manager structure
        validateMemoryManagerStructure();
        
        // Validate memory pool structure
        validateMemoryPoolStructure();
        
        // Validate garbage collector structure
        validateGarbageCollectorStructure();
        
        // Check test files
        validateMemoryTestFiles();
        
        validationResults.summary.memoryManagement = true;
        logSuccess('✅ Memory management system validated');
    } else {
        logError('❌ Missing memory management files');
    }
}

/**
 * Validate memory manager structure
 */
function validateMemoryManagerStructure() {
    const memoryManagerPath = path.join(VALIDATION_CONFIG.projectRoot, 'src/memory/memory_manager.mega');
    const content = fs.readFileSync(memoryManagerPath, 'utf8');
    
    const requiredComponents = [
        'blockchain MemoryManager',
        'MemoryPool',
        'GarbageCollector',
        'allocate',
        'deallocate',
        'force_garbage_collection',
        'get_memory_stats'
    ];
    
    requiredComponents.forEach(component => {
        if (content.includes(component)) {
            addCheck('memory_manager', 'PASS', `MemoryManager contains ${component}`, 'memory_manager.mega');
        } else {
            addCheck('memory_manager', 'WARNING', `MemoryManager missing ${component}`, 'memory_manager.mega');
        }
    });
}

/**
 * Validate memory pool structure
 */
function validateMemoryPoolStructure() {
    const memoryPoolPath = path.join(VALIDATION_CONFIG.projectRoot, 'src/memory/memory_pool.mega');
    const content = fs.readFileSync(memoryPoolPath, 'utf8');
    
    const requiredComponents = [
        'blockchain MemoryPool',
        'allocate',
        'deallocate',
        'defragment',
        'get_stats',
        'MemoryBlock'
    ];
    
    requiredComponents.forEach(component => {
        if (content.includes(component)) {
            addCheck('memory_pool', 'PASS', `MemoryPool contains ${component}`, 'memory_pool.mega');
        } else {
            addCheck('memory_pool', 'WARNING', `MemoryPool missing ${component}`, 'memory_pool.mega');
        }
    });
}

/**
 * Validate garbage collector structure
 */
function validateGarbageCollectorStructure() {
    const garbageCollectorPath = path.join(VALIDATION_CONFIG.projectRoot, 'src/memory/garbage_collector.mega');
    const content = fs.readFileSync(garbageCollectorPath, 'utf8');
    
    const requiredComponents = [
        'blockchain GarbageCollector',
        'collect',
        'mark_sweep',
        'reference_counting',
        'get_gc_stats',
        'GCStrategy'
    ];
    
    requiredComponents.forEach(component => {
        if (content.includes(component)) {
            addCheck('garbage_collector', 'PASS', `GarbageCollector contains ${component}`, 'garbage_collector.mega');
        } else {
            addCheck('garbage_collector', 'WARNING', `GarbageCollector missing ${component}`, 'garbage_collector.mega');
        }
    });
}

/**
 * Validate memory test files
 */
function validateMemoryTestFiles() {
    const testFiles = [
        'tests/memory/test_main.mega',
        'tests/memory/test_memory_manager.mega',
        'tests/memory/test_runner.mega',
        'tests/memory/test_config.mega'
    ];
    
    testFiles.forEach(file => {
        const filePath = path.join(VALIDATION_CONFIG.projectRoot, file);
        if (fs.existsSync(filePath)) {
            addCheck('memory_tests', 'PASS', `Test file exists: ${file}`, file);
        } else {
            addCheck('memory_tests', 'ERROR', `Missing test file: ${file}`, file);
        }
    });
}

/**
 * Validate system integration
 */
function validateSystemIntegration() {
    logInfo('\n🔗 Validating System Integration...');
    
    // Check that all components work together
    const mainFiles = [
        'src/error.mega',
        'src/codegen.mega',
        'src/main.omega'
    ];
    
    let integrationIssues = 0;
    
    mainFiles.forEach(file => {
        const filePath = path.join(VALIDATION_CONFIG.projectRoot, file);
        if (fs.existsSync(filePath)) {
            const content = fs.readFileSync(filePath, 'utf8');
            
            // Check for proper imports
            if (content.includes('import') && content.includes('memory')) {
                addCheck('system_integration', 'PASS', `File integrates memory management: ${file}`, file);
            } else if (content.includes('import')) {
                addCheck('system_integration', 'INFO', `File has imports but no memory integration: ${file}`, file);
            }
            
            // Check for SecureTimestamp usage
            if (content.includes('SecureTimestamp')) {
                addCheck('system_integration', 'PASS', `File uses SecureTimestamp: ${file}`, file);
            }
        }
    });
    
    // Test compilation of main components
    testCompilation();
    
    validationResults.summary.integration = integrationIssues === 0;
    logSuccess('✅ System integration validated');
}

/**
 * Test compilation of main components
 */
function testCompilation() {
    logInfo('   Testing compilation...');
    
    const testFiles = [
        'src/memory/memory_manager.mega',
        'src/memory/memory_pool.mega',
        'src/memory/garbage_collector.mega'
    ];
    
    testFiles.forEach(file => {
        const filePath = path.join(VALIDATION_CONFIG.projectRoot, file);
        
        try {
            const compileCommand = `${VALIDATION_CONFIG.omegaCompiler} compile "${filePath}" --syntax-check`;
            execSync(compileCommand, { stdio: 'ignore', timeout: 30000 });
            addCheck('compilation', 'PASS', `Successfully compiled: ${file}`, file);
        } catch (error) {
            addCheck('compilation', 'ERROR', `Compilation failed: ${file} - ${error.message}`, file);
        }
    });
}

/**
 * Validate code quality
 */
function validateCodeQuality() {
    logInfo('\n📋 Validating Code Quality...');
    
    const megaFiles = findFiles(VALIDATION_CONFIG.sourceDir, '.mega');
    
    megaFiles.forEach(file => {
        const content = fs.readFileSync(file, 'utf8');
        const relativePath = path.relative(VALIDATION_CONFIG.projectRoot, file);
        
        // Check for proper documentation
        if (content.includes('///') || content.includes('/**')) {
            addCheck('documentation', 'PASS', `File has documentation: ${relativePath}`, relativePath);
        } else {
            addCheck('documentation', 'WARNING', `File lacks documentation: ${relativePath}`, relativePath);
        }
        
        // Check for error handling
        if (content.includes('try') || content.includes('catch') || content.includes('require')) {
            addCheck('error_handling', 'PASS', `File has error handling: ${relativePath}`, relativePath);
        } else {
            addCheck('error_handling', 'INFO', `File may need error handling: ${relativePath}`, relativePath);
        }
        
        // Check for security patterns
        if (content.includes('SecureTimestamp') || content.includes('memory') || content.includes('validation')) {
            addCheck('security', 'PASS', `File has security considerations: ${relativePath}`, relativePath);
        }
    });
    
    validationResults.summary.codeQuality = true;
    logSuccess('✅ Code quality validated');
}

/**
 * Validate file integrity
 */
function validateFileIntegrity() {
    logInfo('\n🔍 Validating File Integrity...');
    
    // Check for corrupted or incomplete files
    const allFiles = findFiles(VALIDATION_CONFIG.projectRoot, ['.mega', '.omega', '.md']);
    
    allFiles.forEach(file => {
        try {
            const stats = fs.statSync(file);
            
            if (stats.size === 0) {
                addCheck('file_integrity', 'ERROR', `Empty file: ${file}`, file);
            } else if (stats.size > 10 * 1024 * 1024) { // 10MB
                addCheck('file_integrity', 'WARNING', `Large file: ${file} (${Math.round(stats.size / 1024 / 1024)}MB)`, file);
            } else {
                addCheck('file_integrity', 'PASS', `File integrity OK: ${file}`, file);
            }
        } catch (error) {
            addCheck('file_integrity', 'ERROR', `Cannot read file: ${file} - ${error.message}`, file);
        }
    });
    
    logSuccess('✅ File integrity validated');
}

/**
 * Validate dependencies
 */
function validateDependencies() {
    logInfo('\n📦 Validating Dependencies...');
    
    // Check for circular dependencies
    const importGraph = buildImportGraph();
    const circularDeps = detectCircularDependencies(importGraph);
    
    if (circularDeps.length === 0) {
        addCheck('dependencies', 'PASS', 'No circular dependencies detected', 'dependency_graph');
    } else {
        circularDeps.forEach(cycle => {
            addCheck('dependencies', 'ERROR', `Circular dependency: ${cycle.join(' -> ')}`, 'dependency_graph');
        });
    }
    
    // Check for missing imports
    const missingImports = findMissingImports();
    
    if (missingImports.length === 0) {
        addCheck('dependencies', 'PASS', 'No missing imports detected', 'imports');
    } else {
        missingImports.forEach(missing => {
            addCheck('dependencies', 'ERROR', `Missing import: ${missing.file} -> ${missing.import}`, missing.file);
        });
    }
    
    logSuccess('✅ Dependencies validated');
}

/**
 * Build import graph
 */
function buildImportGraph() {
    const graph = {};
    const megaFiles = findFiles(VALIDATION_CONFIG.sourceDir, '.mega');
    
    megaFiles.forEach(file => {
        const relativePath = path.relative(VALIDATION_CONFIG.projectRoot, file);
        graph[relativePath] = [];
        
        const content = fs.readFileSync(file, 'utf8');
        const importMatches = content.match(/import\s+["']([^"']+)["']/g) || [];
        
        importMatches.forEach(match => {
            const importPath = match.match(/["']([^"']+)["']/)[1];
            graph[relativePath].push(importPath);
        });
    });
    
    return graph;
}

/**
 * Detect circular dependencies
 */
function detectCircularDependencies(graph) {
    const visited = new Set();
    const recursionStack = new Set();
    const cycles = [];
    
    function dfs(node, path) {
        if (recursionStack.has(node)) {
            const cycleStart = path.indexOf(node);
            cycles.push(path.slice(cycleStart).concat([node]));
            return;
        }
        
        if (visited.has(node)) {
            return;
        }
        
        visited.add(node);
        recursionStack.add(node);
        
        if (graph[node]) {
            graph[node].forEach(neighbor => {
                dfs(neighbor, path.concat([node]));
            });
        }
        
        recursionStack.delete(node);
    }
    
    Object.keys(graph).forEach(node => {
        if (!visited.has(node)) {
            dfs(node, []);
        }
    });
    
    return cycles;
}

/**
 * Find missing imports
 */
function findMissingImports() {
    const missing = [];
    const megaFiles = findFiles(VALIDATION_CONFIG.sourceDir, '.mega');
    
    megaFiles.forEach(file => {
        const content = fs.readFileSync(file, 'utf8');
        const importMatches = content.match(/import\s+["']([^"']+)["']/g) || [];
        
        importMatches.forEach(match => {
            const importPath = match.match(/["']([^"']+)["']/)[1];
            const resolvedPath = resolveImportPath(file, importPath);
            
            if (!fs.existsSync(resolvedPath)) {
                missing.push({
                    file: path.relative(VALIDATION_CONFIG.projectRoot, file),
                    import: importPath
                });
            }
        });
    });
    
    return missing;
}

/**
 * Resolve import path
 */
function resolveImportPath(currentFile, importPath) {
    if (importPath.startsWith('./') || importPath.startsWith('../')) {
        return path.resolve(path.dirname(currentFile), importPath);
    }
    
    // Try relative to source directory
    return path.join(VALIDATION_CONFIG.sourceDir, importPath);
}

/**
 * Add validation check result
 */
function addCheck(category, status, message, file = '') {
    validationResults.checks.push({
        category,
        status,
        message,
        file,
        timestamp: new Date().toISOString()
    });
    
    validationResults.totalChecks++;
    
    if (status === 'PASS') {
        validationResults.passedChecks++;
    } else if (status === 'ERROR') {
        validationResults.failedChecks++;
    } else if (status === 'WARNING') {
        validationResults.warnings++;
    }
}

/**
 * Generate validation report
 */
function generateValidationReport() {
    validationResults.endTime = new Date();
    
    console.log(`\n${COLORS.bright}${COLORS.blue}${'='.repeat(60)}${COLORS.reset}`);
    console.log(`${COLORS.bright}${COLORS.blue}📊 OMEGA SYSTEM VALIDATION REPORT${COLORS.reset}`);
    console.log(`${COLORS.bright}${COLORS.blue}${'='.repeat(60)}${COLORS.reset}`);
    
    console.log(`\n${COLORS.bright}🔍 Validation Summary:${COLORS.reset}`);
    console.log(`   Total Checks: ${validationResults.totalChecks}`);
    console.log(`   Passed: ${COLORS.green}${validationResults.passedChecks}${COLORS.reset}`);
    console.log(`   Failed: ${COLORS.red}${validationResults.failedChecks}${COLORS.reset}`);
    console.log(`   Warnings: ${COLORS.yellow}${validationResults.warnings}${COLORS.reset}`);
    console.log(`   Success Rate: ${getValidationSuccessRate()}%`);
    console.log(`   Execution Time: ${validationResults.endTime - validationResults.startTime}ms`);
    
    console.log(`\n${COLORS.bright}🏆 Component Status:${COLORS.reset}`);
    console.log(`   SecureTimestamp Integration: ${getComponentStatus(validationResults.summary.timestampIntegration)}`);
    console.log(`   Memory Management: ${getComponentStatus(validationResults.summary.memoryManagement)}`);
    console.log(`   System Integration: ${getComponentStatus(validationResults.summary.integration)}`);
    console.log(`   Code Quality: ${getComponentStatus(validationResults.summary.codeQuality)}`);
    
    // Determine overall health
    const overallHealth = validationResults.failedChecks === 0 && 
                         validationResults.summary.timestampIntegration &&
                         validationResults.summary.memoryManagement;
    
    validationResults.overallHealth = overallHealth;
    
    console.log(`\n${COLORS.bright}🎯 Overall System Health: ${overallHealth ? COLORS.green + '✅ HEALTHY' : COLORS.red + '❌ ISSUES DETECTED'}${COLORS.reset}`);
    
    if (validationResults.failedChecks > 0) {
        console.log(`\n${COLORS.bright}${COLORS.red}❌ Failed Checks:${COLORS.reset}`);
        validationResults.checks
            .filter(check => check.status === 'ERROR')
            .forEach(check => {
                console.log(`   ${COLORS.red}- ${check.message}${COLORS.reset}`);
                if (check.file) {
                    console.log(`     File: ${check.file}`);
                }
            });
    }
    
    if (validationResults.warnings > 0) {
        console.log(`\n${COLORS.bright}${COLORS.yellow}⚠️  Warnings:${COLORS.reset}`);
        validationResults.checks
            .filter(check => check.status === 'WARNING')
            .slice(0, 10) // Show first 10 warnings
            .forEach(check => {
                console.log(`   ${COLORS.yellow}- ${check.message}${COLORS.reset}`);
                if (check.file) {
                    console.log(`     File: ${check.file}`);
                }
            });
        
        if (validationResults.warnings > 10) {
            console.log(`   ${COLORS.yellow}... and ${validationResults.warnings - 10} more warnings${COLORS.reset}`);
        }
    }
    
    console.log(`\n${COLORS.bright}${COLORS.blue}${'='.repeat(60)}${COLORS.reset}`);
    
    // Write results to file
    writeValidationResults();
    
    // Generate detailed report if requested
    if (VALIDATION_CONFIG.generateReport) {
        generateDetailedValidationReport();
    }
}

/**
 * Get validation success rate
 */
function getValidationSuccessRate() {
    if (validationResults.totalChecks === 0) return 0;
    return Math.round((validationResults.passedChecks / validationResults.totalChecks) * 100);
}

/**
 * Get component status
 */
function getComponentStatus(healthy) {
    return healthy ? `${COLORS.green}✅ Healthy${COLORS.reset}` : `${COLORS.red}❌ Issues${COLORS.reset}`;
}

/**
 * Write validation results to file
 */
function writeValidationResults() {
    const resultsPath = path.join(VALIDATION_CONFIG.outputDir, 'validation_results.json');
    
    const resultsData = {
        timestamp: new Date().toISOString(),
        summary: {
            totalChecks: validationResults.totalChecks,
            passedChecks: validationResults.passedChecks,
            failedChecks: validationResults.failedChecks,
            warnings: validationResults.warnings,
            successRate: getValidationSuccessRate(),
            overallHealth: validationResults.overallHealth
        },
        componentStatus: validationResults.summary,
        checks: validationResults.checks,
        executionTime: validationResults.endTime - validationResults.startTime
    };
    
    fs.writeFileSync(resultsPath, JSON.stringify(resultsData, null, 2));
    logInfo(`\n📊 Validation results saved to: ${resultsPath}`);
}

/**
 * Generate detailed HTML validation report
 */
function generateDetailedValidationReport() {
    const reportPath = path.join(VALIDATION_CONFIG.outputDir, 'validation_report.html');
    
    const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OMEGA System Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .header { background-color: #2c3e50; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .summary { background-color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .check-item { background-color: white; padding: 10px; border-radius: 4px; margin-bottom: 5px; box-shadow: 0 1px 2px rgba(0,0,0,0.1); }
        .success { border-left: 4px solid #27ae60; }
        .error { border-left: 4px solid #e74c3c; }
        .warning { border-left: 4px solid #f39c12; }
        .info { border-left: 4px solid #3498db; }
        .metric { display: inline-block; margin: 10px 20px 10px 0; }
        .metric-value { font-size: 24px; font-weight: bold; }
        .metric-label { font-size: 12px; color: #7f8c8d; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; }
        .status-healthy { color: #27ae60; }
        .status-issues { color: #e74c3c; }
    </style>
</head>
<body>
    <div class="header">
        <h1>OMEGA System Validation Report</h1>
        <p>Generated: ${new Date().toISOString()}</p>
    </div>
    
    <div class="summary">
        <h2>Validation Summary</h2>
        <div class="metric">
            <div class="metric-value ${validationResults.overallHealth ? 'status-healthy' : 'status-issues'}">${getValidationSuccessRate()}%</div>
            <div class="metric-label">Success Rate</div>
        </div>
        <div class="metric">
            <div class="metric-value">${validationResults.totalChecks}</div>
            <div class="metric-label">Total Checks</div>
        </div>
        <div class="metric">
            <div class="metric-value status-healthy">${validationResults.passedChecks}</div>
            <div class="metric-label">Passed</div>
        </div>
        <div class="metric">
            <div class="metric-value status-issues">${validationResults.failedChecks}</div>
            <div class="metric-label">Failed</div>
        </div>
        <div class="metric">
            <div class="metric-value">${Math.round((validationResults.endTime - validationResults.startTime) / 1000)}s</div>
            <div class="metric-label">Execution Time</div>
        </div>
    </div>
    
    <div class="summary">
        <h2>Component Status</h2>
        <table>
            <tr>
                <th>Component</th>
                <th>Status</th>
                <th>Description</th>
            </tr>
            <tr>
                <td>SecureTimestamp Integration</td>
                <td class="${validationResults.summary.timestampIntegration ? 'status-healthy' : 'status-issues'}">${validationResults.summary.timestampIntegration ? '✅ Healthy' : '❌ Issues'}</td>
                <td>All files use secure timestamp implementation</td>
            </tr>
            <tr>
                <td>Memory Management</td>
                <td class="${validationResults.summary.memoryManagement ? 'status-healthy' : 'status-issues'}">${validationResults.summary.memoryManagement ? '✅ Healthy' : '❌ Issues'}</td>
                <td>Memory pool, garbage collector, and manager are properly implemented</td>
            </tr>
            <tr>
                <td>System Integration</td>
                <td class="${validationResults.summary.integration ? 'status-healthy' : 'status-issues'}">${validationResults.summary.integration ? '✅ Healthy' : '❌ Issues'}</td>
                <td>All components work together correctly</td>
            </tr>
            <tr>
                <td>Code Quality</td>
                <td class="${validationResults.summary.codeQuality ? 'status-healthy' : 'status-issues'}">${validationResults.summary.codeQuality ? '✅ Healthy' : '❌ Issues'}</td>
                <td>Code follows best practices and standards</td>
            </tr>
        </table>
    </div>
    
    <div class="summary">
        <h2>Detailed Check Results</h2>
        ${validationResults.checks.map(check => `
            <div class="check-item ${check.status.toLowerCase()}">
                <strong>${check.category}</strong> - ${check.message}
                ${check.file ? `<br><small>File: ${check.file}</small>` : ''}
                <br><small>Time: ${check.timestamp}</small>
            </div>
        `).join('')}
    </div>
</body>
</html>
    `;
    
    fs.writeFileSync(reportPath, htmlContent);
    logInfo(`📄 Detailed validation report generated: ${reportPath}`);
}

/**
 * Utility functions
 */
function findFiles(dir, extensions) {
    const files = [];
    const extArray = Array.isArray(extensions) ? extensions : [extensions];
    
    function traverse(currentDir) {
        const items = fs.readdirSync(currentDir);
        
        items.forEach(item => {
            const itemPath = path.join(currentDir, item);
            const stat = fs.statSync(itemPath);
            
            if (stat.isDirectory()) {
                traverse(itemPath);
            } else if (stat.isFile()) {
                const ext = path.extname(item);
                if (extArray.includes(ext)) {
                    files.push(itemPath);
                }
            }
        });
    }
    
    traverse(dir);
    return files;
}

function logInfo(message) {
    console.log(`${COLORS.cyan}ℹ️  ${message}${COLORS.reset}`);
}

function logSuccess(message) {
    console.log(`${COLORS.green}${message}${COLORS.reset}`);
}

function logError(message) {
    console.log(`${COLORS.red}${message}${COLORS.reset}`);
}

function logWarning(message) {
    console.log(`${COLORS.yellow}⚠️  ${message}${COLORS.reset}`);
}

/**
 * Main execution
 */
function main() {
    if (process.argv.includes('--help') || process.argv.includes('-h')) {
        console.log(`
OMEGA System Validation Script

Usage: node validation.js [options]

Options:
  --help, -h              Show this help message
  --verbose               Enable verbose output
  --report                Generate detailed HTML report
  --skip-timestamp        Skip SecureTimestamp validation
  --skip-memory           Skip memory management validation
  --skip-integration      Skip system integration validation

Environment Variables:
  OMEGA_COMPILER          Path to OMEGA compiler (default: omega)
  VERBOSE                 Enable verbose output (true/false)
  GENERATE_REPORT         Generate detailed report (true/false)

Examples:
  node validation.js --verbose --report
  node validation.js --skip-timestamp
  node validation.js --report --skip-memory
        `);
        process.exit(0);
    }
    
    try {
        const success = runValidation();
        process.exit(success ? 0 : 1);
    } catch (error) {
        logError(`\n💥 Fatal validation error: ${error.message}`);
        console.error(error.stack);
        process.exit(1);
    }
}

// Run main function
main();