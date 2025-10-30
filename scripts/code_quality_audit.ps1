# OMEGA Code Quality Audit Script
# Comprehensive code quality analysis for OMEGA compiler

param(
    [string]$ProjectRoot = "R:\OMEGA",
    [string]$OutputFile = "code_quality_report.json",
    [switch]$Verbose = $false,
    [string]$AuditLevel = "comprehensive"
)

# Initialize audit results
$AuditResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    project_root = $ProjectRoot
    audit_level = $AuditLevel
    overall_score = 0
    grade = "F"
    deployment_approved = $false
    metrics = @{}
    issues = @()
    coverage = @{}
    improvement_plan = @{}
    quality_gates = @{}
}

Write-Host "🔍 Starting OMEGA Code Quality Audit..." -ForegroundColor Cyan
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Gray
Write-Host "Audit Level: $AuditLevel" -ForegroundColor Gray
Write-Host ""

# Function to log messages
function Write-AuditLog {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
    
    if ($Verbose) {
        Add-Content -Path "audit.log" -Value "[$timestamp] [$Level] $Message"
    }
}

# Function to analyze file metrics
function Get-FileMetrics {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return $null
    }
    
    $content = Get-Content $FilePath -Raw
    $lines = (Get-Content $FilePath).Count
    
    # Basic metrics calculation
    $metrics = @{
        file_path = $FilePath
        lines_of_code = $lines
        blank_lines = ($content -split "`n" | Where-Object { $_.Trim() -eq "" }).Count
        comment_lines = ($content -split "`n" | Where-Object { $_.Trim().StartsWith("//") }).Count
        cyclomatic_complexity = Get-CyclomaticComplexity $content
        cognitive_complexity = Get-CognitiveComplexity $content
        maintainability_index = 0
        technical_debt_ratio = 0
        code_duplication = 0
        last_modified = (Get-Item $FilePath).LastWriteTime
    }
    
    # Calculate maintainability index (simplified)
    $effective_lines = $metrics.lines_of_code - $metrics.blank_lines - $metrics.comment_lines
    if ($effective_lines -gt 0) {
        $metrics.maintainability_index = [Math]::Max(0, 171 - 5.2 * [Math]::Log($effective_lines) - 0.23 * $metrics.cyclomatic_complexity)
    }
    
    return $metrics
}

# Function to calculate cyclomatic complexity (simplified)
function Get-CyclomaticComplexity {
    param([string]$Content)
    
    $complexity = 1 # Base complexity
    
    # Count decision points
    $patterns = @(
        'if\s*\(',
        'else\s+if\s*\(',
        'while\s*\(',
        'for\s*\(',
        'switch\s*\(',
        'case\s+',
        'catch\s*\(',
        '\?\s*:',
        '&&',
        '\|\|'
    )
    
    foreach ($pattern in $patterns) {
        $matches = [regex]::Matches($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $complexity += $matches.Count
    }
    
    return $complexity
}

# Function to calculate cognitive complexity (simplified)
function Get-CognitiveComplexity {
    param([string]$Content)
    
    $complexity = 0
    $nesting_level = 0
    
    # This is a simplified version - real implementation would need proper parsing
    $lines = $Content -split "`n"
    
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        
        # Increase nesting for blocks
        if ($trimmed -match '^\s*\{' -or $trimmed -match '\{\s*$') {
            $nesting_level++
        }
        
        # Decrease nesting
        if ($trimmed -match '^\s*\}') {
            $nesting_level = [Math]::Max(0, $nesting_level - 1)
        }
        
        # Add complexity for control structures
        if ($trimmed -match '^(if|while|for|switch)\s*\(') {
            $complexity += 1 + $nesting_level
        }
        
        # Add complexity for logical operators
        $logical_ops = [regex]::Matches($trimmed, '&&|\|\|').Count
        $complexity += $logical_ops
    }
    
    return $complexity
}

