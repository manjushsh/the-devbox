param([ValidateSet("test", "validate", "clean", "generate")][string]$Action = "test")

Write-Host "DevBox Development Helper" -ForegroundColor Cyan

if ($Action -eq "test") {
    Write-Host "Running tests..." -ForegroundColor Yellow
    
    if (Test-Path "devbox.ps1") {
        Write-Host "✓ devbox.ps1 exists" -ForegroundColor Green
    } else {
        Write-Host "✗ devbox.ps1 missing" -ForegroundColor Red
    }
    
    if (Test-Path "examples") {
        $count = (Get-ChildItem "examples\*.yaml").Count
        Write-Host "✓ Found $count example files" -ForegroundColor Green
    } else {
        Write-Host "✗ examples folder missing" -ForegroundColor Red
    }
    
    Write-Host "✓ Tests completed" -ForegroundColor Green
}

if ($Action -eq "validate") {
    Write-Host "Validating devbox.yaml..." -ForegroundColor Yellow
    
    if (Test-Path "devbox.yaml") {
        $content = Get-Content "devbox.yaml" -Raw
        if ($content -match "name:") {
            Write-Host "✓ Configuration valid" -ForegroundColor Green
        } else {
            Write-Host "✗ Missing name field" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ devbox.yaml not found" -ForegroundColor Red
    }
}

if ($Action -eq "clean") {
    Write-Host "Cleaning artifacts..." -ForegroundColor Yellow
    Remove-Item ".devbox" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "devbox.log" -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Cleanup completed" -ForegroundColor Green
}

if ($Action -eq "generate") {
    Write-Host "Generating devbox.yaml with sandbox configuration..." -ForegroundColor Yellow
    
    $yamlContent = @(
        'name: "my-project"',
        'packages:',
        '  - git',
        '  - vscode',
        'environment:',
        '  EDITOR: "code"',
        'startup_commands:',
        '  - "git --version"',
        'sandbox:',
        '  memory_mb: 6144',
        '  vgpu: "Default"',
        '  networking: "Default"',
        '  clipboard_redirection: true'
    )
    
    $yamlContent | Out-File "devbox.yaml" -Encoding UTF8
    Write-Host "✓ devbox.yaml created with sandbox configuration" -ForegroundColor Green
    Write-Host "  Memory: 6GB, GPU: Default, Network: Enabled" -ForegroundColor Cyan
}