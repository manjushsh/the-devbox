# DevBox Sandboxer

A command-line tool for creating isolated development environments on Windows using the native Windows Sandbox feature. DevBox Sandboxer automates the creation of pre-configured sandbox environments with all necessary languages, tools, and project code - think of it as a native Windows alternative to Docker Dev Environments or Vagrant.

## Features

- 🏗️ **Automated Environment Setup**: Creates isolated development environments from YAML configuration
- 🔒 **Host Safety**: Never installs anything on your host machine - everything runs in disposable sandboxes
- 📁 **Code Persistence**: Your project code is mapped into the sandbox but remains on the host
- 🎯 **Simple CLI**: Just three commands: `up`, `down`, and `status`
- 🔄 **Idempotent**: Running `devbox up` multiple times creates consistent environments
- 📦 **Package Management**: Automatic installation of tools via Chocolatey

## Prerequisites

### Windows Sandbox - ([Available only on Windows 10/11 Pro, Enterprise, and Education](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/))
Windows Sandbox must be enabled on your system. To enable it:

1. **Via GUI**: Open "Turn Windows features on or off" and check "Windows Sandbox"
2. **Via PowerShell** (run as Administrator):
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -All
   ```
3. **Restart your computer**

### PowerShell Dependencies
Install the required PowerShell module:
```powershell
Install-Module powershell-yaml
```

## Quick Start

1. **Create a configuration file** in your project root named `devbox.yaml`:
   ```yaml
   name: "my-project"
   packages:
     - git
     - nodejs
     - vscode
   environment:
     NODE_ENV: "development"
   startup_commands:
     - "node --version"
   ```

   Or copy from the [examples folder](examples/) for common development scenarios:
   ```bash
   cp examples/go-project.yaml devbox.yaml
   ```

2. **Start your DevBox**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File devbox.ps1 up
   ```

3. **Check status**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File devbox.ps1 status
   ```

4. **Stop the DevBox**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File devbox.ps1 down
   ```

## Configuration

Create a `devbox.yaml` file in your project root with the following structure:

```yaml
# Required: Name of your development environment
name: "my-awesome-project"

# Optional: List of packages to install via Chocolatey
packages:
  - git
  - nodejs
  - python
  - vscode
  - docker-desktop

# Optional: Environment variables to set
environment:
  NODE_ENV: "development"
  API_URL: "http://localhost:3000"
  DEBUG: "true"

# Optional: Commands to run after setup
startup_commands:
  - "git config --global user.name 'Developer'"
  - "npm install -g yarn"
  - "echo 'Environment ready!'"

# Optional: Windows Sandbox configuration
sandbox:
  memory_mb: 8192                    # RAM allocation in MB
  vgpu: "Enable"                     # GPU virtualization: Default, Enable, Disable
  networking: "Default"              # Network access: Default, Disable
  audio_input: false                 # Enable microphone access
  video_input: false                 # Enable camera access
  printer_redirection: false         # Enable printer access
  clipboard_redirection: true        # Enable clipboard sharing
  protected_client: false            # Enhanced security mode
```

### Configuration Options

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Name of your development environment |
| `packages` | array | No | List of Chocolatey packages to install |
| `environment` | object | No | Environment variables to set |
| `startup_commands` | array | No | Commands to run after setup completion |
| `sandbox` | object | No | Windows Sandbox configuration options |

#### Sandbox Configuration Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `memory_mb` | integer | 4096 | RAM allocation in megabytes |
| `vgpu` | string | "Default" | GPU virtualization: `Default`, `Enable`, `Disable` |
| `networking` | string | "Default" | Network access: `Default`, `Disable` |
| `audio_input` | boolean | false | Enable microphone access in sandbox |
| `video_input` | boolean | false | Enable camera access in sandbox |
| `printer_redirection` | boolean | false | Enable printer access from sandbox |
| `clipboard_redirection` | boolean | true | Enable clipboard sharing with host |
| `protected_client` | boolean | false | Enhanced security mode (limits host access) |
| `packages` | array | No | List of Chocolatey packages to install |
| `environment` | object | No | Environment variables to set |
| `startup_commands` | array | No | Commands to run after setup completion |

## Configuration Examples

The `examples/` folder contains ready-to-use configurations for common development scenarios:

**Programming Languages:**
- **`go-project.yaml`** - Go development with proper GOPATH setup
- **`rust-project.yaml`** - Rust development with Cargo and LLVM
- **`java-project.yaml`** - Java with Maven, Gradle, and IntelliJ
- **`python-datascience.yaml`** - Python with Jupyter and data science libraries
- **`dotnet-project.yaml`** - .NET development environment

**Web & Mobile:**
- **`react-project.yaml`** - React development with Yarn and Chrome
- **`flutter-project.yaml`** - Flutter development with Android Studio
- **`php-project.yaml`** - PHP with Composer, MySQL, and Nginx

