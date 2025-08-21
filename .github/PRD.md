# Project Requirements Document: DevBox Sandboxer

## 1. Project Vision & Mission

**Vision:** To create a simple, powerful command-line tool that allows developers to define and launch fully configured, isolated development environments on Windows using the native Windows Sandbox feature.

**Mission:** Eliminate complex local machine setup by automating the creation of project-specific "devboxes." This tool will read a simple configuration file in a project's repository, launch a clean sandbox, install all required languages and tools, and map the project code from the host machine for seamless development. It's "Docker for Windows Desktops."

## 2. Core Principles

- **Simplicity over Complexity:** The configuration should be human-readable and easy to create. The commands should be intuitive (devbox up, devbox down).
- **Reproducibility:** A given configuration file must always produce the exact same development environment.
- **Host Integrity:** The host machine's file system and system state must remain untouched by the devbox's dependencies. All installations happen inside the sandbox.
- **Persistence of Work:** While the sandbox environment is disposable, the user's code and work must be persistent by residing on the host machine.

## 3. Key Features & User Stories

### a. Configuration File (devbox.yaml)

The heart of the project is a configuration file that defines the environment.

- **As a developer, I want to** define the required **language runtimes** and their specific **versions** (e.g., python: 3.10, nodejs: 18).
- **As a developer, I want to** specify **development tools** to be installed (e.g., vscode, git, postman).
- **As a developer, I want to** define which **folder** from my host machine contains the project code, so it can be mapped into the sandbox.
- **As a developer, I want to** run **setup commands or scripts** after the sandbox starts to complete the environment setup (e.g., npm install, pip install -r requirements.txt).

### b. Command-Line Interface (CLI)

The primary user interface for interacting with the tool.

- **As a developer, I want to** run devbox up in my project directory to create and start the sandbox environment defined in devbox.yaml.
- **As a developer, I want to** run devbox down to shut down and destroy the currently running sandbox for the project.
- **As a developer, I want to** run devbox status to see if a devbox is currently running for my project.

### c. Sandbox Orchestration

The backend logic that manages the Windows Sandbox lifecycle.

- The tool will dynamically **generate a .wsb (Windows Sandbox Config) file** based on the devbox.yaml settings.
- It will automatically create a **startup script** (e.g., PowerShell) that runs inside the sandbox to perform the installations.
- It will leverage package managers like **Chocolatey** or **Winget** within the sandbox for reliable software installation.

## 4. Proposed Technical Implementation

- **Primary Language:** **PowerShell Core** is the ideal candidate. It's cross-platform, has excellent integration with the Windows OS, and can easily generate and execute scripts. A compiled language like C# or Go are also strong alternatives for a more robust CLI tool.
- **Configuration Parsing:** Use a standard library to parse the devbox.yaml file.
- **Sandbox Management:**
  1. Read devbox.yaml.
  2. Generate a PowerShell script (setup.ps1) that contains the logic for installing tools (e.g., choco install python3 --version=3.10.5).
  3. Generate a .wsb file. This file will:  
     - Map the project folder from the host to a specific path in the sandbox (e.g., C:\project).
     - Map the generated setup.ps1 script into the sandbox.
     - Set the LogonCommand to execute the setup.ps1 script upon sandbox startup.
  4. Launch the sandbox by executing the generated .wsb file.

## 5. Development Roadmap (MVP)

### Phase 1: Core Functionality

- [ ] Create the devbox.yaml specification with support for a single language, a single tool, and one mapped folder.
- [ ] Implement the logic to parse the YAML file.
- [ ] Build the core function to generate a .wsb file and a setup.ps1 script from the parsed config.
- [ ] Create the devbox up command that performs the generation and launches the sandbox.
- [ ] Hardcode Chocolatey as the default package manager in the setup script.

### Phase 2: Enhancements

- [ ] Implement the devbox down and devbox status commands.
- [ ] Add support for specifying multiple languages and tools in the config.
- [ ] Add support for custom setup commands (e.g., npm install).
- [ ] Improve error handling and provide user-friendly feedback.

### Phase 3: Advanced Features

- [ ] Develop a templating system (devbox init) to create starter devbox.yaml files for common project types (e.g., Python/Django, Node.js/React).
- [ ] Investigate networking options, like port forwarding, if supported by the Sandbox configuration.
- [ ] Consider building a simple GUI wrapper around the CLI tool.

## 6. Example devbox.yaml

```yaml
# devbox.yaml - Example for a Python web project

# The name of the devbox, visible in the sandbox window title
name: "My Python API Project"

# Defines the folder on the host to map into the sandbox
# The current directory '.' is mapped to C:\project inside the sandbox
projectFolder:
  host: .
  sandbox: C:\project
  readOnly: false

# List of software to install using Chocolatey or Winget
packages:
  - python --version=3.10.5
  - git
  - vscode
  - postman

# Commands to run after the sandbox starts and packages are installed
# These commands will run inside the C:\project directory
setupCommands:
  - "pip install --upgrade pip"
  - "pip install -r requirements.txt"
  - "echo 'DevBox is ready!'"
```  
