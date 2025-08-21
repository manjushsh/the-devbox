# DevBox Configuration Examples

This folder contains example `devbox.yaml` configurations for different development scenarios. Copy any of these files to your project root and rename it to `devbox.yaml` to use.

## Available Examples

### Web Development
- **`basic-web-dev.yaml`** - General web development (Git + Node.js + VS Code)
- **`react-project.yaml`** - React development with Yarn and Chrome
- **`php-project.yaml`** - PHP development with Composer, MySQL, and Nginx

### Programming Languages
- **`go-project.yaml`** - Go development with proper GOPATH and build tools
- **`rust-project.yaml`** - Rust development with Cargo and LLVM
- **`java-project.yaml`** - Java development with Maven, Gradle, and IntelliJ
- **`ruby-project.yaml`** - Ruby development with Rails and Bundler
- **`dotnet-project.yaml`** - .NET development with optimized settings

### Data Science & AI/ML
- **`python-datascience.yaml`** - Python with Jupyter and data science libraries
- **`ai-ml-project.yaml`** - AI/ML development with CUDA, PyTorch, TensorFlow

### Mobile & Game Development
- **`flutter-project.yaml`** - Flutter development with Android Studio
- **`game-dev-project.yaml`** - Game development with Unity Hub and Blender

### DevOps & Infrastructure
- **`docker-project.yaml`** - Docker and Kubernetes development
- **`terraform-devops.yaml`** - Infrastructure as Code with Terraform and cloud CLIs

### Specialized
- **`blockchain-project.yaml`** - Blockchain development with Truffle and Hardhat
- **`minimal.yaml`** - Minimal environment (Git + VS Code only)

## Usage Examples

### Quick Start with React
```bash
cp examples/react-project.yaml devbox.yaml
./devbox.ps1 up
```

### AI/ML Development
```bash
cp examples/ai-ml-project.yaml devbox.yaml
# Edit devbox.yaml to add your specific ML libraries
./devbox.ps1 up
```

### DevOps Infrastructure
```bash
cp examples/terraform-devops.yaml devbox.yaml
./devbox.ps1 up
```

## Customization

Feel free to modify any example by:
- Adding/removing packages from the `packages` list
- Setting custom environment variables
- Adding startup commands for project-specific setup
- Changing the environment name

## Package Names

All packages use Chocolatey package names. You can search for available packages at:
https://community.chocolatey.org/packages
