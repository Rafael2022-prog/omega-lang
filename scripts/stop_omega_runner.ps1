# Stop/Cleanup OMEGA Native Runner
param(
    [int]$Port,
    [string]$BindHost = "localhost"
)

$ErrorActionPreference = "Continue"

# Resolve defaults
if (-not $Port -or $Port -le 0) {
    if ($env:OMEGA_SERVER_PORT -match '^[0-9]+$') { $Port = [int]$env:OMEGA_SERVER_PORT } else { $Port = 8080 }
}

Write-Host "[Stop] Attempting to stop OMEGA runner on $($BindHost):$($Port)" -ForegroundColor Cyan

$script:killed = @()

function Try-KillByPort {
    param([int]$p)
    try {
        $conns = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
        foreach ($c in $conns) {
            $procId = $c.OwningProcess
            if ($procId -and $procId -gt 0) {
                try {
                    $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
                    if ($proc) {
                        Write-Host "[Stop] Killing process by port: PID=$procId Name=$($proc.ProcessName)" -ForegroundColor Yellow
                        Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                        $script:killed += $procId
                    }
                } catch { }
            }
        }
    } catch {
        Write-Host "[Stop] Port-based kill not available: $($_.Exception.Message)" -ForegroundColor DarkYellow
    }
}

function Try-KillByCommandLine {
    try {
        $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
            $_.CommandLine -like "*omega_native_runner.ps1*" -or $_.CommandLine -like "*omega.ps1* run*"
        }
        foreach ($p in $procs) {
            try {
                Write-Host "[Stop] Killing process by command line: PID=$($p.ProcessId)" -ForegroundColor Yellow
                Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
                $script:killed += $p.ProcessId
            } catch { }
        }
    } catch {
        Write-Host "[Stop] CommandLine-based kill failed: $($_.Exception.Message)" -ForegroundColor DarkYellow
    }
}

Try-KillByPort -p $Port
Try-KillByCommandLine

if ($script:killed.Count -gt 0) {
    Write-Host "[Stop] Stopped $($script:killed.Count) process(es): $($script:killed -join ', ')" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[Stop] No matching runner processes found." -ForegroundColor Yellow
    exit 1
}