# Function to check code issues
function Find-CodeIssues {
    param([string]$FilePath, [hashtable]$Metrics)
    
    $issues = @()
    $content = Get-Content $FilePath -Raw
    
    # Check complexity issues
    if ($Metrics.cyclomatic_complexity -gt 15) {
        $issues += @{
            type = "complexity"
            severity = "high"
            file = $FilePath
            line = 0
            description = "Cyclomatic complexity ($($Metrics.cyclomatic_complexity)) exceeds threshold (15)"
            recommendation = "Consider breaking down complex functions into smaller, more manageable pieces"
            estimated_fix_time = 8
        }
    } elseif ($Metrics.cyclomatic_complexity -gt 10) {
        $issues += @{
            type = "complexity"
            severity = "medium"
            file = $FilePath
            line = 0
            description = "Cyclomatic complexity ($($Metrics.cyclomatic_complexity)) is moderately high"
            recommendation = "Consider refactoring to reduce complexity"
            estimated_fix_time = 4
        }
    }
    
    # Check maintainability
    if ($Metrics.maintainability_index -lt 50) {
        $issues += @{
            type = "maintainability"
            severity = "high"
            file = $FilePath
            line = 0
            description = "Low maintainability index ($([Math]::Round($Metrics.maintainability_index, 2)))"
            recommendation = "Improve code structure, reduce complexity, and add documentation"
            estimated_fix_time = 12
        }
    }
    
    # Check for potential security issues (basic patterns)
    $security_patterns = @{
        'unsafe\s*\{' = "Unsafe code block detected"
        '\.unwrap\(\)' = "Potential panic with unwrap()"
        'panic!\(' = "Explicit panic call"
        'todo!\(' = "TODO macro in production code"
        'unimplemented!\(' = "Unimplemented macro in production code"
    }
    
    foreach ($pattern in $security_patterns.Keys) {
        $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        foreach ($match in $matches) {
            $line_number = ($content.Substring(0, $match.Index) -split "`n").Count
            $issues += @{
                type = "security"
                severity = "medium"
                file = $FilePath
                line = $line_number
                description = $security_patterns[$pattern]
                recommendation = "Review and handle potential error cases safely"
                estimated_fix_time = 2
            }
        }
    }
    
    # Check for performance issues
    $performance_patterns = @{
        'String\s*\+\s*String' = "String concatenation in loop (potential performance issue)"
        '\.clone\(\)' = "Frequent cloning may impact performance"
        'Vec::new\(\)' = "Consider pre-allocating Vec with capacity"
    }
    
    foreach ($pattern in $performance_patterns.Keys) {
        $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($matches.Count -gt 5) {  # Only flag if frequent
            $issues += @{
                type = "performance"
                severity = "low"
                file = $FilePath
                line = 0
                description = "$($performance_patterns[$pattern]) (found $($matches.Count) instances)"
                recommendation = "Optimize for better performance"
                estimated_fix_time = 3
            }
        }
    }
    
    # Check documentation
    $function_count = ([regex]::Matches($content, 'fn\s+\w+\s*\(', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
    $doc_comment_count = ([regex]::Matches($content, '///', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
    
    if ($function_count -gt 0) {
        $doc_coverage = ($doc_comment_count / $function_count) * 100
        if ($doc_coverage -lt 75) {
            $issues += @{
                type = "documentation"
                severity = "medium"
                file = $FilePath
                line = 0
                description = "Low documentation coverage ($([Math]::Round($doc_coverage, 1))%)"
                recommendation = "Add comprehensive documentation for public functions"
                estimated_fix_time = 4
            }
        }
    }
    
    return $issues
}

# Function to analyze test coverage (simplified)
function Get-TestCoverage {
    Write-AuditLog "Analyzing test coverage..." "INFO"
    
    $test_files = Get-ChildItem -Path "$ProjectRoot\tests" -Filter "*.rs" -Recurse -ErrorAction SilentlyContinue
    $src_files = Get-ChildItem -Path "$ProjectRoot\src" -Filter "*.rs" -Recurse -ErrorAction SilentlyContinue
    
    $coverage = @{
        test_files_count = $test_files.Count
        source_files_count = $src_files.Count
        estimated_line_coverage = 0
        estimated_function_coverage = 0
        critical_uncovered_areas = @()
    }
    
    if ($src_files.Count -gt 0) {
        # Simplified coverage estimation based on test-to-source ratio
        $test_ratio = $test_files.Count / $src_files.Count
        $coverage.estimated_line_coverage = [Math]::Min(95, $test_ratio * 80)
        $coverage.estimated_function_coverage = [Math]::Min(98, $test_ratio * 85)
    }
    
    # Identify potentially uncovered critical areas
    $critical_files = @("main.rs", "lib.rs", "compiler.rs", "codegen.rs")
    foreach ($file in $critical_files) {
        $src_path = Get-ChildItem -Path "$ProjectRoot\src" -Filter $file -Recurse -ErrorAction SilentlyContinue
        if ($src_path) {
            $test_path = Get-ChildItem -Path "$ProjectRoot\tests" -Filter "*$($file.Replace('.rs', ''))*" -Recurse -ErrorAction SilentlyContinue
            if (-not $test_path) {
                $coverage.critical_uncovered_areas += $file
            }
        }
    }
    
    return $coverage
}

# Function to calculate overall quality score
function Calculate-QualityScore {
    param([hashtable]$AllMetrics, [array]$AllIssues, [hashtable]$Coverage)
    
    Write-AuditLog "Calculating overall quality score..." "INFO"
    
    # Initialize component scores
    $maintainability_score = 100
    $reliability_score = 100
    $security_score = 100
    $performance_score = 100
    $testability_score = 100
    
    # Calculate maintainability score
    if ($AllMetrics.Count -gt 0) {
        $avg_complexity = ($AllMetrics.Values | Measure-Object -Property cyclomatic_complexity -Average).Average
        $avg_maintainability = ($AllMetrics.Values | Measure-Object -Property maintainability_index -Average).Average
        
        $maintainability_score = [Math]::Max(0, $avg_maintainability)
        if ($avg_complexity -gt 15) {
            $maintainability_score -= 20
        } elseif ($avg_complexity -gt 10) {
            $maintainability_score -= 10
        }
    }
    
    # Calculate reliability score based on issues
    $high_issues = ($AllIssues | Where-Object { $_.severity -eq "high" }).Count
    $medium_issues = ($AllIssues | Where-Object { $_.severity -eq "medium" }).Count
    
    $reliability_score -= ($high_issues * 15) + ($medium_issues * 5)
    $reliability_score = [Math]::Max(0, $reliability_score)
    
    # Calculate security score
    $security_issues = ($AllIssues | Where-Object { $_.type -eq "security" }).Count
    $security_score -= $security_issues * 20
    $security_score = [Math]::Max(0, $security_score)
    
    # Calculate performance score
    $performance_issues = ($AllIssues | Where-Object { $_.type -eq "performance" }).Count
    $performance_score -= $performance_issues * 10
    $performance_score = [Math]::Max(0, $performance_score)
    
    # Calculate testability score
    if ($Coverage.estimated_line_coverage) {
        $testability_score = $Coverage.estimated_line_coverage
    }
    
    # Calculate weighted overall score
    $overall_score = [Math]::Round((
        $maintainability_score * 0.25 +
        $reliability_score * 0.20 +
        $security_score * 0.25 +
        $performance_score * 0.15 +
        $testability_score * 0.15
    ), 1)
    
    # Determine grade
    $grade = if ($overall_score -ge 95) { "A+" }
             elseif ($overall_score -ge 90) { "A" }
             elseif ($overall_score -ge 85) { "B+" }
             elseif ($overall_score -ge 80) { "B" }
             elseif ($overall_score -ge 75) { "C+" }
             elseif ($overall_score -ge 70) { "C" }
             elseif ($overall_score -ge 60) { "D" }
             else { "F" }
    
    return @{
        overall_score = $overall_score
        maintainability_score = $maintainability_score
        reliability_score = $reliability_score
        security_score = $security_score
        performance_score = $performance_score
        testability_score = $testability_score
        grade = $grade
        passes_quality_gate = $overall_score -ge 75
    }
}

# Function to generate improvement plan
function Generate-ImprovementPlan {
    param([array]$AllIssues)
    
    Write-AuditLog "Generating improvement plan..." "INFO"
    
    $high_priority = $AllIssues | Where-Object { $_.severity -eq "high" }
    $medium_priority = $AllIssues | Where-Object { $_.severity -eq "medium" }
    $low_priority = $AllIssues | Where-Object { $_.severity -eq "low" }
    
    $total_effort = ($AllIssues | Measure-Object -Property estimated_fix_time -Sum).Sum
    
    $plan = @{
        high_priority_actions = $high_priority
        medium_priority_actions = $medium_priority
        low_priority_actions = $low_priority
        estimated_total_effort = $total_effort
        quick_wins = @(
            "Fix code formatting inconsistencies",
            "Remove unused imports and variables",
            "Add missing documentation comments",
            "Update outdated comments"
        )
        long_term_goals = @(
            "Achieve 90%+ test coverage",
            "Reduce average cyclomatic complexity to <10",
            "Implement comprehensive error handling",
            "Establish automated quality gates in CI/CD"
        )
    }
    
    return $plan
}

# Function to evaluate quality gates
function Test-QualityGates {
    param([hashtable]$Scores, [array]$AllIssues, [hashtable]$Coverage)
    
    Write-AuditLog "Evaluating quality gates..." "INFO"
    
    $gates = @{
        test_coverage = @{
            name = "Test Coverage"
            condition = "line_coverage >= 80"
            threshold = 80
            actual = $Coverage.estimated_line_coverage
            passed = $Coverage.estimated_line_coverage -ge 80
            blocking = $true
        }
        security_issues = @{
            name = "Security Issues"
            condition = "high_security_issues == 0"
            threshold = 0
            actual = ($AllIssues | Where-Object { $_.type -eq "security" -and $_.severity -eq "high" }).Count
            passed = ($AllIssues | Where-Object { $_.type -eq "security" -and $_.severity -eq "high" }).Count -eq 0
            blocking = $true
        }
        overall_score = @{
            name = "Overall Quality Score"
            condition = "overall_score >= 75"
            threshold = 75
            actual = $Scores.overall_score
            passed = $Scores.overall_score -ge 75
            blocking = $true
        }
        complexity = @{
            name = "Code Complexity"
            condition = "high_complexity_issues <= 2"
            threshold = 2
            actual = ($AllIssues | Where-Object { $_.type -eq "complexity" -and $_.severity -eq "high" }).Count
            passed = ($AllIssues | Where-Object { $_.type -eq "complexity" -and $_.severity -eq "high" }).Count -le 2
            blocking = $false
        }
    }
    
    $all_blocking_gates_pass = $true
    foreach ($gate in $gates.Values) {
        if ($gate.blocking -and -not $gate.passed) {
            $all_blocking_gates_pass = $false
        }
    }
    
    return @{
        gates = $gates
        deployment_approved = $all_blocking_gates_pass
    }
}

# Main audit execution
try {
    Write-AuditLog "Starting comprehensive code quality audit" "INFO"
    
    # Phase 1: Analyze source files
    Write-AuditLog "Phase 1: Analyzing source files..." "INFO"
    $source_files = Get-ChildItem -Path "$ProjectRoot\src" -Filter "*.rs" -Recurse -ErrorAction SilentlyContinue
    
    $all_metrics = @{}
    $all_issues = @()
    
    foreach ($file in $source_files) {
        Write-AuditLog "Analyzing: $($file.Name)" "INFO"
        
        $metrics = Get-FileMetrics $file.FullName
        if ($metrics) {
            $all_metrics[$file.FullName] = $metrics
            $AuditResults.metrics[$file.FullName] = $metrics
            
            # Find issues in this file
            $file_issues = Find-CodeIssues $file.FullName $metrics
            $all_issues += $file_issues
        }
    }
    
    Write-AuditLog "Analyzed $($source_files.Count) source files" "SUCCESS"
    
    # Phase 2: Analyze test coverage
    Write-AuditLog "Phase 2: Analyzing test coverage..." "INFO"
    $coverage = Get-TestCoverage
    $AuditResults.coverage = $coverage
    
    # Phase 3: Calculate quality scores
    Write-AuditLog "Phase 3: Calculating quality scores..." "INFO"
    $scores = Calculate-QualityScore $all_metrics $all_issues $coverage
    $AuditResults.overall_score = $scores.overall_score
    $AuditResults.grade = $scores.grade
    
    # Phase 4: Generate improvement plan
    Write-AuditLog "Phase 4: Generating improvement plan..." "INFO"
    $improvement_plan = Generate-ImprovementPlan $all_issues
    $AuditResults.improvement_plan = $improvement_plan
    
    # Phase 5: Evaluate quality gates
    Write-AuditLog "Phase 5: Evaluating quality gates..." "INFO"
    $quality_gates = Test-QualityGates $scores $all_issues $coverage
    $AuditResults.quality_gates = $quality_gates.gates
    $AuditResults.deployment_approved = $quality_gates.deployment_approved
    
    # Store all issues
    $AuditResults.issues = $all_issues
    
    # Generate summary
    Write-Host ""
    Write-Host "📊 AUDIT SUMMARY" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    Write-Host "Overall Score: $($scores.overall_score)/100 ($($scores.grade))" -ForegroundColor $(if ($scores.grade -match "A|B") { "Green" } elseif ($scores.grade -match "C") { "Yellow" } else { "Red" })
    Write-Host "Files Analyzed: $($source_files.Count)" -ForegroundColor White
    Write-Host "Issues Found: $($all_issues.Count)" -ForegroundColor $(if ($all_issues.Count -eq 0) { "Green" } elseif ($all_issues.Count -le 5) { "Yellow" } else { "Red" })
    Write-Host "Test Coverage: $([Math]::Round($coverage.estimated_line_coverage, 1))%" -ForegroundColor $(if ($coverage.estimated_line_coverage -ge 80) { "Green" } elseif ($coverage.estimated_line_coverage -ge 60) { "Yellow" } else { "Red" })
    Write-Host "Deployment Approved: $(if ($quality_gates.deployment_approved) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($quality_gates.deployment_approved) { "Green" } else { "Red" })
    
    if ($all_issues.Count -gt 0) {
        Write-Host ""
        Write-Host "🔍 TOP ISSUES TO ADDRESS:" -ForegroundColor Yellow
        $top_issues = $all_issues | Sort-Object { 
            switch ($_.severity) {
                "high" { 1 }
                "medium" { 2 }
                "low" { 3 }
            }
        } | Select-Object -First 5
        
        foreach ($issue in $top_issues) {
            $severity_color = switch ($issue.severity) {
                "high" { "Red" }
                "medium" { "Yellow" }
                "low" { "Gray" }
            }
            Write-Host "  [$($issue.severity.ToUpper())] $($issue.description)" -ForegroundColor $severity_color
        }
    }
    
    Write-Host ""
    Write-Host "💡 QUICK WINS:" -ForegroundColor Green
    foreach ($win in $improvement_plan.quick_wins) {
        Write-Host "  • $win" -ForegroundColor Gray
    }
    
    # Save detailed report
    $json_output = $AuditResults | ConvertTo-Json -Depth 10
    $output_path = Join-Path $ProjectRoot $OutputFile
    $json_output | Out-File -FilePath $output_path -Encoding UTF8
    
    Write-Host ""
    Write-AuditLog "Detailed report saved to: $output_path" "SUCCESS"
    Write-AuditLog "Code quality audit completed successfully" "SUCCESS"
    
    # Exit with appropriate code
    if ($quality_gates.deployment_approved) {
        exit 0
    } else {
        Write-AuditLog "Quality gates failed - deployment not approved" "ERROR"
        exit 1
    }
    
} catch {
    Write-AuditLog "Audit failed with error: $($_.Exception.Message)" "ERROR"
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}