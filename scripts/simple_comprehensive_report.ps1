# OMEGA Comprehensive Audit Report Generator (Simple Version)
# Consolidates all audit results into final assessment

param(
    [string]$ProjectRoot = "R:\OMEGA"
)

Write-Host "OMEGA Comprehensive Audit Report Generator" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Yellow
Write-Host ""

# Initialize report structure
$ComprehensiveReport = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    project_root = $ProjectRoot
    audit_results = @{}
    overall_assessment = @{}
    deployment_decision = @{}
    recommendations = @()
}

# Load individual audit reports
$ReportFiles = @{
    "code_quality" = "$ProjectRoot\code_quality_report.json"
    "dependencies" = "$ProjectRoot\dependency_audit_report.json"
    "documentation" = "$ProjectRoot\documentation_audit_report.json"
}

Write-Host "Loading individual audit reports..." -ForegroundColor Green

foreach ($AuditType in $ReportFiles.Keys) {
    $ReportPath = $ReportFiles[$AuditType]
    
    if (Test-Path $ReportPath) {
        try {
            $Content = Get-Content $ReportPath -Raw | ConvertFrom-Json
            $ComprehensiveReport.audit_results[$AuditType] = $Content
            
            $Score = if ($Content.overall_score) { $Content.overall_score } else { 0 }
            $Grade = if ($Content.grade) { $Content.grade } else { "F" }
            
            Write-Host "$AuditType`: $Score/100 ($Grade)" -ForegroundColor $(if ($Score -ge 70) { "Green" } elseif ($Score -ge 50) { "Yellow" } else { "Red" })
        }
        catch {
            Write-Host "Error loading $AuditType report: $($_.Exception.Message)" -ForegroundColor Red
            $ComprehensiveReport.audit_results[$AuditType] = @{ error = $_.Exception.Message }
        }
    }
    else {
        Write-Host "$AuditType report not found: $ReportPath" -ForegroundColor Yellow
        $ComprehensiveReport.audit_results[$AuditType] = @{ status = "not_found" }
    }
}

Write-Host ""

# Calculate overall assessment
$Scores = @()
$AllPassed = $true
$CriticalIssues = @()

foreach ($AuditType in $ComprehensiveReport.audit_results.Keys) {
    $Result = $ComprehensiveReport.audit_results[$AuditType]
    
    if ($Result.overall_score) {
        $Scores += $Result.overall_score
        
        if ($Result.overall_score -lt 50) {
            $AllPassed = $false
            $CriticalIssues += "$AuditType (Score: $($Result.overall_score))"
        }
    }
    elseif ($Result.error -or $Result.status -eq "not_found") {
        $AllPassed = $false
        $CriticalIssues += "$AuditType (Failed/Missing)"
    }
}

# Calculate weighted average
$OverallScore = if ($Scores.Count -gt 0) { 
    [math]::Round(($Scores | Measure-Object -Average).Average, 1) 
} else { 
    0 
}

$OverallGrade = switch ($OverallScore) {
    { $_ -ge 90 } { "A" }
    { $_ -ge 80 } { "B" }
    { $_ -ge 70 } { "C" }
    { $_ -ge 60 } { "D" }
    default { "F" }
}

# Deployment decision logic
$DeploymentApproved = $AllPassed -and ($OverallScore -ge 70) -and ($CriticalIssues.Count -eq 0)

$ComprehensiveReport.overall_assessment = @{
    overall_score = $OverallScore
    overall_grade = $OverallGrade
    audits_completed = $ComprehensiveReport.audit_results.Keys.Count
    critical_issues_count = $CriticalIssues.Count
    critical_issues = $CriticalIssues
}

$ComprehensiveReport.deployment_decision = @{
    approved = $DeploymentApproved
    reason = if ($DeploymentApproved) { 
        "All audits passed with acceptable scores" 
    } else { 
        "Critical issues found: $($CriticalIssues -join ', ')" 
    }
    recommendation = if ($DeploymentApproved) { 
        "PROCEED with deployment" 
    } else { 
        "DO NOT DEPLOY - Address critical issues first" 
    }
}

