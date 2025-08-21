@{
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'DevBox Sandboxer Team'
    CompanyName = 'DevBox'
    Copyright = '(c) 2025 DevBox Sandboxer. All rights reserved.'
    Description = 'A CLI tool for creating isolated development environments using Windows Sandbox'
    PowerShellVersion = '5.1'
    RequiredModules = @('powershell-yaml')
    ScriptsToProcess = @('devbox.ps1')
    CmdletsToExport = @()
    FunctionsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Windows', 'Sandbox', 'Development', 'Environment', 'CLI')
            LicenseUri = 'https://github.com/manjushsh/the-devbox/blob/main/LICENSE'
            ProjectUri = 'https://github.com/manjushsh/the-devbox'
            ReleaseNotes = 'Initial release of DevBox Sandboxer CLI tool'
        }
    }
}
