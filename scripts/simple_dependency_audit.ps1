# OMEGA Simple Dependency Audit Script
# Basic dependency analysis for security, license, and compatibility

param(
    [string]$ProjectRoot = "R:\OMEGA",
    [string]$OutputFile = "dependency_audit_report.json"
)

# Initialize audit results
$AuditResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    project_root = $ProjectRoot
    cargo_toml_found = $false
    dependencies_found = @()
    dev_dependencies_found = @()
    security_issues = @()
    license_issues = @()
    outdated_dependencies = @()
    overall_score = 0
    grade = "F"
    deployment_approved = $false
    recommendations = @()
}

Write-Host "Simple Dependency Audit for OMEGA" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
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

# Function to parse Cargo.toml dependencies
function Get-DependenciesFromCargoToml {
    param([string]$CargoPath)
    
    if (-not (Test-Path $CargoPath)) {
        Write-AuditLog "Cargo.toml not found at $CargoPath" "ERROR"
        return @{
            dependencies = @()
            dev_dependencies = @()
        }
    }
    
    try {
        $content = Get-Content $CargoPath
        $dependencies = @()
        $dev_dependencies = @()
        $in_deps_section = $false
        $in_dev_deps_section = $false
        
        foreach ($line in $content) {
            $line = $line.Trim()
            
            # Check for section headers
            if ($line -eq "[dependencies]") {
                $in_deps_section = $true
                $in_dev_deps_section = $false
                continue
            }
            elseif ($line -eq "[dev-dependencies]") {
                $in_deps_section = $false
                $in_dev_deps_section = $true
                continue
            }
            elseif ($line.StartsWith("[") -and $line.EndsWith("]")) {
                $in_deps_section = $false
                $in_dev_deps_section = $false
                continue
            }
            
            # Parse dependency lines
            if (($in_deps_section -or $in_dev_deps_section) -and $line -and -not $line.StartsWith("#")) {
                if ($line.Contains("=")) {
                    $parts = $line.Split("=", 2)
                    if ($parts.Length -eq 2) {
                        $dep_name = $parts[0].Trim()
                        $dep_version = $parts[1].Trim().Trim('"')
                        
                        $dep_info = @{
                            name = $dep_name
                            version = $dep_version
                        }
                        
                        if ($in_deps_section) {
                            $dependencies += $dep_info
                        } else {
                            $dev_dependencies += $dep_info
                        }
                    }
                }
            }
        }
        
        return @{
            dependencies = $dependencies
            dev_dependencies = $dev_dependencies
        }
        
    } catch {
        Write-AuditLog "Error parsing Cargo.toml: $($_.Exception.Message)" "ERROR"
        return @{
            dependencies = @()
            dev_dependencies = @()
        }
    }
}

# Function to check for known security issues
function Test-SecurityIssues {
    param([array]$Dependencies)
    
    Write-AuditLog "Checking for security vulnerabilities..." "INFO"
    
    $security_issues = @()
    
    # Known vulnerable dependencies (simplified database)
    $vulnerable_deps = @{
        "openssl" = "Multiple security vulnerabilities in older versions"
        "hyper" = "HTTP request smuggling vulnerability in older versions"
        "tokio" = "Memory safety issues in versions < 1.0"
        "serde" = "Potential deserialization vulnerability in older versions"
    }
    
    foreach ($dep in $Dependencies) {
        if ($vulnerable_deps.ContainsKey($dep.name)) {
            $security_issues += @{
                dependency = $dep.name
                version = $dep.version
                issue = $vulnerable_deps[$dep.name]
                severity = "medium"
                recommendation = "Update to latest version"
            }
        }
    }
    
    return $security_issues
}

# Function to check license compatibility
function Test-LicenseIssues {
    param([array]$Dependencies)
    
    Write-AuditLog "Checking license compatibility..." "INFO"
    
    $license_issues = @()
    
    # Known license information (simplified)
    $license_info = @{
        "serde" = "MIT/Apache-2.0"
        "tokio" = "MIT"
        "clap" = "MIT/Apache-2.0"
        "anyhow" = "MIT/Apache-2.0"
        "thiserror" = "MIT/Apache-2.0"
        "log" = "MIT/Apache-2.0"
        "env_logger" = "MIT/Apache-2.0"
        "regex" = "MIT/Apache-2.0"
        "serde_json" = "MIT/Apache-2.0"
        "toml" = "MIT/Apache-2.0"
    }
    
    foreach ($dep in $Dependencies) {
        if (-not $license_info.ContainsKey($dep.name)) {
            $license_issues += @{
                dependency = $dep.name
                version = $dep.version
                issue = "License information not available"
                severity = "low"
                recommendation = "Verify license compatibility manually"
            }
        }
    }
    
    return $license_issues
}