# Generate consolidated recommendations
$AllRecommendations = @()

foreach ($AuditType in $ComprehensiveReport.audit_results.Keys) {
    $Result = $ComprehensiveReport.audit_results[$AuditType]
    
    if ($Result.recommendations) {
        foreach ($Rec in $Result.recommendations) {
            $AllRecommendations += @{
                category = $AuditType
                recommendation = $Rec
                priority = if ($Result.overall_score -lt 30) { "HIGH" } elseif ($Result.overall_score -lt 60) { "MEDIUM" } else { "LOW" }
            }
        }
    }
}

# Add specific recommendations based on scores
if ($ComprehensiveReport.audit_results.code_quality.overall_score -lt 60) {
    $AllRecommendations += @{
        category = "code_quality"
        recommendation = "Improve code quality through refactoring and better practices"
        priority = "HIGH"
    }
}

if ($ComprehensiveReport.audit_results.dependencies.overall_score -lt 60) {
    $AllRecommendations += @{
        category = "dependencies"
        recommendation = "Update dependencies and resolve security vulnerabilities"
        priority = "HIGH"
    }
}

if ($ComprehensiveReport.audit_results.documentation.overall_score -lt 60) {
    $AllRecommendations += @{
        category = "documentation"
        recommendation = "Create comprehensive documentation including README and LICENSE"
        priority = "MEDIUM"
    }
}

$ComprehensiveReport.recommendations = $AllRecommendations

# Display results
Write-Host "COMPREHENSIVE AUDIT RESULTS" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Overall Score: $OverallScore/100 ($OverallGrade)" -ForegroundColor $(if ($OverallScore -ge 70) { "Green" } elseif ($OverallScore -ge 50) { "Yellow" } else { "Red" })
Write-Host "Audits Completed: $($ComprehensiveReport.overall_assessment.audits_completed)"
Write-Host "Critical Issues: $($CriticalIssues.Count)"
Write-Host ""

Write-Host "DEPLOYMENT DECISION" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "Status: $(if ($DeploymentApproved) { 'APPROVED' } else { 'REJECTED' })" -ForegroundColor $(if ($DeploymentApproved) { "Green" } else { "Red" })
Write-Host "Recommendation: $($ComprehensiveReport.deployment_decision.recommendation)" -ForegroundColor $(if ($DeploymentApproved) { "Green" } else { "Red" })
Write-Host "Reason: $($ComprehensiveReport.deployment_decision.reason)"
Write-Host ""

if ($AllRecommendations.Count -gt 0) {
    Write-Host "TOP RECOMMENDATIONS" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    
    $HighPriority = $AllRecommendations | Where-Object { $_.priority -eq "HIGH" }
    $MediumPriority = $AllRecommendations | Where-Object { $_.priority -eq "MEDIUM" }
    
    if ($HighPriority.Count -gt 0) {
        Write-Host "HIGH PRIORITY:" -ForegroundColor Red
        foreach ($Rec in $HighPriority) {
            Write-Host "  - [$($Rec.category)] $($Rec.recommendation)" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    if ($MediumPriority.Count -gt 0) {
        Write-Host "MEDIUM PRIORITY:" -ForegroundColor Yellow
        foreach ($Rec in $MediumPriority) {
            Write-Host "  - [$($Rec.category)] $($Rec.recommendation)" -ForegroundColor Yellow
        }
        Write-Host ""
    }
}

# Save comprehensive report
$OutputPath = "$ProjectRoot\comprehensive_audit_report.json"
try {
    $ComprehensiveReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Comprehensive audit report saved to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Host "Error saving comprehensive report: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Audit completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# Return exit code based on deployment decision
if ($DeploymentApproved) {
    exit 0
} else {
    exit 1
}