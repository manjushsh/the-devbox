#!/usr/bin/env pwsh
<#
.SYNOPSIS
Installation script for DevBox Sandboxer

.DESCRIPTION
This script installs the required dependencies and sets up DevBox Sandboxer for use.

.EXAMPLE
.\install.ps1
#>

Write-Host "DevBox Sandboxer Installation" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "PowerShell 5.1 or higher is required. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

Write-Host "✓ PowerShell version check passed" -ForegroundColor Green

# Check Windows version and edition
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$windowsVersion = [System.Environment]::OSVersion.Version
$isSupported = $false

if ($windowsVersion.Major -eq 10) {
    if ($osInfo.ProductType -eq 1) { # Workstation
        $edition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
        if ($edition -in @("Professional", "Enterprise", "Education")) {
            $isSupported = $true
        }
    }
} elseif ($windowsVersion.Major -ge 11) {
    $isSupported = $true
}

if (-not $isSupported) {
    Write-Warning "Windows Sandbox requires Windows 10 Pro/Enterprise/Education or Windows 11"
    Write-Host "Current OS: $($osInfo.Caption)" -ForegroundColor Yellow
}

# Check if Windows Sandbox is enabled
Write-Host "Checking Windows Sandbox status..." -ForegroundColor Yellow

try {
    $feature = Get-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -ErrorAction Stop
    if ($feature.State -eq "Enabled") {
        Write-Host "✓ Windows Sandbox is enabled" -ForegroundColor Green
    } else {
        Write-Warning "Windows Sandbox is not enabled"
        Write-Host "To enable Windows Sandbox, run as Administrator:" -ForegroundColor Yellow
        Write-Host "Enable-WindowsOptionalFeature -Online -FeatureName 'Containers-DisposableClientVM' -All" -ForegroundColor Cyan
        Write-Host "Then restart your computer." -ForegroundColor Yellow
    }
} catch {
    Write-Warning "Could not check Windows Sandbox status. You may need to run this as Administrator."
}

# Install required PowerShell modules
Write-Host "Installing required PowerShell modules..." -ForegroundColor Yellow

try {
    if (-not (Get-Module -ListAvailable -Name "powershell-yaml")) {
        Write-Host "Installing powershell-yaml module..." -ForegroundColor Gray
        Install-Module -Name powershell-yaml -Force -Scope CurrentUser
        Write-Host "✓ powershell-yaml module installed" -ForegroundColor Green
    } else {
        Write-Host "✓ powershell-yaml module already installed" -ForegroundColor Green
    }
} catch {
    Write-Error "Failed to install powershell-yaml module: $($_.Exception.Message)"
    Write-Host "Please run: Install-Module powershell-yaml -Force" -ForegroundColor Yellow
}

# Test the devbox script
Write-Host "Testing devbox.ps1..." -ForegroundColor Yellow

$devboxScript = Join-Path $PSScriptRoot "devbox.ps1"
if (Test-Path $devboxScript) {
    try {
        # Test script syntax
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $devboxScript -Raw), [ref]$null)
        Write-Host "✓ devbox.ps1 syntax is valid" -ForegroundColor Green
        
        # Add to PATH suggestion
        $currentPath = $PSScriptRoot
        Write-Host "`nSetup completed!" -ForegroundColor Green
        Write-Host "You can now use DevBox from this directory:" -ForegroundColor White
        Write-Host "  .\devbox.ps1 up" -ForegroundColor Cyan
        Write-Host "  .\devbox.ps1 status" -ForegroundColor Cyan
        Write-Host "  .\devbox.ps1 down" -ForegroundColor Cyan
        
        Write-Host "`nOptionally, add this directory to your PATH:" -ForegroundColor White
        Write-Host "  `$env:PATH += ';$currentPath'" -ForegroundColor Cyan
        
    } catch {
        Write-Error "devbox.ps1 has syntax errors: $($_.Exception.Message)"
    }
} else {
    Write-Error "devbox.ps1 not found in current directory"
}

Write-Host "`nFor more information, see README.md" -ForegroundColor Gray