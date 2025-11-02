# HTTP E2E Tests for OMEGA Native Runner
param(
    [int]$Port = 8091,
    [string]$SourceFile = "examples\omega_api_server.mega"
)

$ErrorActionPreference = "Stop"

# Prepare environment
$env:OMEGA_SERVER_PORT = "$Port"
$env:OMEGA_SERVER_IP = "localhost"
$env:OMEGA_RATE_LIMIT = "5"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$omegaCli = Join-Path $ProjectRoot "omega.ps1"

if (-not (Test-Path $omegaCli)) {
    throw "omega.ps1 not found at $omegaCli"
}

# Ensure no previous runner is still bound on the same port
try {
    $stopScript = Join-Path $ProjectRoot "scripts\stop_omega_runner.ps1"
    if (Test-Path $stopScript) {
        Write-Host "[E2E] Ensuring previous runner is stopped on port $Port..." -ForegroundColor Yellow
        & $stopScript -Port $Port | Out-Host
        Start-Sleep -Milliseconds 300
    }
} catch { Write-Host "[E2E] Stop runner preflight warning: $($_.Exception.Message)" -ForegroundColor DarkYellow }

# Start server as background process
Write-Host "[E2E] Starting server on port $Port..." -ForegroundColor Cyan
$psi = New-Object System.Diagnostics.ProcessStartInfo
$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue)
if ($pwsh -and $pwsh.Source) { $psi.FileName = $pwsh.Source } else { $psi.FileName = "powershell.exe" }
$psi.Arguments = "-ExecutionPolicy Bypass -File `"$omegaCli`" run `"$SourceFile`""
$psi.WorkingDirectory = $ProjectRoot
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
$null = $proc.Start()

# Wait for listener
$baseUrl = "http://localhost:$Port/"
$healthUrl = $baseUrl + "health"

function Wait-ServerReady {
    param([int]$TimeoutMs = 5000)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try { Add-Type -AssemblyName System.Net.Http } catch { }
    $client = New-Object System.Net.Http.HttpClient
    while ($sw.ElapsedMilliseconds -lt $TimeoutMs) {
        try {
            $resp = $client.GetAsync($healthUrl).GetAwaiter().GetResult()
            if ([int]$resp.StatusCode -eq 200) { $client.Dispose(); return $true }
        } catch { }
        Start-Sleep -Milliseconds 250
    }
    $client.Dispose()
    return $false
}

if (-not (Wait-ServerReady -TimeoutMs 8000)) {
    Write-Host "[E2E] Server failed to start" -ForegroundColor Red
    try { $proc.Kill() } catch { }
    try { $proc.WaitForExit(2000) } catch { }
    $out = ""
    $err = ""
    try { $out = $proc.StandardOutput.ReadToEnd() } catch { }
    try { $err = $proc.StandardError.ReadToEnd() } catch { }
    if ($out) { Write-Host $out }
    if ($err) { Write-Host $err }
    exit 1
}

Write-Host "[E2E] Server is ready at $healthUrl" -ForegroundColor Green

# Test GET /health (allow initial 429 due to rate limiting = 1)
$attempts = 0
$r1 = $null
while ($attempts -lt 3) {
    try {
        $r1 = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -Method GET
        if ($r1.StatusCode -eq 200) { break }
        if ($r1.StatusCode -eq 429) {
            Write-Host "[E2E] Initial GET /health hit rate limit, waiting for window reset..." -ForegroundColor DarkYellow
            Start-Sleep -Milliseconds 1100
            $attempts++
            continue
        }
        throw "GET /health failed: $($r1.StatusCode)"
    } catch {
        # Handle non-2xx responses where Invoke-WebRequest throws
        $resp = $null
        try { $resp = $_.Exception.Response } catch { }
        if ($resp -and $resp.StatusCode.Value__ -eq 429) {
            Write-Host "[E2E] Initial GET /health hit rate limit (429), waiting..." -ForegroundColor DarkYellow
            Start-Sleep -Milliseconds 1100
            $attempts++
            continue
        }
        throw
    }
}
if (-not $r1 -or $r1.StatusCode -ne 200) { throw "GET /health failed after retries: $($r1.StatusCode)" }
$ct1 = $r1.Headers["Content-Type"]
if (-not $ct1 -or ($ct1 -notlike "application/json*")) { throw "GET /health invalid Content-Type: $ct1" }
$body1 = $r1.Content | ConvertFrom-Json
if ($body1.status -ne "ok") { throw "GET /health invalid body: $($r1.Content)" }

