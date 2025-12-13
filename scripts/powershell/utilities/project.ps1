<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/utilities/project.ps1
 @version:    1.0.0
 @createDate: 2025 Dec 03
 @createTime: 23:21
 @author:     Steve R Lewis

 ================================================================================

 @description:
 Project Context and Safety Utilities

 ================================================================================

 @notes: Revision History

 V1.0.0, 20251203-23:21
 Initial creation and release of project.ps1

 ================================================================================
#>

function Test-ProjectRoot {
    <#
    .SYNOPSIS
        Verifies the script is running from the project root.
    #>
    if (-not (Test-Path -LiteralPath ".\package.json")) {
        Write-Host "FATAL: No 'package.json' found." -ForegroundColor Red
        Write-Host "Please run this script from the project root." -ForegroundColor Gray
        exit 1
    }
}

function Get-FileProjectContext {
    <#
    .SYNOPSIS
        Determines the project name based on file location (Root vs Layer).
    .EXAMPLE
        Returns "my-app" for ~/app/app.vue
        Returns "@monorepo/billing" for ~/layers/billing/nuxt.config.ts.old
    #>
    param(
        [string]$FilePath,
        [string]$RootProjectName
    )

    # Regex to detect if file is inside a /layers/<layerName>/ folder
    if ($FilePath -match "[\\/]layers[\\/]([^\\/]+)[\\/]") {
        return "@monorepo/$($matches[1])"
    }

    return $RootProjectName
}
