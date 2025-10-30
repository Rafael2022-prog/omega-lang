# OMEGA Simple Code Quality Audit Script
# Simplified code quality analysis for OMEGA compiler

param(
    [string]$ProjectRoot = "R:\OMEGA",
    [string]$OutputFile = "code_quality_report.json"
)

# Initialize audit results
$AuditResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    project_root = $ProjectRoot
    overall_score = 0
    grade = "F"
    deployment_approved = $false
    files_analyzed = 0
    issues_found = 0
    summary = ""
}

Write-Host "Code Quality Audit for OMEGA" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Gray
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
}

# Function to analyze basic file metrics
function Get-BasicFileMetrics {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return $null
    }
    
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        return $null
    }
    
    $lines = (Get-Content $FilePath -ErrorAction SilentlyContinue).Count
    if (-not $lines) { $lines = 0 }
    
    # Count basic patterns
    $function_count = 0
    $comment_count = 0
    $blank_count = 0
    
    try {
        # Simple pattern counting without complex regex
        $function_count = ($content -split "fn " | Measure-Object).Count - 1
        $comment_count = ($content -split "//" | Measure-Object).Count - 1
        $blank_count = ($content -split "`n" | Where-Object { $_.Trim() -eq "" } | Measure-Object).Count
    } catch {
        Write-AuditLog "Warning: Could not analyze patterns in $FilePath" "WARN"
    }
    
    return @{
        file_path = $FilePath
        lines_of_code = $lines
        function_count = $function_count
        comment_count = $comment_count
        blank_lines = $blank_count
        effective_lines = $lines - $blank_count
        last_modified = (Get-Item $FilePath -ErrorAction SilentlyContinue).LastWriteTime
    }
}

# Function to find basic code issues
function Find-BasicIssues {
    param([string]$FilePath, [hashtable]$Metrics)
    
    $issues = @()
    
    try {
        $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
        if (-not $content) {
            return $issues
        }
        
        # Check file size issues
        if ($Metrics.lines_of_code -gt 500) {
            $issues += @{
                type = "maintainability"
                severity = "medium"
                file = $FilePath
                description = "Large file ($($Metrics.lines_of_code) lines) may be hard to maintain"
                recommendation = "Consider breaking into smaller modules"
            }
        }
        
        # Check for basic patterns (simple string matching)
        if ($content -match "unwrap\(\)") {
            $issues += @{
                type = "reliability"
                severity = "medium"
                file = $FilePath
                description = "Found unwrap() calls that may cause panics"
                recommendation = "Use proper error handling instead of unwrap()"
            }
        }
        
        if ($content -match "todo!") {
            $issues += @{
                type = "completeness"
                severity = "high"
                file = $FilePath
                description = "Found TODO markers in code"
                recommendation = "Complete implementation before deployment"
            }
        }
        
        if ($content -match "panic!") {
            $issues += @{
                type = "reliability"
                severity = "high"
                file = $FilePath
                description = "Found explicit panic calls"
                recommendation = "Replace with proper error handling"
            }
        }
        
        # Check documentation ratio
        if ($Metrics.function_count -gt 0) {
            $doc_ratio = $Metrics.comment_count / $Metrics.function_count
            if ($doc_ratio -lt 0.5) {
                $issues += @{
                    type = "documentation"
                    severity = "medium"
                    file = $FilePath
                    description = "Low documentation ratio"
                    recommendation = "Add more documentation comments"
                }
            }
        }
        
    } catch {
        Write-AuditLog "Warning: Could not analyze issues in $FilePath" "WARN"
    }
    
    return $issues
}

