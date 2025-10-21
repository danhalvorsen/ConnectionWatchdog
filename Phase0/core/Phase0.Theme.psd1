@{
    RootModule        = 'Phase0.Theme.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'b19e7e2c-29e8-4b71-b4e2-5a7b1f4a46d1'
    Author            = 'Phase0 Core Runtime'
    CompanyName       = 'Possibilities'
    Copyright         = '(c) 2025 Possibilities. All rights reserved.'
    Description       = 'Centralized theme and color configuration module for Phase0 runtime.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Set-Phase0Theme', 'Get-Phase0Theme')
    AliasesToExport   = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
    PrivateData       = @{
        PSData = @{
            Tags = @('Phase0', 'Theme', 'Config')
        }
    }
}
