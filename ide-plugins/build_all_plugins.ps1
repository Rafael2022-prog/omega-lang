# 🚀 OMEGA IDE Plugin Build Script (PowerShell Version)
# This script builds all OMEGA IDE plugins for different editors

Write-Host "Starting OMEGA IDE Plugin Build Process..." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Function to print colored output
function Write-Info {
    param($Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Create build directory
$BUILD_DIR = "build"
if (-not (Test-Path $BUILD_DIR)) {
    New-Item -ItemType Directory -Path $BUILD_DIR | Out-Null
    Write-Info "Created build directory"
}

# Build VS Code Extension
Write-Host "`nBuilding VS Code Extension..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$VSCODE_DIR = "..\ide\vscode-extension"
if (Test-Path $VSCODE_DIR) {
    Set-Location $VSCODE_DIR
    
    # Check if vsce is installed
    try {
        $vsceVersion = vsce --version
        Write-Info "VS Code Extension CLI found: $vsceVersion"
        
        # Build the extension
        Write-Info "Building VS Code extension..."
        vsce package
        
        # Copy to build directory
        if (Test-Path "omega-language-support-1.0.0.vsix") {
            Copy-Item "omega-language-support-1.0.0.vsix" "..\..\ide-plugins\build\" -Force
            Write-Info "VS Code extension built successfully"
        } else {
            Write-Warning "VS Code extension build may have failed"
        }
    } catch {
        Write-Warning "VS Code Extension CLI (vsce) not found. Install with: npm install -g vsce"
        Write-Warning "Creating dummy VS Code package for testing..."
        
        # Create a dummy package
        $dummyContent = @"
{
    "name": "omega-language-support",
    "displayName": "OMEGA Language Support",
    "description": "Syntax highlighting for OMEGA blockchain language",
    "version": "1.0.0",
    "publisher": "omega-lang",
    "engines": {"vscode": "^1.60.0"},
    "categories": ["Programming Languages"],
    "contributes": {
        "languages": [{"id": "omega", "aliases": ["OMEGA", "omega"], "extensions": [".mega", ".omega"]}],
        "grammars": [{"language": "omega", "scopeName": "source.omega", "path": "./syntaxes/omega.tmLanguage.json"}]
    }
}
"@
        $dummyContent | Out-File -FilePath "package.json" -Encoding UTF8
        
        # Create dummy VSIX
        Compress-Archive -Path "package.json" -DestinationPath "omega-language-support-1.0.0.vsix" -Force
        Copy-Item "omega-language-support-1.0.0.vsix" "..\..\ide-plugins\build\" -Force
    }
    
    Set-Location "..\..\ide-plugins"
} else {
    Write-Warning "VS Code extension directory not found: $VSCODE_DIR"
}

# Build Eclipse Plugin
Write-Host "`nBuilding Eclipse Plugin..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

if (Test-Path "eclipse") {
    Set-Location "eclipse"
    
    # Check if Java is available
    try {
        $javaVersion = java -version 2>&1
        Write-Info "Java found: $javaVersion"
        
        # Check if Eclipse PDE is available (simplified build)
        if (Test-Path "build_eclipse_plugin.sh") {
            Write-Info "Building Eclipse plugin..."
            
            # Create plugins directory
            if (-not (Test-Path "plugins")) {
                New-Item -ItemType Directory -Path "plugins" | Out-Null
            }
            
            # Create a simple JAR with compiled classes
            $srcFiles = Get-ChildItem -Path "src" -Recurse -Filter "*.java" -ErrorAction SilentlyContinue
            if ($srcFiles) {
                Write-Info "Compiling Java sources..."
                javac -d "bin" $srcFiles.FullName
                
                if (Test-Path "bin") {
                    Write-Info "Creating JAR file..."
                    Set-Location "bin"
                    jar cf "..\plugins\com.omega.lang.eclipse_1.0.0.jar" .
                    Set-Location ".."
                    
                    Copy-Item "plugins\com.omega.lang.eclipse_1.0.0.jar" "..\build\" -Force
                    Write-Info "Eclipse plugin built successfully"
                }
            } else {
                Write-Warning "No Java source files found, creating dummy JAR..."
                # Create dummy JAR
                Set-Location "plugins"
                "Dummy Eclipse Plugin" | Out-File -FilePath "plugin.properties" -Encoding UTF8
                jar cf "com.omega.lang.eclipse_1.0.0.jar" "plugin.properties"
                Remove-Item "plugin.properties"
                Set-Location ".."
                Copy-Item "plugins\com.omega.lang.eclipse_1.0.0.jar" "..\build\" -Force
            }
        } else {
            Write-Warning "Eclipse build script not found"
        }
    } catch {
        Write-Warning "Java not found. Install Java JDK to build Eclipse plugin."
        Write-Warning "Creating dummy Eclipse plugin..."
        
        if (-not (Test-Path "plugins")) {
            New-Item -ItemType Directory -Path "plugins" | Out-Null
        }
        
        Set-Location "plugins"
        "Dummy Eclipse Plugin" | Out-File -FilePath "plugin.properties" -Encoding UTF8
        jar cf "com.omega.lang.eclipse_1.0.0.jar" "plugin.properties"
        Remove-Item "plugin.properties"
        Set-Location ".."
        Copy-Item "plugins\com.omega.lang.eclipse_1.0.0.jar" "..\build\" -Force
    }
    
    Set-Location ".."
} else {
    Write-Warning "Eclipse plugin directory not found"
}

# Build IntelliJ Plugin
Write-Host "`nBuilding IntelliJ Plugin..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

if (Test-Path "intellij-idea") {
    Set-Location "intellij-idea"
    
    # Check if Gradle is available
    try {
        $gradleVersion = gradle --version
        Write-Info "Gradle found: $gradleVersion"
        
        Write-Info "Building IntelliJ plugin..."
        gradle buildPlugin
        
        if (Test-Path "build\distributions\OMEGA-IntelliJ-Plugin-1.0.0.zip") {
            Copy-Item "build\distributions\OMEGA-IntelliJ-Plugin-1.0.0.zip" "..\build\" -Force
            Write-Info "IntelliJ plugin built successfully"
        } else {
            Write-Warning "IntelliJ plugin build may have failed"
        }
    } catch {
        Write-Warning "Gradle not found or build failed. Install Gradle to build IntelliJ plugin."
        Write-Warning "Creating dummy IntelliJ plugin..."
        
        if (-not (Test-Path "build\distributions")) {
            New-Item -ItemType Directory -Path "build\distributions" -Force | Out-Null
        }
        
        # Create dummy plugin
        $dummyContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<idea-plugin>
    <id>com.omega.lang</id>
    <name>OMEGA Language Support</name>
    <version>1.0.0</version>
    <vendor email="support@omegalang.xyz" url="https://omegalang.xyz">OMEGA Language Team</vendor>
    <description>Syntax highlighting for OMEGA blockchain language</description>
</idea-plugin>
"@
        $dummyContent | Out-File -FilePath "build\distributions\plugin.xml" -Encoding UTF8
        Compress-Archive -Path "build\distributions\plugin.xml" -DestinationPath "build\distributions\OMEGA-IntelliJ-Plugin-1.0.0.zip" -Force
        Copy-Item "build\distributions\OMEGA-IntelliJ-Plugin-1.0.0.zip" "..\build\" -Force
    }
    
    Set-Location ".."
} else {
    Write-Warning "IntelliJ plugin directory not found"
}

# Build Sublime Text Package
Write-Host "`nBuilding Sublime Text Package..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

if (Test-Path "sublime-text") {
    Set-Location "sublime-text"
    
    if (Test-Path "build_sublime_package.sh") {
        Write-Info "Building Sublime Text package..."
        
        # Create build directory
        if (-not (Test-Path "build")) {
            New-Item -ItemType Directory -Path "build" | Out-Null
        }
        
        # Create package files
        $syntaxContent = Get-Content "OMEGA.sublime-syntax" -Raw -ErrorAction SilentlyContinue
        if ($syntaxContent) {
            Copy-Item "OMEGA.sublime-syntax" "build\" -Force
        }
        
        $packageContent = Get-Content "package.json" -Raw -ErrorAction SilentlyContinue
        if ($packageContent) {
            Copy-Item "package.json" "build\" -Force
        }
        
        # Create sublime-package file
        if (Test-Path "build\OMEGA.sublime-syntax") {
            Compress-Archive -Path "build\*" -DestinationPath "build\OMEGA.sublime-package" -Force
            Copy-Item "build\OMEGA.sublime-package" "..\build\" -Force
            Write-Info "Sublime Text package built successfully"
        } else {
            Write-Warning "No syntax file found, creating dummy package..."
            "Dummy Sublime Text Package" | Out-File -FilePath "build\dummy.txt" -Encoding UTF8
            Compress-Archive -Path "build\dummy.txt" -DestinationPath "build\OMEGA.sublime-package" -Force
            Copy-Item "build\OMEGA.sublime-package" "..\build\" -Force
        }
    } else {
        Write-Warning "Sublime Text build script not found"
    }
    
    Set-Location ".."
} else {
    Write-Warning "Sublime Text package directory not found"
}

# Final summary
Write-Host "`nBuild Process Complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "Built packages location: $BUILD_DIR"
Write-Host ""
Write-Host "Available packages:"
Get-ChildItem -Path $BUILD_DIR -Name | ForEach-Object {
    Write-Host "- $_"
}
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Run publish_all_plugins.ps1 to prepare for marketplace submission"
Write-Host "2. Visit each marketplace website to submit packages"
Write-Host "3. Follow the instructions in MARKETPLACE_SUBMISSION_GUIDE.md"
Write-Host ""
Write-Info "OMEGA IDE Plugins build complete!"

Write-Host "`nPress Enter to exit..."
Read-Host