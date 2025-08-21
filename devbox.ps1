param([Parameter(Mandatory = $true)][ValidateSet("up", "down", "status")][string]$Command)

# Global variables
$script:LogFile = "devbox.log"

function Write-DevBoxLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    $logEntry | Add-Content -Path $script:LogFile -Encoding UTF8
}

function Test-WindowsSandboxAvailable {
    Write-DevBoxLog "Checking Windows Sandbox availability..."
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -ErrorAction Stop
        if ($feature.State -ne "Enabled") {
            throw "Windows Sandbox is not enabled. Please enable it in Windows Features or run: Enable-WindowsOptionalFeature -Online -FeatureName 'Containers-DisposableClientVM' -All"
        }
        Write-DevBoxLog "Windows Sandbox is available" "SUCCESS"
    } catch {
        Write-DevBoxLog "Windows Sandbox check failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Test-DevBoxConfig {
    param($config)
    Write-DevBoxLog "Validating configuration..."
    
    if (-not $config.name) { 
        throw "Configuration must have a 'name' field" 
    }
    if ($config.name -match '[<>:"/\\|?*]') { 
        throw "Name '$($config.name)' contains invalid characters. Use only letters, numbers, hyphens, and underscores." 
    }
    
    # Validate package names
    foreach ($package in $config.packages) {
        if ($package -notmatch '^[a-zA-Z0-9\-_.]+$') {
            throw "Invalid package name: '$package'. Package names should only contain letters, numbers, hyphens, dots, and underscores."
        }
    }
    
    Write-DevBoxLog "Configuration validation passed" "SUCCESS"
}

function Parse-DevBoxYaml {
    param([string]$YamlPath)
    if (-not (Test-Path $YamlPath)) { throw "devbox.yaml not found" }
    
    $config = @{ packages = @(); environment = @{}; startup_commands = @() }
    $content = Get-Content $YamlPath
    $currentSection = $null
    
    foreach ($line in $content) {
        $line = $line.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { continue }
        
        if ($line -match "^name:\s*(.+)$") {
            $config.name = $matches[1].Trim('"').Trim("'")
        } elseif ($line -eq "packages:") {
            $currentSection = "packages"
        } elseif ($line -eq "environment:") {
            $currentSection = "environment"
        } elseif ($line -eq "startup_commands:") {
            $currentSection = "startup_commands"
        } elseif ($line -match "^\s*-\s*(.+)$" -and $currentSection -eq "packages") {
            $config.packages += $matches[1].Trim()
        } elseif ($line -match "^\s*-\s*(.+)$" -and $currentSection -eq "startup_commands") {
            $config.startup_commands += $matches[1].Trim('"').Trim("'")
        } elseif ($line -match "^\s*(\w+):\s*(.+)$" -and $currentSection -eq "environment") {
            $config.environment[$matches[1]] = $matches[2].Trim('"').Trim("'")
        }
    }
    return $config
}

function Start-DevBox {
    Write-DevBoxLog "Starting DevBox..." "INFO"
    
    # Check prerequisites
    Test-WindowsSandboxAvailable
    
    try {
        $config = Parse-DevBoxYaml "devbox.yaml"
        Test-DevBoxConfig $config
        Write-DevBoxLog "Configuration loaded: $($config.name)" "SUCCESS"
    } catch {
        Write-DevBoxLog "Failed to read devbox.yaml: $($_.Exception.Message)" "ERROR"
        Write-Error "Failed to read devbox.yaml: $($_.Exception.Message)"
        return
    }
    
    $tempDir = Join-Path $env:TEMP "devbox"
    $devboxDir = ".devbox"
    
    New-Item -ItemType Directory -Path $tempDir -Force -ErrorAction SilentlyContinue | Out-Null
    New-Item -ItemType Directory -Path $devboxDir -Force -ErrorAction SilentlyContinue | Out-Null
    
    # Create enhanced setup script with visual progress
    $setupScript = @"
Write-Host "DevBox Sandboxer - Visual Setup Progress" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

`$LogFile = "C:\project\devbox-setup.log"
function Write-Log { param([string]`$Message); "`$(Get-Date) - `$Message" | Tee-Object -FilePath `$LogFile -Append }

Write-Log "Starting DevBox setup for $($config.name)"

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "STEP 1: Installing Chocolatey package manager..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "SUCCESS: Chocolatey installed!" -ForegroundColor Green
        `$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } catch {
        Write-Host "ERROR: Chocolatey installation failed" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "STEP 1: Chocolatey already installed" -ForegroundColor Green
}