# Main audit execution
try {
    Write-AuditLog "Starting code quality audit" "INFO"
    
    # Find source files
    $source_files = @()
    if (Test-Path "$ProjectRoot\src") {
        $source_files += Get-ChildItem -Path "$ProjectRoot\src" -Filter "*.rs" -Recurse -ErrorAction SilentlyContinue
    }
    if (Test-Path "$ProjectRoot\src") {
        $source_files += Get-ChildItem -Path "$ProjectRoot\src" -Filter "*.mega" -Recurse -ErrorAction SilentlyContinue
    }
    
    Write-AuditLog "Found $($source_files.Count) source files to analyze" "INFO"
    
    $all_metrics = @()
    $all_issues = @()
    $files_analyzed = 0
    
    # Analyze each file
    foreach ($file in $source_files) {
        Write-AuditLog "Analyzing: $($file.Name)" "INFO"
        
        $metrics = Get-BasicFileMetrics $file.FullName
        if ($metrics) {
            $all_metrics += $metrics
            $files_analyzed++
            
            # Find issues in this file
            $file_issues = Find-BasicIssues $file.FullName $metrics
            $all_issues += $file_issues
        }
    }
    
    # Calculate basic quality score
    $total_lines = ($all_metrics | Measure-Object -Property lines_of_code -Sum).Sum
    $total_functions = ($all_metrics | Measure-Object -Property function_count -Sum).Sum
    $total_comments = ($all_metrics | Measure-Object -Property comment_count -Sum).Sum
    
    # Basic scoring
    $base_score = 100
    
    # Deduct points for issues
    $high_issues = ($all_issues | Where-Object { $_.severity -eq "high" }).Count
    $medium_issues = ($all_issues | Where-Object { $_.severity -eq "medium" }).Count
    $low_issues = ($all_issues | Where-Object { $_.severity -eq "low" }).Count
    
    $score_deduction = ($high_issues * 15) + ($medium_issues * 8) + ($low_issues * 3)
    $final_score = [Math]::Max(0, $base_score - $score_deduction)
    
    # Calculate grade
    $grade = if ($final_score -ge 90) { "A" }
             elseif ($final_score -ge 80) { "B" }
             elseif ($final_score -ge 70) { "C" }
             elseif ($final_score -ge 60) { "D" }
             else { "F" }
    
    # Determine deployment approval
    $deployment_approved = ($final_score -ge 75) -and ($high_issues -eq 0)
    
    # Update results
    $AuditResults.overall_score = $final_score
    $AuditResults.grade = $grade
    $AuditResults.deployment_approved = $deployment_approved
    $AuditResults.files_analyzed = $files_analyzed
    $AuditResults.issues_found = $all_issues.Count
    
    # Generate summary
    $summary = @"
Code Quality Audit Summary:
- Files Analyzed: $files_analyzed
- Total Lines of Code: $total_lines
- Total Functions: $total_functions
- Issues Found: $($all_issues.Count) (High: $high_issues, Medium: $medium_issues, Low: $low_issues)
- Overall Score: $final_score/100 ($grade)
- Deployment Approved: $(if ($deployment_approved) { 'YES' } else { 'NO' })
"@
    
    $AuditResults.summary = $summary
    
    # Display results
    Write-Host ""
    Write-Host "AUDIT RESULTS" -ForegroundColor Cyan
    Write-Host "=============" -ForegroundColor Cyan
    Write-Host "Overall Score: $final_score/100 ($grade)" -ForegroundColor $(if ($grade -match "A|B") { "Green" } elseif ($grade -eq "C") { "Yellow" } else { "Red" })
    Write-Host "Files Analyzed: $files_analyzed" -ForegroundColor White
    Write-Host "Total Lines: $total_lines" -ForegroundColor White
    Write-Host "Issues Found: $($all_issues.Count)" -ForegroundColor $(if ($all_issues.Count -eq 0) { "Green" } elseif ($all_issues.Count -le 5) { "Yellow" } else { "Red" })
    Write-Host "Deployment Approved: $(if ($deployment_approved) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($deployment_approved) { "Green" } else { "Red" })
    
    if ($all_issues.Count -gt 0) {
        Write-Host ""
        Write-Host "TOP ISSUES:" -ForegroundColor Yellow
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
    
    # Save report
    $json_output = $AuditResults | ConvertTo-Json -Depth 5
    $output_path = Join-Path $ProjectRoot $OutputFile
    $json_output | Out-File -FilePath $output_path -Encoding UTF8
    
    Write-Host ""
    Write-AuditLog "Report saved to: $output_path" "SUCCESS"
    Write-AuditLog "Code quality audit completed" "SUCCESS"
    
    # Exit with appropriate code
    if ($deployment_approved) {
        exit 0
    } else {
        Write-AuditLog "Quality standards not met - deployment not recommended" "WARN"
        exit 1
    }
    
} catch {
    Write-AuditLog "Audit failed: $($_.Exception.Message)" "ERROR"
    exit 1
}