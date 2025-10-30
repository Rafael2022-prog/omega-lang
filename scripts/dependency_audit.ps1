# OMEGA Dependency Audit Script
# Comprehensive dependency security, license, and compatibility analysis

param(
    [string]$ProjectRoot = "R:\OMEGA",
    [string]$OutputFile = "dependency_audit_report.json"
)

# Initialize audit results
$AuditResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    project_root = $ProjectRoot
    cargo_toml_found = $false
    dependencies_count = 0
    dev_dependencies_count = 0
    security_issues = @()
    license_issues = @()
    compatibility_issues = @()
    outdated_dependencies = @()
    overall_score = 0
    grade = "F"
    deployment_approved = $false
    recommendations = @()
}

Write-Host "Dependency Audit for OMEGA" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
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

# Function to parse Cargo.toml
function Get-CargoTomlInfo {
    param([string]$CargoPath)
    
    if (-not (Test-Path $CargoPath)) {
        Write-AuditLog "Cargo.toml not found at $CargoPath" "ERROR"
        return $null
    }
    
    try {
        $content = Get-Content $CargoPath -Raw
        $info = @{
            dependencies = @{}
            dev_dependencies = @{}
            build_dependencies = @{}
            features = @{}
            package_info = @{}
        }
        
        # Parse basic package information
        if ($content -match '\[package\]') {
            $package_section = ($content -split '\[package\]')[1] -split '\[\w')[0]
            
            if ($package_section -match 'name\s*=\s*"([^"]+)"') {
                $info.package_info.name = $matches[1]
            }
            if ($package_section -match 'version\s*=\s*"([^"]+)"') {
                $info.package_info.version = $matches[1]
            }
            if ($package_section -match 'edition\s*=\s*"([^"]+)"') {
                $info.package_info.edition = $matches[1]
            }
        }
        
        # Parse dependencies section
        if ($content -match '\[dependencies\]') {
            $deps_section = ($content -split '\[dependencies\]')[1]
            if ($deps_section -match '\[') {
                $deps_section = ($deps_section -split '\[')[0]
            }
            
            $deps_lines = $deps_section -split "`n" | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') }
            foreach ($line in $deps_lines) {
                if ($line -match '^\s*([^=\s]+)\s*=\s*(.+)$') {
                    $dep_name = $matches[1].Trim()
                    $dep_spec = $matches[2].Trim()
                    $info.dependencies[$dep_name] = $dep_spec
                }
            }
        }
        
        # Parse dev-dependencies section
        if ($content -match '\[dev-dependencies\]') {
            $dev_deps_section = ($content -split '\[dev-dependencies\]')[1]
            if ($dev_deps_section -match '\[') {
                $dev_deps_section = ($dev_deps_section -split '\[')[0]
            }
            
            $dev_deps_lines = $dev_deps_section -split "`n" | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') }
            foreach ($line in $dev_deps_lines) {
                if ($line -match '^\s*([^=\s]+)\s*=\s*(.+)$') {
                    $dep_name = $matches[1].Trim()
                    $dep_spec = $matches[2].Trim()
                    $info.dev_dependencies[$dep_name] = $dep_spec
                }
            }
        }
        
        return $info
        
    } catch {
        Write-AuditLog "Error parsing Cargo.toml: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Function to check for known security vulnerabilities
function Test-SecurityVulnerabilities {
    param([hashtable]$Dependencies)
    
    Write-AuditLog "Checking for security vulnerabilities..." "INFO"
    
    $vulnerabilities = @()
    
    # Known vulnerable patterns (simplified database)
    $known_issues = @{
        "serde" = @{
            vulnerable_versions = @("< 1.0.100")
            issue = "Potential deserialization vulnerability"
            severity = "medium"
        }
        "tokio" = @{
            vulnerable_versions = @("< 1.0.0")
            issue = "Memory safety issues in older versions"
            severity = "high"
        }
        "openssl" = @{
            vulnerable_versions = @("< 0.10.30")
            issue = "Multiple security vulnerabilities"
            severity = "high"
        }
        "hyper" = @{
            vulnerable_versions = @("< 0.14.0")
            issue = "HTTP request smuggling vulnerability"
            severity = "medium"
        }
    }
    
    foreach ($dep_name in $Dependencies.Keys) {
        if ($known_issues.ContainsKey($dep_name)) {
            $issue_info = $known_issues[$dep_name]
            $dep_version = $Dependencies[$dep_name]
            
            # Simple version check (in real implementation, would use proper semver parsing)
            $vulnerabilities += @{
                dependency = $dep_name
                version = $dep_version
                issue = $issue_info.issue
                severity = $issue_info.severity
                recommendation = "Update to latest version"
            }
        }
    }
    
    return $vulnerabilities
}

# Function to check license compatibility
function Test-LicenseCompatibility {
    param([hashtable]$Dependencies)
    
    Write-AuditLog "Checking license compatibility..." "INFO"
    
    $license_issues = @()
    
    # Known license information (simplified)
    $license_db = @{
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
    
    # Incompatible licenses for MIT project
    $incompatible_licenses = @("GPL-3.0", "AGPL-3.0", "LGPL-3.0")
    
    foreach ($dep_name in $Dependencies.Keys) {
        if ($license_db.ContainsKey($dep_name)) {
            $license = $license_db[$dep_name]
            
            # Check for incompatible licenses
            foreach ($incompatible in $incompatible_licenses) {
                if ($license -match $incompatible) {
                    $license_issues += @{
                        dependency = $dep_name
                        license = $license
                        issue = "License incompatible with MIT"
                        severity = "high"
                        recommendation = "Find alternative with compatible license"
                    }
                }
            }
        } else {
            # Unknown license
            $license_issues += @{
                dependency = $dep_name
                license = "Unknown"
                issue = "License information not available"
                severity = "medium"
                recommendation = "Verify license compatibility manually"
            }
        }
    }
    
    return $license_issues
}

# Function to check for outdated dependencies
function Test-OutdatedDependencies {
    param([hashtable]$Dependencies)
    
    Write-AuditLog "Checking for outdated dependencies..." "INFO"
    
    $outdated = @()
    
    # Simulated version database (in real implementation, would query crates.io)
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
    
    foreach ($dep_name in $Dependencies.Keys) {
        if ($latest_versions.ContainsKey($dep_name)) {
            $current_spec = $Dependencies[$dep_name]
            $latest = $latest_versions[$dep_name]
            
            # Simple version extraction (in real implementation, would use proper parsing)
            $current_version = $current_spec -replace '[^0-9.]', ''
            
            if ($current_version -and $current_version -ne $latest) {
                $outdated += @{
                    dependency = $dep_name
                    current_version = $current_spec
                    latest_version = $latest
                    recommendation = "Update to latest version for bug fixes and improvements"
                }
            }
        }
    }
    
    return $outdated
}

# Function to check version compatibility
function Test-VersionCompatibility {
    param([hashtable]$Dependencies)
    
    Write-AuditLog "Checking version compatibility..." "INFO"
    
    $compatibility_issues = @()
    
    # Check for potential version conflicts
    $rust_edition_deps = @{
        "2018" = @("tokio", "serde", "clap")
        "2021" = @("tokio", "serde", "clap", "anyhow", "thiserror")
    }
    
    # Check for dependencies that might not work well together
    $conflict_patterns = @{
        "tokio_old_async_std" = @{
            deps = @("tokio", "async-std")
            issue = "Tokio and async-std runtime conflict"
            severity = "high"
        }
        "serde_version_mismatch" = @{
            deps = @("serde", "serde_json", "serde_derive")
            issue = "Serde ecosystem version mismatch"
            severity = "medium"
        }
    }
    
    foreach ($pattern in $conflict_patterns.Keys) {
        $conflict_info = $conflict_patterns[$pattern]
        $found_deps = @()
        
        foreach ($dep in $conflict_info.deps) {
            if ($Dependencies.ContainsKey($dep)) {
                $found_deps += $dep
            }
        }
        
        if ($found_deps.Count -gt 1) {
            $compatibility_issues += @{
                pattern = $pattern
                dependencies = $found_deps
                issue = $conflict_info.issue
                severity = $conflict_info.severity
                recommendation = "Ensure compatible versions or choose one runtime"
            }
        }
    }
    
    return $compatibility_issues
}

# Function to calculate dependency score
function Calculate-DependencyScore {
    param(
        [int]$SecurityIssues,
        [int]$LicenseIssues,
        [int]$CompatibilityIssues,
        [int]$OutdatedCount
    )
    
    $base_score = 100
    
    # Deduct points for issues
    $score_deduction = ($SecurityIssues * 20) + ($LicenseIssues * 15) + ($CompatibilityIssues * 10) + ($OutdatedCount * 2)
    
    $final_score = [Math]::Max(0, $base_score - $score_deduction)
    
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
    $cargo_info = Get-CargoTomlInfo $cargo_path
    
    if (-not $cargo_info) {
        Write-AuditLog "Cannot proceed without valid Cargo.toml" "ERROR"
        exit 1
    }
    
    $AuditResults.cargo_toml_found = $true
    $AuditResults.dependencies_count = $cargo_info.dependencies.Count
    $AuditResults.dev_dependencies_count = $cargo_info.dev_dependencies.Count
    
    Write-AuditLog "Found $($cargo_info.dependencies.Count) dependencies and $($cargo_info.dev_dependencies.Count) dev-dependencies" "INFO"
    
    # Combine all dependencies for analysis
    $all_deps = @{}
    foreach ($dep in $cargo_info.dependencies.GetEnumerator()) {
        $all_deps[$dep.Key] = $dep.Value
    }
    foreach ($dep in $cargo_info.dev_dependencies.GetEnumerator()) {
        $all_deps[$dep.Key] = $dep.Value
    }
    
    # Run security audit
    Write-AuditLog "Running security vulnerability check..." "INFO"
    $security_issues = Test-SecurityVulnerabilities $all_deps
    $AuditResults.security_issues = $security_issues
    
    # Run license audit
    Write-AuditLog "Running license compatibility check..." "INFO"
    $license_issues = Test-LicenseCompatibility $all_deps
    $AuditResults.license_issues = $license_issues
    
    # Check for outdated dependencies
    Write-AuditLog "Checking for outdated dependencies..." "INFO"
    $outdated_deps = Test-OutdatedDependencies $all_deps
    $AuditResults.outdated_dependencies = $outdated_deps
    
    # Check version compatibility
    Write-AuditLog "Checking version compatibility..." "INFO"
    $compatibility_issues = Test-VersionCompatibility $all_deps
    $AuditResults.compatibility_issues = $compatibility_issues
    
    # Calculate overall score
    $score_info = Calculate-DependencyScore $security_issues.Count $license_issues.Count $compatibility_issues.Count $outdated_deps.Count
    $AuditResults.overall_score = $score_info.score
    $AuditResults.grade = $score_info.grade
    
    # Determine deployment approval
    $high_security_issues = ($security_issues | Where-Object { $_.severity -eq "high" }).Count
    $high_license_issues = ($license_issues | Where-Object { $_.severity -eq "high" }).Count
    $high_compatibility_issues = ($compatibility_issues | Where-Object { $_.severity -eq "high" }).Count
    
    $AuditResults.deployment_approved = ($high_security_issues -eq 0) -and ($high_license_issues -eq 0) -and ($high_compatibility_issues -eq 0) -and ($score_info.score -ge 70)
    
    # Generate recommendations
    $recommendations = @()
    
    if ($security_issues.Count -gt 0) {
        $recommendations += "Address security vulnerabilities by updating affected dependencies"
    }
    
    if ($license_issues.Count -gt 0) {
        $recommendations += "Review and resolve license compatibility issues"
    }
    
    if ($outdated_deps.Count -gt 5) {
        $recommendations += "Update outdated dependencies to benefit from bug fixes and improvements"
    }
    
    if ($compatibility_issues.Count -gt 0) {
        $recommendations += "Resolve version compatibility conflicts between dependencies"
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
    Write-Host "Dependencies: $($cargo_info.dependencies.Count)" -ForegroundColor White
    Write-Host "Dev Dependencies: $($cargo_info.dev_dependencies.Count)" -ForegroundColor White
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
    
    if ($license_issues.Count -gt 0) {
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