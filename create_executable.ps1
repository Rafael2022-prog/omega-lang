# OMEGA Executable Builder
# Creates a proper omega.exe binary

Write-Host "🔨 Creating OMEGA executable binary..." -ForegroundColor Cyan

# Create executable directory
$execDir = "R:\OMEGA\bin"
if (-not (Test-Path $execDir)) {
    New-Item -ItemType Directory -Path $execDir -Force | Out-Null
}

# Compute version from central VERSION file with CI/local metadata
$versionBase = "1.2.1"
try {
    $verFile = "R:\OMEGA\VERSION"
    if (Test-Path $verFile) { $versionBase = (Get-Content $verFile -ErrorAction SilentlyContinue | Select-Object -First 1).Trim() }
} catch { }
$versionMeta = $null
if ($env:GITHUB_RUN_NUMBER -or $env:GITHUB_SHA) {
    $run = $env:GITHUB_RUN_NUMBER
    $sha = $env:GITHUB_SHA
    if ($sha) { $sha = $sha.Substring(0,7) }
    $parts = @()
    if ($run) { $parts += "ci.$run" }
    if ($sha) { $parts += "sha.$sha" }
    $versionMeta = ($parts -join ".")
} else {
    $versionMeta = "local." + (Get-Date -Format "yyyyMMdd.HHmm")
}
$versionStr = $versionBase
if ($versionMeta) { $versionStr = "$versionBase-$versionMeta" }

# Create the main executable content
$executableContent = @"
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;

namespace OmegaCompiler
{
    class Program
    {
        static void Main(string[] args)
        {
            var version = "${versionStr}";
            var buildDate = DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss");
            
            if (args.Length == 0 || args[0] == "--help" || args[0] == "-h")
            {
                ShowHelp();
                return;
            }
            
            if (args[0] == "--version" || args[0] == "-v")
            {
                Console.WriteLine($"OMEGA Compiler v{version}");
                Console.WriteLine("Universal Blockchain Programming Language");
                Console.WriteLine("Write Once, Deploy Everywhere");
                Console.WriteLine();
                Console.WriteLine($"Build Date: {buildDate}");
                Console.WriteLine("Platform: Windows x64");
                return;
            }
            
            // Execute OMEGA compiler via PowerShell wrapper
            var omegaRoot = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            var omegaScript = Path.Combine(omegaRoot, "omega.ps1");
            
            var startInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = $"-ExecutionPolicy Bypass -File \"{omegaScript}\" {string.Join(" ", args)}",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = false
            };
            
            try
            {
                using (var process = Process.Start(startInfo))
                {
                    var output = process.StandardOutput.ReadToEnd();
                    var error = process.StandardError.ReadToEnd();
                    
                    if (!string.IsNullOrEmpty(output))
                        Console.Write(output);
                    
                    if (!string.IsNullOrEmpty(error))
                        Console.Error.Write(error);
                    
                    process.WaitForExit();
                    Environment.Exit(process.ExitCode);
                }
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Error executing OMEGA compiler: {ex.Message}");
                Environment.Exit(1);
            }
        }
        
        static void ShowHelp()
        {
            Console.WriteLine("OMEGA Compiler");
            Console.WriteLine();
            Console.WriteLine("Usage: omega [COMMAND] [OPTIONS]");
            Console.WriteLine();
            Console.WriteLine("Commands:");
            Console.WriteLine("  build      Build OMEGA project for specified target");
            Console.WriteLine("  init       Initialize new OMEGA project");
            Console.WriteLine("  deploy     Deploy smart contract to blockchain");
            Console.WriteLine("  test       Run project tests");
            Console.WriteLine();
            Console.WriteLine("Options:");
            Console.WriteLine("  --target   Target blockchain (evm, solana, cosmos)");
            Console.WriteLine("  --version  Show version information");
            Console.WriteLine("  --help     Show this help message");
            Console.WriteLine();
            Console.WriteLine("Examples:");
            Console.WriteLine("  omega build --target evm");
            Console.WriteLine("  omega init my-dapp");
            Console.WriteLine("  omega deploy --target solana");
        }
    }
}
"@

