# DevBox Sandboxer Tests

# Simple test framework
function Test-Function {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    
    try {
        Write-Host "Testing: $Name" -ForegroundColor Cyan
        $result = & $Test
        if ($result) {
            Write-Host "  ✓ PASS" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ✗ FAIL" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  ✗ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Import the main script functions
. "$PSScriptRoot\..\devbox.ps1" -Command "status" -ErrorAction SilentlyContinue

Write-Host "DevBox Sandboxer Test Suite" -ForegroundColor Yellow
Write-Host "===========================" -ForegroundColor Yellow

$totalTests = 0
$passedTests = 0

# Test 1: YAML Parsing
$totalTests++
if (Test-Function "Parse-DevBoxYaml with valid YAML" {
    $testYaml = @"
name: "test-project"
packages:
  - git
  - nodejs
environment:
  NODE_ENV: "test"
startup_commands:
  - "node --version"
"@
    $testYaml | Out-File -FilePath "test-config.yaml" -Encoding UTF8
    
    try {
        $config = Parse-DevBoxYaml "test-config.yaml"
        $valid = $config.name -eq "test-project" -and 
                $config.packages.Count -eq 2 -and
                $config.environment["NODE_ENV"] -eq "test"
        Remove-Item "test-config.yaml" -ErrorAction SilentlyContinue
        return $valid
    } catch {
        Remove-Item "test-config.yaml" -ErrorAction SilentlyContinue
        throw
    }
}) { $passedTests++ }

# Test 2: Configuration Validation
$totalTests++
if (Test-Function "Test-DevBoxConfig with valid config" {
    $config = @{
        name = "test-project"
        packages = @("git", "nodejs")
        environment = @{}
        startup_commands = @()
    }
    
    try {
        Test-DevBoxConfig $config
        return $true
    } catch {
        return $false
    }
}) { $passedTests++ }

# Test 3: Invalid Configuration
$totalTests++
if (Test-Function "Test-DevBoxConfig with invalid name" {
    $config = @{
        name = "test/project"  # Invalid character
        packages = @("git")
        environment = @{}
        startup_commands = @()
    }
    
    try {
        Test-DevBoxConfig $config
        return $false  # Should have thrown an error
    } catch {
        return $true   # Expected to fail
    }
}) { $passedTests++ }

# Test 4: Example Configurations
$exampleFiles = Get-ChildItem "$PSScriptRoot\..\examples\*.yaml"
foreach ($exampleFile in $exampleFiles) {
    $totalTests++
    if (Test-Function "Validate example: $($exampleFile.Name)" {
        try {
            $config = Parse-DevBoxYaml $exampleFile.FullName
            Test-DevBoxConfig $config
            return $true
        } catch {
            Write-Host "    Error in $($exampleFile.Name): $($_.Exception.Message)" -ForegroundColor Yellow
            return $false
        }
    }) { $passedTests++ }
}

# Test Results
Write-Host ""
Write-Host "Test Results:" -ForegroundColor Yellow
Write-Host "=============" -ForegroundColor Yellow
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $($totalTests - $passedTests)" -ForegroundColor Red

if ($passedTests -eq $totalTests) {
    Write-Host "All tests passed! ✓" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some tests failed! ✗" -ForegroundColor Red
    exit 1
}
