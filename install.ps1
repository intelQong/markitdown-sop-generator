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
    Write-Host "[*] Cloning repository from $repoUrl..." -ForegroundColor Blue
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "[Error] Git is required to clone the repository." -ForegroundColor Red
        Write-Host "Please install Git from https://git-scm.com/ or download the repository ZIP." -ForegroundColor Yellow
        exit 1
    }
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
