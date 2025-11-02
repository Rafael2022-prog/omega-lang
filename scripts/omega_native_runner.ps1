# OMEGA Native Runner (Temporary)
# Menyediakan server HTTP sederhana untuk menjalankan contoh Omega API
# Endpoint: /health, /compile, /version, /info
# Catatan: Menggunakan .NET HttpListener; hanya bind ke localhost untuk menghindari urlacl.

param(
    [string]$SourceFile = "examples\omega_api_server.mega",
    [string]$BindHost,
    [int]$Port,
    [int]$RateLimit
)

Write-Host "[Runner] Starting OMEGA Native Runner..." -ForegroundColor Cyan

# Resolve project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Determine version from package.json (fallback to 1.1.0)
$CompilerVersion = "1.1.0"
try {
    $pkgPath = Join-Path $ProjectRoot "package.json"
    if (Test-Path $pkgPath) {
        $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
        if ($pkg.version) { $CompilerVersion = $pkg.version }
    }
} catch { }

# Environment configs (with CLI overrides)
$envPort = $env:OMEGA_SERVER_PORT
if ($Port -gt 0) { $envPort = "$Port" }
if (-not $envPort -or -not ($envPort -match '^[0-9]+$')) { $envPort = "8080" }
$envAddr = $env:OMEGA_SERVER_IP
if ($BindHost) { $envAddr = $BindHost }
if (-not $envAddr -or $envAddr.Trim() -eq "") { $envAddr = "127.0.0.1" }

# HttpListener prefix must be a concrete host, not 0.0.0.0
# Gunakan 'localhost' untuk menghindari konflik urlacl pada 127.0.0.1
$hostForPrefix = if ($envAddr -eq "0.0.0.0") { "localhost" } else { $envAddr }
$prefix = "http://${hostForPrefix}:${envPort}/"

# Status
$RequestsHandled = 0
$StartTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

# Initialize listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Clear()
$listener.Prefixes.Add($prefix)
try {
    $listener.Start()
} catch {
    if ($hostForPrefix -ne "localhost") {
        Write-Host "[Runner] Failed on $hostForPrefix, retrying on localhost..." -ForegroundColor Yellow
        try {
            if ($listener -and $listener.Prefixes) { $listener.Prefixes.Clear() } else { $listener = New-Object System.Net.HttpListener }
        } catch { $listener = New-Object System.Net.HttpListener }
        $hostForPrefix = "localhost"
        $prefix = "http://${hostForPrefix}:${envPort}/"
        $listener.Prefixes.Add($prefix)
        $listener.Start()
    } else {
        Write-Host "[Runner] Failed to start HttpListener on $prefix. Try running as admin or use localhost." -ForegroundColor Red
        throw
    }
}

Write-Host "[Runner] Listening at $prefix" -ForegroundColor Green
Write-Host "[Runner] Preview URL: ${prefix}health" -ForegroundColor Yellow
Write-Host "[Runner] Using SourceFile: $SourceFile" -ForegroundColor Gray
Write-Host "[Runner] Compiler Version: $CompilerVersion" -ForegroundColor Gray
Write-Host "[Runner] Address: $envAddr (prefix host: $hostForPrefix), Port: $envPort" -ForegroundColor Gray

# Rate limiting (simple sliding window)
$RateLimitPerSecond = 10
try {
    if ($env:OMEGA_RATE_LIMIT -match '^[0-9]+$') { $RateLimitPerSecond = [int]$env:OMEGA_RATE_LIMIT }
} catch { }
if ($RateLimit -gt 0) { $RateLimitPerSecond = $RateLimit }
Write-Host "[Runner] RateLimitPerSecond = $RateLimitPerSecond" -ForegroundColor Gray
# Fixed 1-second window counters
$WindowStartMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$WindowCount = 0

# Helper: write JSON response (with optional headers)
function Write-JsonResponse($context, [int]$statusCode, [string]$bodyText, $headers = $null) {
    $resp = $context.Response
    if ($headers) {
        foreach ($k in $headers.Keys) {
            try { $resp.Headers[$k] = [string]$headers[$k] } catch { }
        }
    }
    $resp.StatusCode = $statusCode
    $resp.ContentType = "application/json; charset=utf-8"
    $buf = [System.Text.Encoding]::UTF8.GetBytes($bodyText)
    $resp.ContentLength64 = $buf.Length
    $stream = $resp.OutputStream
    $stream.Write($buf, 0, $buf.Length)
    $stream.Close()
}