# Save C# source
$csFile = Join-Path $execDir "omega.cs"
$executableContent | Out-File -FilePath $csFile -Encoding UTF8

Write-Host "✅ C# source created: $csFile" -ForegroundColor Green

# Try to compile with .NET Framework compiler
$cscPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\csc.exe"
if (-not (Test-Path $cscPath)) {
    $cscPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\Roslyn\csc.exe"
}
if (-not (Test-Path $cscPath)) {
    $cscPath = "${env:WINDIR}\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
}

$outputExe = Join-Path $execDir "omega.exe"

if (Test-Path $cscPath) {
    Write-Host "🔧 Compiling with C# compiler..." -ForegroundColor Yellow
    
    $compileArgs = @(
        "/out:$outputExe",
        "/target:exe",
        "/optimize+",
        "/platform:x64",
        $csFile
    )
    
    $process = Start-Process -FilePath $cscPath -ArgumentList $compileArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0 -and (Test-Path $outputExe)) {
        Write-Host "✅ Successfully created omega.exe!" -ForegroundColor Green
        Write-Host "📍 Location: $outputExe" -ForegroundColor Cyan
        
        # Test the executable
        Write-Host "🧪 Testing executable..." -ForegroundColor Yellow
        & $outputExe --version
        
        # Copy to main directory for easy access
        $mainExe = "R:\OMEGA\omega.exe"
        Copy-Item $outputExe $mainExe -Force
        Write-Host "✅ Copied to: $mainExe" -ForegroundColor Green
        
    } else {
        Write-Host "❌ Compilation failed!" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  C# compiler not found. Creating PowerShell executable instead..." -ForegroundColor Yellow
    
    # Create PowerShell-based executable using ps2exe if available
    if (Get-Command ps2exe -ErrorAction SilentlyContinue) {
        $ps1File = "R:\OMEGA\omega_executable.ps1"
        
        $ps1Content = @"
param([string[]]$Arguments)

$version = "${versionStr}"
$buildDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

if ($Arguments.Length -eq 0 -or $Arguments[0] -eq "--help" -or $Arguments[0] -eq "-h") {
    Write-Host "OMEGA Compiler v$version"
    Write-Host ""
    Write-Host "Usage: omega [COMMAND] [OPTIONS]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  build      Build OMEGA project for specified target"
    Write-Host "  init       Initialize new OMEGA project"
    Write-Host "  deploy     Deploy smart contract to blockchain"
    Write-Host "  test       Run project tests"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --target   Target blockchain (evm, solana, cosmos)"
    Write-Host "  --version  Show version information"
    Write-Host "  --help     Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  omega build --target evm"
    Write-Host "  omega init my-dapp"
    Write-Host "  omega deploy --target solana"
    return
}

if ($Arguments[0] -eq "--version" -or $Arguments[0] -eq "-v") {
    Write-Host "OMEGA Compiler v$version"
    Write-Host "Universal Blockchain Programming Language"
    Write-Host "Write Once, Deploy Everywhere"
    Write-Host ""
    Write-Host "Build Date: $buildDate"
    Write-Host "Platform: Windows x64"
    return
}

# Execute the main OMEGA script
$omegaScript = Join-Path $PSScriptRoot "omega.ps1"
& $omegaScript @Arguments
"@
        
        $ps1Content | Out-File -FilePath $ps1File -Encoding UTF8
        
        try {
            ps2exe -inputFile $ps1File -outputFile $outputExe -runtime40 -x64 -noConsole:$false
            if (Test-Path $outputExe) {
                Write-Host "✅ PowerShell executable created!" -ForegroundColor Green
                Copy-Item $outputExe "R:\OMEGA\omega.exe" -Force
            }
        } catch {
            Write-Host "❌ ps2exe failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ No suitable compiler found. Please install Visual Studio or .NET SDK." -ForegroundColor Red
        Write-Host "💡 Alternative: Install ps2exe module with 'Install-Module ps2exe'" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎯 OMEGA Executable Builder Complete!" -ForegroundColor Cyan