**DevOps & Cloud:**
- **`docker-project.yaml`** - Docker and Kubernetes development
- **`terraform-devops.yaml`** - Infrastructure as Code with Terraform
- **`ai-ml-project.yaml`** - AI/ML with CUDA, PyTorch, TensorFlow

**Specialized:**
- **`blockchain-project.yaml`** - Blockchain development with Truffle
- **`game-dev-project.yaml`** - Game development with Unity and Blender
- **`minimal.yaml`** - Minimal environment with just Git and VS Code

Copy any example to your project root as `devbox.yaml` and customize as needed.

## Commands

### `devbox up`
Starts a new sandbox environment:
- Reads `devbox.yaml` from current directory
- Generates setup scripts and sandbox configuration
- Launches Windows Sandbox with your project code mounted
- Installs specified packages and configures environment

### `devbox down`
Stops the running sandbox:
- Gracefully shuts down the sandbox
- Cleans up temporary files
- Removes generated configuration files

### `devbox status`
Shows current sandbox status:
- Whether a sandbox is running for the current project
- Process information and runtime details
- Configuration file status

## How It Works

1. **Configuration Reading**: DevBox reads your `devbox.yaml` file
2. **Script Generation**: Creates a PowerShell setup script with package installations
3. **Sandbox Configuration**: Generates a `.wsb` Windows Sandbox configuration file
4. **Environment Launch**: Starts Windows Sandbox with your project folder mapped
5. **Automatic Setup**: Runs the setup script inside the sandbox to configure the environment

## File Structure

When you run DevBox, it creates the following temporary structure:

```
your-project/
├── devbox.yaml           # Your configuration
├── .devbox/             # Generated files (auto-cleaned)
│   └── setup.ps1        # Setup script for sandbox
└── %TEMP%/devbox/       # Temporary files
    └── your-project/
        └── devbox.wsb   # Sandbox configuration
```

## Package Management

DevBox uses [Chocolatey](https://chocolatey.org/) for package management inside the sandbox. Popular packages include:

- **Development Tools**: `git`, `vscode`, `notepadplusplus`
- **Runtimes**: `nodejs`, `python`, `dotnet`, `golang`
- **Databases**: `postgresql`, `mongodb`, `redis`
- **Containers**: `docker-desktop`, `kubernetes-cli`
- **Build Tools**: `cmake`, `make`, `gradle`, `maven`

Search for packages at [chocolatey.org/packages](https://chocolatey.org/packages).

## Development Tools

DevBox includes several helper tools for development and testing:

### Configuration Generator
Generate configurations interactively:
```powershell
.\generate-config.ps1           # Interactive wizard
.\generate-config.ps1 -Template web    # Web development template
.\generate-config.ps1 -Template api    # API development template
```

### Development Helper
```powershell
.\dev.ps1 test                  # Run test suite
.\dev.ps1 validate              # Validate current devbox.yaml
.\dev.ps1 validate examples/go-project.yaml  # Validate specific file
.\dev.ps1 clean                 # Clean generated files
```

### Testing
Run the test suite to validate all examples and core functionality:
```powershell
.\test\run-tests.ps1
```

## Troubleshooting

### Windows Sandbox Not Available
- Ensure you're running Windows 10 Pro/Enterprise/Education or Windows 11
- Verify virtualization is enabled in BIOS/UEFI
- Check that Hyper-V is not conflicting

### Package Installation Failures
- Check the setup log at `C:\project\devbox-setup.log` inside the sandbox
- Verify package names at chocolatey.org
- Some packages may require additional dependencies

### PowerShell Module Issues
```powershell
# Install required module
Install-Module powershell-yaml -Force

# Check if module is available
Get-Module powershell-yaml -ListAvailable
```

## Examples

### Node.js Web Development
```yaml
name: "nodejs-webapp"
packages:
  - git
  - nodejs
  - vscode
environment:
  NODE_ENV: "development"
  PORT: "3000"
startup_commands:
  - "npm install"
  - "echo 'Ready for Node.js development!'"
```

### Python Data Science
```yaml
name: "python-datascience"
packages:
  - git
  - python
  - vscode
  - anaconda3
startup_commands:
  - "pip install jupyter pandas numpy matplotlib"
  - "python --version"
```

### Full-Stack Development
```yaml
name: "fullstack-dev"
packages:
  - git
  - nodejs
  - python
  - vscode
  - docker-desktop
  - postgresql
environment:
  NODE_ENV: "development"
  DATABASE_URL: "postgresql://localhost:5432/myapp"
startup_commands:
  - "npm install -g @angular/cli"
  - "docker --version"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with various configurations
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 [Documentation](README.md)
- 🐛 [Issue Tracker](https://github.com/manjushsh/the-devbox/issues)
- 💬 [Discussions](https://github.com/manjushsh/the-devbox/discussions)