# Simple stats from source text (fallback for /compile when running native)
function Get-SourceStats([string]$sourceText) {
    $tokens = ($sourceText -split "\s+", [System.StringSplitOptions]::RemoveEmptyEntries)
    $imports = [regex]::Matches($sourceText, "\bimport\b", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Count
    return [PSCustomObject]@{ tokens_count = $tokens.Length; imports_count = $imports }
}

# Main loop
try {
    while ($true) {
        try {
            $context = $listener.GetContext()
        } catch {
            Write-Host "[Runner] Listener closed or error: $($_.Exception.Message)" -ForegroundColor Yellow
            break
        }
        $RequestsHandled++
        # Rate limit check (fixed window 1s)
        $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        if ($nowMs -ge ($WindowStartMs + 1000)) {
            $WindowStartMs = $nowMs
            $WindowCount = 0
        }
        if ($WindowCount -ge $RateLimitPerSecond) {
            Write-Host "[RL] 429 rate_limited (count=$WindowCount, limit=$RateLimitPerSecond)" -ForegroundColor Yellow
            $resetMs = [Math]::Max(0, ($WindowStartMs + 1000) - $nowMs)
            $json = @{ error = "rate_limited"; limit_per_sec = $RateLimitPerSecond } | ConvertTo-Json -Compress
            $retrySec = [Math]::Max(1, [int][Math]::Ceiling($resetMs / 1000.0))
            $headers = @{ "X-RateLimit-Limit" = "$RateLimitPerSecond"; "X-RateLimit-Remaining" = "0"; "X-RateLimit-Reset" = "$resetMs"; "Retry-After" = "$retrySec" }
            Write-JsonResponse $context 429 $json $headers
            continue
        }
        $WindowCount++
        $resetMs = [Math]::Max(0, ($WindowStartMs + 1000) - $nowMs)
        $remaining = [Math]::Max(0, $RateLimitPerSecond - $WindowCount)
        $DefaultHeaders = @{ "X-RateLimit-Limit" = "$RateLimitPerSecond"; "X-RateLimit-Remaining" = "$remaining"; "X-RateLimit-Reset" = "$resetMs" }

        $req = $context.Request
        $path = $req.Url.AbsolutePath
        $method = $req.HttpMethod
        $ts = (Get-Date).ToString("HH:mm:ss")
        Write-Host "[$ts] $method $path" -ForegroundColor White

        if ($method -eq "GET" -and ($path -eq "/" -or $path -eq "/health")) {
            $json = @{ status = "ok"; server = "omega-native-runner"; version = $CompilerVersion } | ConvertTo-Json -Compress
            Write-JsonResponse $context 200 $json $DefaultHeaders
            continue
        }
        if ($method -eq "GET" -and $path -eq "/version") {
            $json = @{ compiler_version = $CompilerVersion } | ConvertTo-Json -Compress
            Write-JsonResponse $context 200 $json $DefaultHeaders
            continue
        }
        if ($method -eq "GET" -and $path -eq "/info") {
            $json = @{ server = "omega-native-runner"; version = $CompilerVersion; requests_handled = $RequestsHandled; started_at_ms = $StartTime; address = $envAddr; port = [int]$envPort; rate_limit = [int]$RateLimitPerSecond } | ConvertTo-Json -Compress
            Write-JsonResponse $context 200 $json $DefaultHeaders
            continue
        }
        if ($method -eq "POST" -and $path -eq "/compile") {
            $reader = New-Object System.IO.StreamReader($req.InputStream, $req.ContentEncoding)
            $body = $reader.ReadToEnd()
            $reader.Close()
            $stats = Get-SourceStats $body
            $jsonObj = [PSCustomObject]@{ success = $true; message = "Parsed source successfully"; tokens_count = $stats.tokens_count; imports_count = $stats.imports_count; version = $CompilerVersion }
            $json = $jsonObj | ConvertTo-Json -Compress
            Write-JsonResponse $context 200 $json $DefaultHeaders
            continue
        }
        # 404
        $json = @{ error = "Not Found"; path = $path } | ConvertTo-Json -Compress
        Write-JsonResponse $context 404 $json $DefaultHeaders
    }
} finally {
    try { if ($listener) { $listener.Stop() } } catch { }
    try { if ($listener) { $listener.Close() } } catch { }
    Write-Host "[Runner] Stopped." -ForegroundColor Gray
}
# (rate limiting initialization moved above)