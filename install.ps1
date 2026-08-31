<#
.SYNOPSIS
    AI Statement of Purpose (SOP) Generator - Installer for Windows
.DESCRIPTION
    Automated setup script for Windows (PowerShell 5.1+ / PowerShell 7+).
#>

$ErrorActionPreference = "Stop"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  🎓 AI Statement of Purpose (SOP) Generator Setup  " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Helper function to ensure Git is installed
function Ensure-GitInstalled {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitVersion = (git --version)
        Write-Host "[✓] Found $gitVersion" -ForegroundColor Green
        return
    }

    Write-Host "[!] Git is not installed. Attempting to install Git automatically..." -ForegroundColor Yellow

    # 1. Try winget (Windows Package Manager)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "[*] Installing Git via winget..." -ForegroundColor Blue
        try {
            winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements --silent
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } catch {
            Write-Host "[!] winget install failed, trying fallback..." -ForegroundColor Yellow
        }
    }

    # 2. Try Chocolatey
    if (-not (Get-Command git -ErrorAction SilentlyContinue) -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "[*] Installing Git via Chocolatey..." -ForegroundColor Blue
        try {
            choco install git -y
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } catch {
            Write-Host "[!] choco install failed, trying fallback..." -ForegroundColor Yellow
        }
    }

    # 3. Try Scoop
    if (-not (Get-Command git -ErrorAction SilentlyContinue) -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "[*] Installing Git via Scoop..." -ForegroundColor Blue
        try {
            scoop install git
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } catch {
            Write-Host "[!] scoop install failed, trying fallback..." -ForegroundColor Yellow
        }
    }

    # 4. Direct Standalone Installer Download fallback
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "[*] Downloading Git installer directly from GitHub..." -ForegroundColor Blue
        $installerUrl = "https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/Git-2.46.0-64-bit.exe"
        $tempInstaller = Join-Path $env:TEMP "GitInstaller.exe"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $installerUrl -OutFile $tempInstaller -UseBasicParsing
            Write-Host "[*] Running silent Git installation..." -ForegroundColor Blue
            Start-Process -FilePath $tempInstaller -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS" -Wait
            Remove-Item -Path $tempInstaller -Force -ErrorAction SilentlyContinue

            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } catch {
            Write-Host "[!] Direct download/install failed." -ForegroundColor Yellow
        }
    }

    # Verify installation
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitVersion = (git --version)
        Write-Host "[✓] Successfully installed $gitVersion" -ForegroundColor Green
    } else {
        # Check standard default installation paths if not in PATH yet
        $defaultGitPaths = @(
            "$env:ProgramFiles\Git\cmd\git.exe",
            "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
            "$env:LocalAppData\Programs\Git\cmd\git.exe"
        )
        $found = $false
        foreach ($p in $defaultGitPaths) {
            if (Test-Path $p) {
                $gitDir = Split-Path $p
                $env:Path += ";$gitDir"
                $found = $true
                Write-Host "[✓] Git detected at $p" -ForegroundColor Green
                break
            }
        }
        if (-not $found) {
            Write-Host "[Error] Could not install or locate Git automatically." -ForegroundColor Red
            Write-Host "Please install Git manually from https://git-scm.com/ and restart your terminal." -ForegroundColor Yellow
            exit 1
        }
    }
}

# 1. Detect Python
$pythonCmd = $null
if (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = "python"
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
    $pythonCmd = "py -3"
} else {
    Write-Host "[Error] Python 3 was not found in your PATH." -ForegroundColor Red
    Write-Host "Please install Python 3.9+ from https://www.python.org/downloads/ and ensure 'Add python.exe to PATH' is checked." -ForegroundColor Yellow
    exit 1
}

# Check Python Version >= 3.9
try {
    $cmdParts = $pythonCmd -split " "
    $exe = $cmdParts[0]
    $extraArgs = @()
    if ($cmdParts.Length -gt 1) { $extraArgs = $cmdParts[1..($cmdParts.Length - 1)] }
    $versionCheck = & $exe ($extraArgs + @("-c", "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"))
    $parts = $versionCheck.Trim().Split('.')
    $major = [int]$parts[0]
    $minor = [int]$parts[1]

    if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 9)) {
        Write-Host "[Error] Python 3.9+ is required. Found Python $versionCheck." -ForegroundColor Red
        exit 1
    }
    Write-Host "[✓] Found Python $versionCheck ($pythonCmd)" -ForegroundColor Green
} catch {
    Write-Host "[!] Could not verify Python version, continuing..." -ForegroundColor Yellow
}

# 2. Check current directory or clone repo
$repoUrl = "https://github.com/intelQong/markitdown-sop-generator.git"
$targetDir = "markitdown-sop-generator"

if (Test-Path "src\sop_engine.py") {
    $projectDir = (Get-Item -Path ".").FullName
} elseif (Test-Path "$targetDir\src\sop_engine.py") {
    $projectDir = (Get-Item -Path "$targetDir").FullName
    Set-Location $projectDir
} else {
    Ensure-GitInstalled
    Write-Host "[*] Cloning repository from $repoUrl..." -ForegroundColor Blue
    git clone $repoUrl $targetDir
    Set-Location $targetDir
    $projectDir = (Get-Item -Path ".").FullName
}

Write-Host "[✓] Working directory: $projectDir" -ForegroundColor Green

# 3. Create virtual environment
$venvPath = Join-Path $projectDir ".venv"
if (-not (Test-Path $venvPath)) {
    Write-Host "[*] Creating Python virtual environment in .venv..." -ForegroundColor Blue
    $cmdParts = $pythonCmd -split " "
    $exe = $cmdParts[0]
    $extraArgs = @()
    if ($cmdParts.Length -gt 1) { $extraArgs = $cmdParts[1..($cmdParts.Length - 1)] }
    & $exe ($extraArgs + @("-m", "venv", ".venv"))
}
Write-Host "[✓] Virtual environment ready at .venv" -ForegroundColor Green

# 4. Install dependencies
$venvPython = Join-Path $venvPath "Scripts\python.exe"
$venvPip = Join-Path $venvPath "Scripts\pip.exe"

if (-not (Test-Path $venvPip)) {
    Write-Host "[Error] Virtual environment pip not found at $venvPip." -ForegroundColor Red
    exit 1
}

Write-Host "[*] Upgrading pip and installing required packages..." -ForegroundColor Blue
& $venvPip install --upgrade pip --quiet

if (Test-Path "requirements.txt") {
    & $venvPip install -r requirements.txt --quiet
} elseif (Test-Path "src\requirements.txt") {
    & $venvPip install -r src\requirements.txt --quiet
}

# Optional editable install for CLI entry point
& $venvPip install -e . --quiet

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  ✨ Installation Completed Successfully!          " -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To get started, activate the virtual environment:" -ForegroundColor White
Write-Host "  cd `"$projectDir`"" -ForegroundColor Cyan
Write-Host "  .\.venv\Scripts\Activate.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Run the CLI engine:" -ForegroundColor White
Write-Host "  sop-engine --help   (or: python src\sop_engine.py --help)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ingest applicant files:" -ForegroundColor White
Write-Host "  sop-engine --ingest `"path\to\applicant_folder`" --output-md `"applicant_context.md`"" -ForegroundColor Cyan
Write-Host ""
Write-Host "Export SOP to Word (.docx):" -ForegroundColor White
Write-Host "  sop-engine --export-docx `"final_sop.txt`" --docx-out `"SOP.docx`" --name `"Applicant Name`" --course `"Degree`" --country `"Country`"" -ForegroundColor Cyan
Write-Host ""
