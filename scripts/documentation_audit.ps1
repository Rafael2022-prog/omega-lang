# OMEGA Documentation Audit Script
# Comprehensive documentation completeness, accuracy, and quality analysis

param(
    [string]$ProjectRoot = "R:\OMEGA",
    [string]$OutputFile = "documentation_audit_report.json"
)

# Initialize audit results
$AuditResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    project_root = $ProjectRoot
    documentation_files = @()
    missing_documentation = @()
    documentation_quality = @()
    code_documentation = @()
    overall_score = 0
    grade = "F"
    deployment_approved = $false
    recommendations = @()
}

Write-Host "Documentation Audit for OMEGA" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
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

# Function to check for required documentation files
function Test-RequiredDocumentation {
    param([string]$RootPath)
    
    Write-AuditLog "Checking for required documentation files..." "INFO"
    
    $required_docs = @{
        "README.md" = @{
            path = "README.md"
            description = "Main project documentation"
            critical = $true
        }
        "LANGUAGE_SPECIFICATION.md" = @{
            path = "LANGUAGE_SPECIFICATION.md"
            description = "OMEGA language specification"
            critical = $true
        }
        "COMPILER_ARCHITECTURE.md" = @{
            path = "COMPILER_ARCHITECTURE.md"
            description = "Compiler architecture documentation"
            critical = $true
        }
        "CONTRIBUTING.md" = @{
            path = "CONTRIBUTING.md"
            description = "Contribution guidelines"
            critical = $false
        }
        "LICENSE" = @{
            path = "LICENSE"
            description = "Project license"
            critical = $true
        }
        "docs/getting-started.md" = @{
            path = "docs/getting-started.md"
            description = "Getting started guide"
            critical = $false
        }
        "docs/examples/" = @{
            path = "docs/examples"
            description = "Code examples directory"
            critical = $false
        }
    }
    
    $found_docs = @()
    $missing_docs = @()
    
    foreach ($doc_key in $required_docs.Keys) {
        $doc_info = $required_docs[$doc_key]
        $full_path = Join-Path $RootPath $doc_info.path
        
        if (Test-Path $full_path) {
            $file_info = Get-Item $full_path
            $found_docs += @{
                name = $doc_key
                path = $doc_info.path
                description = $doc_info.description
                critical = $doc_info.critical
                size = $file_info.Length
                last_modified = $file_info.LastWriteTime
                exists = $true
            }
        } else {
            $missing_docs += @{
                name = $doc_key
                path = $doc_info.path
                description = $doc_info.description
                critical = $doc_info.critical
                exists = $false
            }
        }
    }
    
    return @{
        found = $found_docs
        missing = $missing_docs
    }
}

# Function to analyze documentation quality
function Test-DocumentationQuality {
    param([array]$DocumentationFiles, [string]$RootPath)
    
    Write-AuditLog "Analyzing documentation quality..." "INFO"
    
    $quality_results = @()
    
    foreach ($doc in $DocumentationFiles) {
        if ($doc.exists -and $doc.name.EndsWith(".md")) {
            $full_path = Join-Path $RootPath $doc.path
            
            try {
                $content = Get-Content $full_path -Raw
                $lines = Get-Content $full_path
                
                $quality_metrics = @{
                    name = $doc.name
                    path = $doc.path
                    line_count = $lines.Count
                    character_count = $content.Length
                    word_count = ($content -split '\s+').Count
                    has_title = $content -match '^#\s+'
                    has_toc = $content -match '(?i)table.of.contents|toc'
                    has_examples = $content -match '```'
                    has_links = $content -match '\[.*\]\(.*\)'
                    section_count = ($content -split '^#+\s+').Count - 1
                    code_block_count = ($content -split '```').Count / 2
                    quality_score = 0
                }
                
                # Calculate quality score
                $score = 0
                if ($quality_metrics.line_count -gt 10) { $score += 20 }
                if ($quality_metrics.has_title) { $score += 20 }
                if ($quality_metrics.has_examples) { $score += 20 }
                if ($quality_metrics.has_links) { $score += 15 }
                if ($quality_metrics.section_count -gt 3) { $score += 15 }
                if ($quality_metrics.word_count -gt 100) { $score += 10 }
                
                $quality_metrics.quality_score = $score
                $quality_results += $quality_metrics
                
            } catch {
                Write-AuditLog "Error analyzing $($doc.name): $($_.Exception.Message)" "WARN"
            }
        }
    }
    
    return $quality_results
}