# Function to check for outdated dependencies
function Test-OutdatedDependencies {
    param([array]$Dependencies)
    
    Write-AuditLog "Checking for outdated dependencies..." "INFO"
    
    $outdated = @()
    
    # Simulated latest versions (in real implementation, would query crates.io)
    $latest_versions = @{
        "serde" = "1.0.193"
        "tokio" = "1.35.0"
        "clap" = "4.4.11"
        "anyhow" = "1.0.75"
        "thiserror" = "1.0.50"
        "log" = "0.4.20"
        "env_logger" = "0.10.1"
        "regex" = "1.10.2"
        "serde_json" = "1.0.108"
        "toml" = "0.8.8"
    }
    
    foreach ($dep in $Dependencies) {
        if ($latest_versions.ContainsKey($dep.name)) {
            $latest = $latest_versions[$dep.name]
            $current = $dep.version
            
            # Simple version comparison (not exact, but good enough for demo)
            if ($current -ne $latest -and -not $current.Contains($latest)) {
                $outdated += @{
                    dependency = $dep.name
                    current_version = $current
                    latest_version = $latest
                    recommendation = "Update to latest version"
                }
            }
        }
    }
    
    return $outdated
}

# Function to calculate dependency score
function Calculate-DependencyScore {
    param(
        [int]$SecurityIssues,
        [int]$LicenseIssues,
        [int]$OutdatedCount,
        [int]$TotalDeps
    )
    
    $base_score = 100
    
    # Deduct points for issues
    $security_deduction = $SecurityIssues * 25
    $license_deduction = $LicenseIssues * 5
    $outdated_deduction = $OutdatedCount * 3
    
    $final_score = [Math]::Max(0, $base_score - $security_deduction - $license_deduction - $outdated_deduction)
    
    $grade = if ($final_score -ge 90) { "A" }
             elseif ($final_score -ge 80) { "B" }
             elseif ($final_score -ge 70) { "C" }
             elseif ($final_score -ge 60) { "D" }
             else { "F" }
    
    return @{
        score = $final_score
        grade = $grade
    }
}