"@

    # Add package installations with visual progress
    if ($config.packages.Count -gt 0) {
        $setupScript += "Write-Host `"STEP 2: Installing $($config.packages.Count) packages...`" -ForegroundColor Yellow`n"
        for ($i = 0; $i -lt $config.packages.Count; $i++) {
            $package = $config.packages[$i]
            $setupScript += @"
Write-Host "[$($i+1)/$($config.packages.Count)] Installing: $package" -ForegroundColor Cyan
Write-Host "Please wait - downloading and installing..." -ForegroundColor Gray
try {
    choco install $package -y --force --timeout 600 --no-progress
    Write-Host "SUCCESS: $package installed!" -ForegroundColor Green
    Write-Log "Package '$package' installed successfully"
} catch {
    Write-Host "ERROR: Failed to install $package" -ForegroundColor Red
    Write-Log "Package '$package' failed: `$(`$_.Exception.Message)"
}
Write-Host ""

"@
        }
    }

    # Add environment and startup commands
    foreach ($key in $config.environment.Keys) {
        $value = $config.environment[$key]
        $setupScript += "Write-Host `"Setting: $key = $value`" -ForegroundColor Cyan`n"
        $setupScript += "[System.Environment]::SetEnvironmentVariable(`"$key`", `"$value`", `"User`")`n"
    }

    foreach ($command in $config.startup_commands) {
        $setupScript += "Write-Host `"Running: $command`" -ForegroundColor Cyan`n"
        $setupScript += "try { `$output = Invoke-Expression `"$command`" 2>&1; Write-Host `"Output: `$output`" -ForegroundColor Green } catch { Write-Host `"Failed`" -ForegroundColor Red }`n"
    }

    $setupScript += @"

Set-Location C:\project
Write-Host ""
Write-Host "SETUP COMPLETE!" -ForegroundColor Green
Write-Host "DevBox is ready for development!" -ForegroundColor White
Write-Host "Project location: C:\project" -ForegroundColor Yellow
Write-Host ""
Write-Log "DevBox setup completed"

Write-Host "DevBox is ready for development!" -ForegroundColor Green
Write-Host "Type 'exit' to close this window" -ForegroundColor Gray
"@

    $setupScript | Set-Content -Path "$devboxDir\setup.ps1" -Encoding UTF8
    
    # Create batch launcher for visible PowerShell window
    $batchLauncher = @"
@echo off
start "DevBox Setup" powershell.exe -NoExit -ExecutionPolicy Bypass -WindowStyle Normal -File "C:\project\.devbox\setup.ps1"
"@
    $batchLauncher | Set-Content -Path "$devboxDir\launch.bat" -Encoding ASCII
    
    # Create sandbox config
    $hostName = "$($config.name)-DevBox"
    $absolutePath = Resolve-Path "."
    $wsbConfig = @"
<Configuration>
    <VGpu>Default</VGpu>
    <Networking>Default</Networking>
    <MappedFolders>
        <MappedFolder>
            <HostFolder>$absolutePath</HostFolder>
            <SandboxFolder>C:\project</SandboxFolder>
            <ReadOnly>false</ReadOnly>
        </MappedFolder>
    </MappedFolders>
    <LogonCommand>
        <Command>C:\project\.devbox\launch.bat</Command>
    </LogonCommand>
    <HostName>$hostName</HostName>
</Configuration>
"@
    
    $wsbPath = Join-Path $tempDir "devbox.wsb"
    $wsbConfig | Set-Content -Path $wsbPath -Encoding UTF8
    
    Write-Host "Launching Windows Sandbox..." -ForegroundColor Gray
    try {
        Start-Process -FilePath $wsbPath
        Write-Host "SUCCESS: DevBox launched!" -ForegroundColor Green
        Write-Host "Watch the sandbox for real-time installation progress!" -ForegroundColor Cyan
        Write-Host "Installing: $($config.packages -join ', ')" -ForegroundColor Yellow
    } catch {
        Write-Error "Failed to launch sandbox: $($_.Exception.Message)"
    }
}

function Get-DevBoxStatus {
    $processes = Get-Process -Name "WindowsSandboxClient" -ErrorAction SilentlyContinue
    
    if ($processes) {
        Write-Host "DevBox Status: RUNNING" -ForegroundColor Green
        foreach ($proc in $processes) {
            Write-Host "  PID: $($proc.Id)" -ForegroundColor Gray
        }
    } else {
        Write-Host "DevBox Status: STOPPED" -ForegroundColor Red
    }
    
    if (Test-Path "devbox.yaml") {
        $config = Parse-DevBoxYaml "devbox.yaml"
        Write-Host "Config: $($config.name)" -ForegroundColor Green
        Write-Host "Packages: $($config.packages -join ', ')" -ForegroundColor Gray
    }
}

switch ($Command.ToLower()) {
    "up" { Start-DevBox }
    "down" { Write-Host "Close sandbox windows manually" -ForegroundColor Yellow }
    "status" { Get-DevBoxStatus }
}