# Function to check code documentation
function Test-CodeDocumentation {
    param([string]$RootPath)
    
    Write-AuditLog "Checking code documentation..." "INFO"
    
    $code_doc_results = @()
    
    # Find Rust source files
    $rust_files = Get-ChildItem -Path $RootPath -Recurse -Filter "*.rs" | Where-Object { $_.FullName -notmatch "target" }
    
    foreach ($file in $rust_files) {
        try {
            $content = Get-Content $file.FullName -Raw
            $lines = Get-Content $file.FullName
            
            # Count documentation comments
            $doc_comments = ($content -split "`n" | Where-Object { $_ -match '^\s*///' }).Count
            $regular_comments = ($content -split "`n" | Where-Object { $_ -match '^\s*//' -and $_ -notmatch '^\s*///' }).Count
            $function_count = ($content -split "`n" | Where-Object { $_ -match '^\s*(?:pub\s+)?fn\s+' }).Count
            $struct_count = ($content -split "`n" | Where-Object { $_ -match '^\s*(?:pub\s+)?struct\s+' }).Count
            $enum_count = ($content -split "`n" | Where-Object { $_ -match '^\s*(?:pub\s+)?enum\s+' }).Count
            
            $relative_path = $file.FullName.Replace($RootPath, "").TrimStart('\')
            
            $code_doc_info = @{
                file = $relative_path
                line_count = $lines.Count
                doc_comments = $doc_comments
                regular_comments = $regular_comments
                function_count = $function_count
                struct_count = $struct_count
                enum_count = $enum_count
                documentation_ratio = if ($function_count + $struct_count + $enum_count -gt 0) { 
                    [Math]::Round(($doc_comments / ($function_count + $struct_count + $enum_count)) * 100, 2) 
                } else { 0 }
            }
            
            $code_doc_results += $code_doc_info
            
        } catch {
            Write-AuditLog "Error analyzing code file $($file.Name): $($_.Exception.Message)" "WARN"
        }
    }
    
    return $code_doc_results
}

# Function to calculate documentation score
function Calculate-DocumentationScore {
    param(
        [int]$FoundDocsCount,
        [int]$MissingCriticalCount,
        [int]$MissingTotalCount,
        [array]$QualityResults,
        [array]$CodeDocResults
    )
    
    $base_score = 100
    
    # Deduct points for missing documentation
    $missing_critical_deduction = $MissingCriticalCount * 30
    $missing_other_deduction = ($MissingTotalCount - $MissingCriticalCount) * 10
    
    # Calculate average quality score
    $avg_quality = if ($QualityResults.Count -gt 0) {
        ($QualityResults | Measure-Object -Property quality_score -Average).Average
    } else { 0 }
    
    # Calculate average code documentation ratio
    $avg_code_doc = if ($CodeDocResults.Count -gt 0) {
        ($CodeDocResults | Measure-Object -Property documentation_ratio -Average).Average
    } else { 0 }
    
    # Quality bonus/penalty
    $quality_adjustment = ($avg_quality - 50) * 0.5
    $code_doc_adjustment = ($avg_code_doc - 30) * 0.3
    
    $final_score = [Math]::Max(0, $base_score - $missing_critical_deduction - $missing_other_deduction + $quality_adjustment + $code_doc_adjustment)
    
    $grade = if ($final_score -ge 90) { "A" }
             elseif ($final_score -ge 80) { "B" }
             elseif ($final_score -ge 70) { "C" }
             elseif ($final_score -ge 60) { "D" }
             else { "F" }
    
    return @{
        score = [Math]::Round($final_score, 0)
        grade = $grade
        avg_quality = [Math]::Round($avg_quality, 1)
        avg_code_doc = [Math]::Round($avg_code_doc, 1)
    }
}

# Main audit execution
try {
    Write-AuditLog "Starting documentation audit" "INFO"
    
    # Check for required documentation
    $doc_check = Test-RequiredDocumentation $ProjectRoot
    $AuditResults.documentation_files = $doc_check.found
    $AuditResults.missing_documentation = $doc_check.missing
    
    Write-AuditLog "Found $($doc_check.found.Count) documentation files, missing $($doc_check.missing.Count)" "INFO"
    
    # Analyze documentation quality
    $quality_results = Test-DocumentationQuality $doc_check.found $ProjectRoot
    $AuditResults.documentation_quality = $quality_results
    
    # Check code documentation
    $code_doc_results = Test-CodeDocumentation $ProjectRoot
    $AuditResults.code_documentation = $code_doc_results
    
    # Calculate overall score
    $missing_critical = ($doc_check.missing | Where-Object { $_.critical }).Count
    $score_info = Calculate-DocumentationScore $doc_check.found.Count $missing_critical $doc_check.missing.Count $quality_results $code_doc_results
    
    $AuditResults.overall_score = $score_info.score
    $AuditResults.grade = $score_info.grade
    
    # Determine deployment approval
    $AuditResults.deployment_approved = ($missing_critical -eq 0) -and ($score_info.score -ge 70)
    
    # Generate recommendations
    $recommendations = @()
    
    if ($missing_critical -gt 0) {
        $recommendations += "Create missing critical documentation files"
    }
    
    if ($doc_check.missing.Count -gt 2) {
        $recommendations += "Add comprehensive documentation for better user experience"
    }
    
    if ($score_info.avg_quality -lt 60) {
        $recommendations += "Improve documentation quality with more examples and better structure"
    }
    
    if ($score_info.avg_code_doc -lt 30) {
        $recommendations += "Add more inline documentation comments to code"
    }
    
    if ($recommendations.Count -eq 0) {
        $recommendations += "Documentation is in good condition - consider regular updates"
    }
    
    $AuditResults.recommendations = $recommendations
    
    # Display results
    Write-Host ""
    Write-Host "DOCUMENTATION AUDIT RESULTS" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host "Overall Score: $($score_info.score)/100 ($($score_info.grade))" -ForegroundColor $(if ($score_info.grade -match "A|B") { "Green" } elseif ($score_info.grade -eq "C") { "Yellow" } else { "Red" })
    Write-Host "Documentation Files Found: $($doc_check.found.Count)" -ForegroundColor White
    Write-Host "Missing Documentation: $($doc_check.missing.Count)" -ForegroundColor $(if ($doc_check.missing.Count -eq 0) { "Green" } else { "Red" })
    Write-Host "Missing Critical Docs: $missing_critical" -ForegroundColor $(if ($missing_critical -eq 0) { "Green" } else { "Red" })
    Write-Host "Average Quality Score: $($score_info.avg_quality)/100" -ForegroundColor $(if ($score_info.avg_quality -ge 70) { "Green" } elseif ($score_info.avg_quality -ge 50) { "Yellow" } else { "Red" })
    Write-Host "Average Code Documentation: $($score_info.avg_code_doc)%" -ForegroundColor $(if ($score_info.avg_code_doc -ge 50) { "Green" } elseif ($score_info.avg_code_doc -ge 30) { "Yellow" } else { "Red" })
    Write-Host "Deployment Approved: $(if ($AuditResults.deployment_approved) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($AuditResults.deployment_approved) { "Green" } else { "Red" })
    
    if ($doc_check.missing.Count -gt 0) {
        Write-Host ""
        Write-Host "MISSING DOCUMENTATION:" -ForegroundColor Red
        foreach ($missing in $doc_check.missing) {
            $criticality = if ($missing.critical) { "CRITICAL" } else { "OPTIONAL" }
            Write-Host "  [$criticality] $($missing.name): $($missing.description)" -ForegroundColor $(if ($missing.critical) { "Red" } else { "Yellow" })
        }
    }
    
    if ($quality_results.Count -gt 0) {
        Write-Host ""
        Write-Host "DOCUMENTATION QUALITY (top 5):" -ForegroundColor Green
        $quality_results | Sort-Object quality_score -Descending | Select-Object -First 5 | ForEach-Object {
            Write-Host "  $($_.name): $($_.quality_score)/100 ($($_.word_count) words, $($_.section_count) sections)" -ForegroundColor Gray
        }
    }
    
    if ($code_doc_results.Count -gt 0) {
        Write-Host ""
        Write-Host "CODE DOCUMENTATION (files with lowest coverage):" -ForegroundColor Yellow
        $code_doc_results | Sort-Object documentation_ratio | Select-Object -First 3 | ForEach-Object {
            Write-Host "  $($_.file): $($_.documentation_ratio)% ($($_.doc_comments) doc comments, $($_.function_count + $_.struct_count + $_.enum_count) items)" -ForegroundColor Gray
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
    Write-AuditLog "Documentation audit completed" "SUCCESS"
    
    # Exit with appropriate code
    if ($AuditResults.deployment_approved) {
        exit 0
    } else {
        Write-AuditLog "Documentation issues found - review required before deployment" "WARN"
        exit 1
    }
    
} catch {
    Write-AuditLog "Documentation audit failed: $($_.Exception.Message)" "ERROR"
    exit 1
}