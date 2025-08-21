# Development Guide

This guide helps developers understand the DevBox Sandboxer codebase and contribute effectively.

## Architecture Overview

DevBox Sandboxer consists of several key components:

### Core Script (`devbox.ps1`)
The main CLI application with three primary functions:
- **Start-DevBox**: Creates and launches sandbox environments
- **Stop-DevBox**: Shuts down and cleans up sandbox environments  
- **Get-DevBoxStatus**: Reports current sandbox state

### Configuration Processing
- **Get-DevBoxConfig**: Reads and validates `devbox.yaml` files
- **New-SetupScript**: Generates PowerShell setup scripts for sandbox provisioning
- **New-SandboxConfig**: Creates Windows Sandbox `.wsb` configuration files

### Process Management
- **Test-WindowsSandboxEnabled**: Verifies Windows Sandbox availability
- **Get-DevBoxStatus**: Tracks running sandbox processes by hostname

## Key Design Principles

### 1. Host Safety
- Never install anything on the host machine
- All modifications occur within disposable sandboxes
- Temporary files are cleaned up automatically

### 2. Idempotence  
- Running `devbox up` multiple times produces identical environments
- Configuration changes are detected and handled gracefully
- Process tracking prevents duplicate sandbox launches

### 3. Error Handling
- Comprehensive validation of prerequisites and configuration
- Clear error messages with actionable guidance
- Graceful degradation when components are unavailable

## File Structure

```
devbox.ps1              # Main CLI script
DevBox.psd1            # PowerShell module manifest
install.ps1            # Installation and setup script
devbox.yaml            # Example configuration
devbox.yaml.example    # Template configuration
README.md              # User documentation
.gitignore             # Git exclusions
LICENSE                # MIT license
```

## Development Workflow

### Prerequisites
1. Windows 10 Pro/Enterprise/Education or Windows 11
2. Windows Sandbox enabled
3. PowerShell 5.1 or higher
4. `powershell-yaml` module

### Testing Changes

1. **Syntax Validation**:
   ```powershell
   $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content 'devbox.ps1' -Raw), [ref]$null)
   ```

2. **Help Documentation**:
   ```powershell
   Get-Help ./devbox.ps1 -Full
   ```

3. **Basic Functionality**:
   ```powershell
   ./devbox.ps1 status
   ./devbox.ps1 up
   ./devbox.ps1 down
   ```

### Configuration Testing

Create test configurations in the `tests/` directory:

```yaml
# tests/minimal.yaml
name: "test-minimal"

# tests/complex.yaml  
name: "test-complex"
packages:
  - git
  - nodejs
environment:
  TEST_VAR: "value"
startup_commands:
  - "echo 'test complete'"
```

## Code Style Guidelines

### PowerShell Best Practices
- Use approved verbs for function names (`Get-`, `New-`, `Start-`, `Stop-`)
- Include comprehensive comment-based help for all functions
- Use `[Parameter()]` attributes for function parameters
- Implement proper error handling with try/catch blocks

### Variable Naming
- Use descriptive names: `$sandboxProcesses` not `$sp`
- Prefix script-scoped variables: `$script:TempDir`
- Use PascalCase for functions: `Get-DevBoxConfig`

### Error Messages
- Provide actionable guidance: "To enable Windows Sandbox, run..."
- Include context: "devbox.yaml not found in '$ProjectPath'"
- Use appropriate severity levels (Error, Warning, Information)

## Adding New Features

### 1. Configuration Options
To add new `devbox.yaml` fields:

1. Update validation in `Get-DevBoxConfig`
2. Modify setup script generation in `New-SetupScript`  
3. Update documentation and examples
4. Add test cases

### 2. Package Managers
To support additional package managers beyond Chocolatey:

1. Add detection logic in `New-SetupScript`
2. Create package manager-specific installation commands
3. Update error handling for new failure modes
4. Document new configuration syntax

### 3. Sandbox Features
To leverage additional Windows Sandbox capabilities:

1. Modify XML generation in `New-SandboxConfig`
2. Update parameter validation
3. Test with various sandbox configurations
4. Update troubleshooting documentation

## Testing Strategy

### Unit Testing
Test individual functions in isolation:
- Configuration parsing with various YAML inputs
- Script generation with different package lists
- Process detection with mock sandbox processes

### Integration Testing  
Test complete workflows:
- End-to-end sandbox creation and destruction
- Error scenarios (missing prerequisites, invalid configs)
- Multiple concurrent sandbox management

### Manual Testing
Test on different Windows configurations:
- Various Windows versions and editions
- Different PowerShell versions
- With/without Windows Sandbox enabled

## Debugging

### Enable Verbose Output
Add debug statements throughout the script:
```powershell
Write-Verbose "Generating setup script for $($config.packages.Count) packages" -Verbose
```

### Log File Analysis
Setup scripts create logs at `C:\project\devbox-setup.log` inside sandboxes.
Review these logs for package installation failures.

### Process Monitoring
Use PowerShell to monitor sandbox processes:
```powershell
Get-Process -Name "WindowsSandboxClient" | Select-Object Id, ProcessName, StartTime, MainWindowTitle
```

## Release Process

1. **Version Bump**: Update version in `DevBox.psd1`
2. **Testing**: Run full test suite on clean Windows installation
3. **Documentation**: Update README.md with new features
4. **Tagging**: Create Git tag with version number
5. **Release Notes**: Document changes and known issues

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-capability`
3. Make changes following style guidelines
4. Test thoroughly on Windows systems
5. Update documentation as needed
6. Submit pull request with clear description

## Common Issues

### PowerShell Module Loading
If `powershell-yaml` fails to load:
```powershell
Import-Module powershell-yaml -Force
Get-Module powershell-yaml -ListAvailable
```

### Sandbox Process Detection
Windows Sandbox processes may have varying window titles. The current implementation looks for hostname matches but may need adjustment for different Windows versions.

### Path Resolution
Always use `Resolve-Path` for user-provided paths to handle relative paths and various path formats consistently.
