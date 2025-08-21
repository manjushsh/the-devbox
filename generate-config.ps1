#!/usr/bin/env pwsh
<#
.SYNOPSIS
DevBox Configuration Generator

.DESCRIPTION
Interactive wizard to generate devbox.yaml configurations

.EXAMPLE
.\generate-config.ps1

.EXAMPLE
.\generate-config.ps1 -Template web
#>

param(
    [Parameter()][ValidateSet("web", "api", "desktop", "mobile", "data", "devops", "custom")]
    [string]$Template = "custom"
)

function Get-UserInput {
    param([string]$Prompt, [string]$Default = "")
    
    if ($Default) {
        $input = Read-Host "$Prompt [$Default]"
        return if ($input) { $input } else { $Default }
    } else {
        return Read-Host $Prompt
    }
}

function New-DevBoxConfig {
    param([string]$Template)
    
    Write-Host "DevBox Configuration Generator" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host ""
    
    $config = @{
        name = ""
        packages = @()
        environment = @{}
        startup_commands = @()
    }
    
    # Get project name
    $config.name = Get-UserInput "Project name" "my-project"
    
    # Template-based configuration
    switch ($Template) {
        "web" {
            Write-Host "Setting up web development environment..." -ForegroundColor Green
            $config.packages = @("git", "nodejs", "vscode", "googlechrome")
            $config.environment = @{
                "NODE_ENV" = "development"
                "BROWSER" = "chrome"
            }
            $config.startup_commands = @("node --version", "npm --version")
        }
        "api" {
            Write-Host "Setting up API development environment..." -ForegroundColor Green
            $config.packages = @("git", "nodejs", "vscode", "postman")
            $config.environment = @{
                "NODE_ENV" = "development"
                "PORT" = "3000"
            }
            $config.startup_commands = @("node --version", "npm --version")
        }
        "desktop" {
            Write-Host "Setting up desktop development environment..." -ForegroundColor Green
            $config.packages = @("git", "dotnet-sdk", "vscode", "visualstudio2022community")
            $config.environment = @{
                "DOTNET_CLI_TELEMETRY_OPTOUT" = "1"
            }
            $config.startup_commands = @("dotnet --version")
        }
        "mobile" {
            Write-Host "Setting up mobile development environment..." -ForegroundColor Green
            $config.packages = @("git", "flutter", "androidstudio", "vscode")
            $config.environment = @{
                "FLUTTER_ROOT" = "C:\\tools\\flutter"
            }
            $config.startup_commands = @("flutter --version", "flutter doctor")
        }
        "data" {
            Write-Host "Setting up data science environment..." -ForegroundColor Green
            $config.packages = @("git", "python", "anaconda3", "vscode")
            $config.environment = @{
                "PYTHONPATH" = "C:\\project"
            }
            $config.startup_commands = @("python --version", "pip install jupyter pandas numpy")
        }
        "devops" {
            Write-Host "Setting up DevOps environment..." -ForegroundColor Green
            $config.packages = @("git", "docker-desktop", "kubernetes-cli", "terraform", "vscode")
            $config.environment = @{
                "DOCKER_BUILDKIT" = "1"
            }
            $config.startup_commands = @("docker --version", "kubectl version --client", "terraform --version")
        }
        "custom" {
            Write-Host "Setting up custom environment..." -ForegroundColor Green
            
            # Get packages
            Write-Host "Available package categories:" -ForegroundColor Yellow
            Write-Host "- Languages: git, nodejs, python, dotnet-sdk, golang, rust"
            Write-Host "- Editors: vscode, notepadplusplus, vim"
            Write-Host "- Tools: docker-desktop, postman, googlechrome"
            Write-Host ""
            
            $packagesInput = Get-UserInput "Enter packages (comma-separated)" "git,vscode"
            $config.packages = $packagesInput -split "," | ForEach-Object { $_.Trim() }
            
            # Get environment variables
            $envInput = Get-UserInput "Environment variables (KEY=VALUE,KEY2=VALUE2)" ""
            if ($envInput) {
                $envPairs = $envInput -split ","
                foreach ($pair in $envPairs) {
                    $keyValue = $pair -split "="
                    if ($keyValue.Length -eq 2) {
                        $config.environment[$keyValue[0].Trim()] = $keyValue[1].Trim()
                    }
                }
            }
            
            # Get startup commands
            $commandsInput = Get-UserInput "Startup commands (comma-separated)" ""
            if ($commandsInput) {
                $config.startup_commands = $commandsInput -split "," | ForEach-Object { $_.Trim() }
            }
        }
    }
    
    return $config
}

function Export-DevBoxConfig {
    param($config, [string]$Path = "devbox.yaml")
    
    $yamlContent = @"
name: "$($config.name)"
packages:
"@
    
    foreach ($package in $config.packages) {
        $yamlContent += "`n  - $package"
    }
    
    if ($config.environment.Count -gt 0) {
        $yamlContent += "`nenvironment:"
        foreach ($key in $config.environment.Keys) {
            $yamlContent += "`n  $key: `"$($config.environment[$key])`""
        }
    }
    
    if ($config.startup_commands.Count -gt 0) {
        $yamlContent += "`nstartup_commands:"
        foreach ($command in $config.startup_commands) {
            $yamlContent += "`n  - `"$command`""
        }
    }
    
    $yamlContent | Out-File -FilePath $Path -Encoding UTF8
    Write-Host "Configuration saved to: $Path" -ForegroundColor Green
}

# Main execution
try {
    $config = New-DevBoxConfig -Template $Template
    
    Write-Host ""
    Write-Host "Generated Configuration:" -ForegroundColor Yellow
    Write-Host "Name: $($config.name)"
    Write-Host "Packages: $($config.packages -join ', ')"
    if ($config.environment.Count -gt 0) {
        Write-Host "Environment: $($config.environment.Keys -join ', ')"
    }
    if ($config.startup_commands.Count -gt 0) {
        Write-Host "Startup Commands: $($config.startup_commands.Count) commands"
    }
    
    Write-Host ""
    $confirm = Get-UserInput "Save configuration? (y/n)" "y"
    
    if ($confirm -eq "y" -or $confirm -eq "yes") {
        Export-DevBoxConfig $config
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Review and customize devbox.yaml if needed"
        Write-Host "2. Run: powershell -ExecutionPolicy Bypass -File devbox.ps1 up"
    } else {
        Write-Host "Configuration not saved." -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Configuration generation failed: $($_.Exception.Message)"
    exit 1
}
