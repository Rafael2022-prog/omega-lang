# OMEGA Basic Testing Script
Write-Host "🧪 OMEGA Basic Testing Suite" -ForegroundColor Blue
Write-Host "============================" -ForegroundColor Blue
Write-Host ""

$TotalTests = 0
$PassedTests = 0
$FailedTests = 0

function Test-Item {
    param([string]$Name, [bool]$Condition, [string]$Message)
    
    $script:TotalTests++
    
    if ($Condition) {
        Write-Host "✅ $Name - $Message" -ForegroundColor Green
        $script:PassedTests++
    } else {
        Write-Host "❌ $Name - $Message" -ForegroundColor Red
        $script:FailedTests++
    }
}

# 1. Environment Check
Write-Host "🌍 Environment Check" -ForegroundColor Cyan
Write-Host "===================="

# PowerShell version
$psOk = $PSVersionTable.PSVersion.Major -ge 5
Test-Item "PowerShell" $psOk "Version check"

# Rust availability
try {
    rustc --version | Out-Null
    $rustOk = $LASTEXITCODE -eq 0
} catch {
    $rustOk = $false
}
Test-Item "Rust" $rustOk "Compiler availability"

# Cargo availability
try {
    cargo --version | Out-Null
    $cargoOk = $LASTEXITCODE -eq 0
} catch {
    $cargoOk = $false
}
Test-Item "Cargo" $cargoOk "Build tool availability"

# 2. File Structure Check
Write-Host ""
Write-Host "📁 File Structure Check" -ForegroundColor Cyan
Write-Host "======================="

$cargoTomlExists = Test-Path "Cargo.toml"
Test-Item "Cargo.toml" $cargoTomlExists "Configuration file"

$mainMegaExists = Test-Path "src\main.mega"
Test-Item "main.mega" $mainMegaExists "Main source file"

$lexerExists = Test-Path "src\lexer\lexer.mega"
Test-Item "lexer.mega" $lexerExists "Lexer module"

$parserExists = Test-Path "src\parser\parser.mega"
Test-Item "parser.mega" $parserExists "Parser module"

$semanticExists = Test-Path "src\semantic\analyzer.mega"
Test-Item "analyzer.mega" $semanticExists "Semantic analyzer"

$irExists = Test-Path "src\ir\optimizer.mega"
Test-Item "optimizer.mega" $irExists "IR optimizer"

$codegenExists = Test-Path "src\codegen\codegen.mega"
Test-Item "codegen.mega" $codegenExists "Code generator"

# 3. Documentation Check
Write-Host ""
Write-Host "📚 Documentation Check" -ForegroundColor Cyan
Write-Host "======================"

$readmeExists = Test-Path "README.md"
Test-Item "README.md" $readmeExists "Project documentation"

$langSpecExists = Test-Path "LANGUAGE_SPECIFICATION.md"
Test-Item "Language Spec" $langSpecExists "Language specification"

$compilerArchExists = Test-Path "COMPILER_ARCHITECTURE.md"
Test-Item "Compiler Arch" $compilerArchExists "Architecture documentation"

# 4. Build Test (Optional)
Write-Host ""
Write-Host "🔨 Build Test" -ForegroundColor Cyan
Write-Host "=============="

if ($rustOk -and $cargoOk) {
    Write-Host "Attempting clean build..."
    
    try {
        cargo clean | Out-Null
        cargo build --release | Out-Null
        $buildOk = $LASTEXITCODE -eq 0
    } catch {
        $buildOk = $false
    }
    
    Test-Item "Clean Build" $buildOk "Release build"
    
    if ($buildOk) {
        $binaryExists = Test-Path "target\release\omega.exe"
        Test-Item "Binary Output" $binaryExists "Executable created"
        
        if ($binaryExists) {
            try {
                & "target\release\omega.exe" --version | Out-Null
                $execOk = $LASTEXITCODE -eq 0
            } catch {
                $execOk = $false
            }
            Test-Item "Binary Execution" $execOk "Basic functionality"
        }
    }
} else {
    Write-Host "⏭️  Build test skipped (missing tools)" -ForegroundColor Yellow
}

# 5. Unit Tests
Write-Host ""
Write-Host "🧪 Unit Tests" -ForegroundColor Cyan
Write-Host "=============="

if ($rustOk -and $cargoOk) {
    try {
        cargo test | Out-Null
        $testOk = $LASTEXITCODE -eq 0
    } catch {
        $testOk = $false
    }
    
    Test-Item "Unit Tests" $testOk "Test suite execution"
} else {
    Write-Host "⏭️  Unit tests skipped (missing tools)" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "📊 Test Summary" -ForegroundColor Blue
Write-Host "===============" -ForegroundColor Blue

Write-Host "Total Tests: $TotalTests"
Write-Host "Passed: $PassedTests" -ForegroundColor Green
Write-Host "Failed: $FailedTests" -ForegroundColor Red

if ($TotalTests -gt 0) {
    $successRate = [math]::Round(($PassedTests * 100.0) / $TotalTests, 1)
    Write-Host "Success Rate: $successRate%"
}

Write-Host ""

if ($FailedTests -eq 0) {
    Write-Host "🎉 ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "OMEGA is ready for deployment." -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ SOME TESTS FAILED" -ForegroundColor Red
    Write-Host "Please resolve issues before deployment." -ForegroundColor Red
    exit 1
}