# Main audit execution
try {
    Write-AuditLog "Starting dependency audit" "INFO"
    
    # Check for Cargo.toml
    $cargo_path = Join-Path $ProjectRoot "Cargo.toml"
    $deps_info = Get-DependenciesFromCargoToml $cargo_path
    
    if (-not (Test-Path $cargo_path)) {
        Write-AuditLog "Cannot proceed without Cargo.toml" "ERROR"
        exit 1
    }
    
    $AuditResults.cargo_toml_found = $true
    $AuditResults.dependencies_found = $deps_info.dependencies
    $AuditResults.dev_dependencies_found = $deps_info.dev_dependencies
    
    $total_deps = $deps_info.dependencies.Count + $deps_info.dev_dependencies.Count
    Write-AuditLog "Found $($deps_info.dependencies.Count) dependencies and $($deps_info.dev_dependencies.Count) dev-dependencies" "INFO"
    
    # Combine all dependencies for analysis
    $all_deps = $deps_info.dependencies + $deps_info.dev_dependencies
    
    # Run security audit
    $security_issues = Test-SecurityIssues $all_deps
    $AuditResults.security_issues = $security_issues
    
    # Run license audit
    $license_issues = Test-LicenseIssues $all_deps
    $AuditResults.license_issues = $license_issues
    
    # Check for outdated dependencies
    $outdated_deps = Test-OutdatedDependencies $all_deps
    $AuditResults.outdated_dependencies = $outdated_deps
    
    # Calculate overall score
    $score_info = Calculate-DependencyScore $security_issues.Count $license_issues.Count $outdated_deps.Count $total_deps
    $AuditResults.overall_score = $score_info.score
    $AuditResults.grade = $score_info.grade
    
    # Determine deployment approval
    $high_security_issues = ($security_issues | Where-Object { $_.severity -eq "high" }).Count
    $AuditResults.deployment_approved = ($high_security_issues -eq 0) -and ($score_info.score -ge 70)
    
    # Generate recommendations
    $recommendations = @()
    
    if ($security_issues.Count -gt 0) {
        $recommendations += "Address security vulnerabilities by updating affected dependencies"
    }
    
    if ($license_issues.Count -gt 3) {
        $recommendations += "Review license compatibility for unknown dependencies"
    }
    
    if ($outdated_deps.Count -gt 5) {
        $recommendations += "Update outdated dependencies to benefit from bug fixes and improvements"
    }
    
    if ($total_deps -eq 0) {
        $recommendations += "Consider adding necessary dependencies for a complete implementation"
    }
    
    if ($recommendations.Count -eq 0) {
        $recommendations += "Dependencies are in good condition - consider regular updates"
    }
    
    $AuditResults.recommendations = $recommendations
    
    # Display results
    Write-Host ""
    Write-Host "DEPENDENCY AUDIT RESULTS" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host "Overall Score: $($score_info.score)/100 ($($score_info.grade))" -ForegroundColor $(if ($score_info.grade -match "A|B") { "Green" } elseif ($score_info.grade -eq "C") { "Yellow" } else { "Red" })
    Write-Host "Total Dependencies: $total_deps" -ForegroundColor White
    Write-Host "Security Issues: $($security_issues.Count)" -ForegroundColor $(if ($security_issues.Count -eq 0) { "Green" } else { "Red" })
    Write-Host "License Issues: $($license_issues.Count)" -ForegroundColor $(if ($license_issues.Count -eq 0) { "Green" } else { "Yellow" })
    Write-Host "Outdated Dependencies: $($outdated_deps.Count)" -ForegroundColor $(if ($outdated_deps.Count -eq 0) { "Green" } elseif ($outdated_deps.Count -le 3) { "Yellow" } else { "Red" })
    Write-Host "Deployment Approved: $(if ($AuditResults.deployment_approved) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($AuditResults.deployment_approved) { "Green" } else { "Red" })
    
    if ($security_issues.Count -gt 0) {
        Write-Host ""
        Write-Host "SECURITY ISSUES:" -ForegroundColor Red
        foreach ($issue in $security_issues) {
            Write-Host "  [$($issue.severity.ToUpper())] $($issue.dependency): $($issue.issue)" -ForegroundColor Red
        }
    }
    
    if ($license_issues.Count -gt 0 -and $license_issues.Count -le 10) {
        Write-Host ""
        Write-Host "LICENSE ISSUES:" -ForegroundColor Yellow
        foreach ($issue in $license_issues) {
            Write-Host "  [$($issue.severity.ToUpper())] $($issue.dependency): $($issue.issue)" -ForegroundColor Yellow
        }
    }
    
    if ($outdated_deps.Count -gt 0) {
        Write-Host ""
        Write-Host "OUTDATED DEPENDENCIES (showing first 5):" -ForegroundColor Gray
        $outdated_deps | Select-Object -First 5 | ForEach-Object {
            Write-Host "  $($_.dependency): $($_.current_version) -> $($_.latest_version)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "RECOMMENDATIONS:" -ForegroundColor Green
    foreach ($rec in $recommendations) {
        Write-Host "  • $rec" -ForegroundColor Gray
    }
    
    # Save report
    $json_output = $AuditResults | ConvertTo-Json -Depth 5
    $output_path = Join-Path $ProjectRoot $OutputFile
    $json_output | Out-File -FilePath $output_path -Encoding UTF8
    
    Write-Host ""
    Write-AuditLog "Report saved to: $output_path" "SUCCESS"
    Write-AuditLog "Dependency audit completed" "SUCCESS"
    
    # Exit with appropriate code
    if ($AuditResults.deployment_approved) {
        exit 0
    } else {
        Write-AuditLog "Dependency issues found - review required before deployment" "WARN"
        exit 1
    }
    
} catch {
    Write-AuditLog "Dependency audit failed: $($_.Exception.Message)" "ERROR"
    exit 1
}