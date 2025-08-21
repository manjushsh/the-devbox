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
        # Skip elevation check for now - just log and continue
        Write-DevBoxLog "Windows Sandbox check skipped (requires elevation)" "INFO"
        return $true
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
    
    # https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-configure-using-wsb-file
    $config = @{ 
        packages = @(); 
        environment = @{}; 
        startup_commands = @()
        # WSB Configuration defaults
        sandbox = @{
            memory_mb = 4096
            vgpu = "Default"
            networking = "Default"
            audio_input = $false
            video_input = $false
            printer_redirection = $false
            clipboard_redirection = $true
            protected_client = $false
        }
    }
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
        } elseif ($line -eq "sandbox:") {
            $currentSection = "sandbox"
        } elseif ($line -match "^\s*-\s*(.+)$" -and $currentSection -eq "packages") {
            $config.packages += $matches[1].Trim()
        } elseif ($line -match "^\s*-\s*(.+)$" -and $currentSection -eq "startup_commands") {
            $config.startup_commands += $matches[1].Trim('"').Trim("'")
        } elseif ($line -match "^\s*(\w+):\s*(.+)$" -and $currentSection -eq "environment") {
            $config.environment[$matches[1]] = $matches[2].Trim('"').Trim("'")
        } elseif ($line -match "^\s*(\w+):\s*(.+)$" -and $currentSection -eq "sandbox") {
            $key = $matches[1]
            $value = $matches[2].Trim('"').Trim("'")
            
            # Convert specific values
            if ($key -eq "memory_mb") {
                $config.sandbox[$key] = [int]$value
            } elseif ($key -in @("audio_input", "video_input", "printer_redirection", "clipboard_redirection", "protected_client")) {
                $config.sandbox[$key] = $value -eq "true"
            } else {
                $config.sandbox[$key] = $value
            }
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
    $networkDisabled = $config.sandbox.networking -eq "Disable"
    $setupScript = @"
Write-Host "DevBox Sandboxer - Visual Setup Progress" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

`$LogFile = "C:\project\devbox-setup.log"
function Write-Log { param([string]`$Message); "`$(Get-Date) - `$Message" | Tee-Object -FilePath `$LogFile -Append }

Write-Log "Starting DevBox setup for $($config.name)"

# Check network configuration
`$NetworkDisabled = `"$($networkDisabled.ToString().ToLower())`"
if (`$NetworkDisabled -eq 'true') {
    Write-Host "NOTICE: Network is disabled for this sandbox" -ForegroundColor Yellow
    Write-Host "Package installation will be skipped for security" -ForegroundColor Yellow
    Write-Log "Network disabled - skipping package installation"
    
    Write-Host "STEP 1: Network-isolated environment ready" -ForegroundColor Green
    Write-Host "Available tools:" -ForegroundColor Cyan
    Write-Host "  - Windows built-in tools (PowerShell, CMD, Notepad)" -ForegroundColor Gray
    Write-Host "  - Your project files in C:\project" -ForegroundColor Gray
} else {
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
            Write-Host "This may be due to network restrictions or firewall settings" -ForegroundColor Yellow
            Write-Log "Chocolatey installation failed: `$(`$_.Exception.Message)"
            Read-Host "Press Enter to continue without package installation"
        }
    } else {
        Write-Host "STEP 1: Chocolatey already installed" -ForegroundColor Green
    }
}

"@

    # Add package installations with visual progress
    if ($config.packages.Count -gt 0) {
        if ($networkDisabled) {
            $setupScript += @"
Write-Host "STEP 2: Package installation skipped (network disabled)" -ForegroundColor Yellow
Write-Host "Requested packages: $($config.packages -join ', ')" -ForegroundColor Gray
Write-Host "For security, this environment runs without external software" -ForegroundColor Cyan
Write-Log "Package installation skipped due to network isolation"

"@
        } else {
            $setupScript += "Write-Host `"STEP 2: Installing $($config.packages.Count) packages...`" -ForegroundColor Yellow`n"
            $setupScript += "if (Get-Command choco -ErrorAction SilentlyContinue) {`n"
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
            $setupScript += "} else {`n"
            $setupScript += "    Write-Host `"Chocolatey not available - skipping package installation`" -ForegroundColor Yellow`n"
            $setupScript += "}`n"
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
    
    # Create sandbox config with enhanced options
    $hostName = "$($config.name)-DevBox"
    $absolutePath = Resolve-Path "."
    
    # Build WSB configuration with user-defined settings
    $wsbConfig = @"
<Configuration>
    <VGpu>$($config.sandbox.vgpu)</VGpu>
    <Networking>$($config.sandbox.networking)</Networking>
    <AudioInput>$($config.sandbox.audio_input.ToString().ToLower())</AudioInput>
    <VideoInput>$($config.sandbox.video_input.ToString().ToLower())</VideoInput>
    <PrinterRedirection>$($config.sandbox.printer_redirection.ToString().ToLower())</PrinterRedirection>
    <ClipboardRedirection>$($config.sandbox.clipboard_redirection.ToString().ToLower())</ClipboardRedirection>
    <ProtectedClient>$($config.sandbox.protected_client.ToString().ToLower())</ProtectedClient>
    <MemoryInMB>$($config.sandbox.memory_mb)</MemoryInMB>
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