# Test GET /version
$r2 = Invoke-WebRequest -UseBasicParsing -Uri ($baseUrl + "version") -Method GET
if ($r2.StatusCode -ne 200) { throw "GET /version failed: $($r2.StatusCode)" }
$ct2 = $r2.Headers["Content-Type"]
if (-not $ct2 -or ($ct2 -notlike "application/json*")) { throw "GET /version invalid Content-Type: $ct2" }
$body2 = $r2.Content | ConvertFrom-Json
if (-not $body2.compiler_version) { throw "GET /version missing compiler_version" }

# Test GET /info and check requests_handled increments + structure validation
$r3 = Invoke-WebRequest -UseBasicParsing -Uri ($baseUrl + "info") -Method GET
if ($r3.StatusCode -ne 200) { throw "GET /info failed" }
$ct3 = $r3.Headers["Content-Type"]
if (-not $ct3 -or ($ct3 -notlike "application/json*")) { throw "GET /info invalid Content-Type: $ct3" }
$info1 = $r3.Content | ConvertFrom-Json
if (-not $info1.server -or -not $info1.version -or -not $info1.started_at_ms -or -not $info1.port) { throw "GET /info missing required fields: $($r3.Content)" }
if ([int]$info1.port -ne [int]$Port) { throw "GET /info port mismatch: expected $Port got $($info1.port)" }
Write-Host "[E2E] /info response: $($r3.Content)" -ForegroundColor DarkGray
if ($info1.rate_limit) { Write-Host "[E2E] Runner rate_limit reported: $($info1.rate_limit)" -ForegroundColor Yellow } else { Write-Host "[E2E] Runner did not report rate_limit" -ForegroundColor Yellow }
Start-Sleep -Milliseconds 150
$r4 = Invoke-WebRequest -UseBasicParsing -Uri ($baseUrl + "info") -Method GET
$info2 = $r4.Content | ConvertFrom-Json
if ([int]$info2.requests_handled -le [int]$info1.requests_handled) { throw "requests_handled did not increase" }

# Allow rate-limit window to reset before compile
Start-Sleep -Milliseconds 1200

# Test POST /compile and Content-Type
$sampleSource = @"
import std/net/http

fn main() {
  // server stub
}
"@
$r5 = Invoke-WebRequest -UseBasicParsing -Uri ($baseUrl + "compile") -Method POST -Body $sampleSource -ContentType "text/plain"
if ($r5.StatusCode -ne 200) { throw "POST /compile failed" }
$ct5 = $r5.Headers["Content-Type"]
if (-not $ct5 -or ($ct5 -notlike "application/json*")) { throw "POST /compile invalid Content-Type: $ct5" }
$body5 = $r5.Content | ConvertFrom-Json
if (-not $body5.success) { throw "POST /compile response invalid" }

# Rate limiting: send rapid requests and expect 429
try { Add-Type -AssemblyName System.Net.Http } catch { }
$client = New-Object System.Net.Http.HttpClient
# Fire a burst of concurrent requests to reliably exceed any reasonable per-second limit
$tasks = @()
for ($i = 0; $i -lt 20; $i++) {
    $tasks += $client.GetAsync($healthUrl)
}
[System.Threading.Tasks.Task]::WaitAll($tasks)
$responses = $tasks | ForEach-Object { $_.Result }
$client.Dispose()
$limit429 = ($responses | Where-Object { [int]$_.StatusCode -eq 429 }).Count
if ($limit429 -lt 1) { throw "Rate limiting not enforced (429 count=$limit429)" }

Write-Host "[E2E] All tests passed!" -ForegroundColor Green

# Cleanup
try { $proc.Kill() } catch { }
exit 0