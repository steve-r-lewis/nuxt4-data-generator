#!/usr/bin/env pwsh

<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/validateScriptHeaders.ps1
 @version:    1.3.2
 @createDate: 2025 Dec 03
 @createTime: 22:14
 @author:     Steve R Lewis

 ================================================================================

.SYNOPSIS
    Validate and update header blocks in source files.

.DESCRIPTION
    Scans TypeScript, Vue, and config files to ensure they have consistent
    standard headers.
    - Updates @project, @file, @author fields.
    - Syncs @version from the revision history block.
    - Validates package.json names against folder structure.
    - Provides a summary report of actions taken.

.PARAMETER Log
    Enable file-based transcript logging.

.PARAMETER Debug
    Enable verbose debug output.

 ================================================================================

 @notes: Revision History

 V1.4.0, 20251203-23:36
 Refactored the files removing reusable code into three new utilities libraries.

 V1.3.2, 20251203-23:59
 Added logic to explicitly scan root-level source files (e.g. nuxt.config.ts.old)
 while maintaining strict recursive scanning for subdirectories.

 V1.3.1, 20251203-23:55
 Updated Reporting to show full relative path in the summary table instead of
 just filename. Updated Validate-PackageJson to support path resolution.

 V1.3.0, 20251203-23:01
 Optimized I/O (single-pass read/write), implemented atomic writes for safety,
 compiled Regex for performance, and expanded exclusion lists.

 V1.2.1, 20251203-23:25
 Removed redundant 'Start' menu option to align with UX standards.

 V1.2.0, 20251203-23:15
 Refactored scan logic to strict directories, added node_modules exclusion,
 fixed null content errors, and added interactive menu.

 V1.1.0, 20251203-22:45
 Refactored to align with gitManageRepos.ps1 gold standards (Reporting, Progress, Robustness).

 V1.0.0, 20251203-22:14
 Initial creation and release of validateScriptHeaders.ps1

 ================================================================================
#>

param(
    [switch]$Log,
    [switch]$Debug,
    [switch]$SkipMenu
)

# ---------------------------
# Configuration
# ---------------------------
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------
# Import Utilities
# ---------------------------
$utilitiesPath = Join-Path $PSScriptRoot "utilities"
$requiredScripts = @("logger.ps1", "showMenu.ps1", "paths.ps1", "fileSystem.ps1", "project.ps1")

foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path $utilitiesPath $script
    if (Test-Path $scriptPath) { . $scriptPath }
    else { Write-Host "FATAL: Missing utility '$script'" -ForegroundColor Red; exit 1 }
}

# ---------------------------
# Compiled Regex
# ---------------------------
$RegexOptions = [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::Multiline
$RxProject    = [regex]::new('(@project:\s*)(.+)', $RegexOptions)
$RxFile       = [regex]::new('(@file:\s*)(.+)', $RegexOptions)
$RxAuthor     = [regex]::new('(@author:\s*)(.+)', $RegexOptions)
$RxVersionTag = [regex]::new('(@version:\s*)(\S+)', $RegexOptions)
$RxHistory    = [regex]::new('V\d+\.\d+\.\d+', $RegexOptions)

$global:OperationReport = @()

function Add-ReportEntry {
    param($File, $Action, $Details)
    $global:OperationReport += [PSCustomObject]@{ "File"=$File; "Action"=$Action; "Details"=$Details }
}

# ---------------------------
# Logic Functions
# ---------------------------

function Process-SourceFile {
    param($fileItem, $projectName, $rootPath)

    # Utility: Get-RelativePath (from paths.ps1)
    $relPathDisplay = Get-RelativePath -FullPath $fileItem.FullName -RootPath $rootPath

    try {
        $content = Get-Content -LiteralPath $fileItem.FullName -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($content)) { return }

        $original = $content
        $isModified = $false
        $changes = @()

        # --- Header Updates ---
        if ($RxProject.IsMatch($content)) {
            $new = $RxProject.Replace($content, "`$1$projectName")
            if ($new -ne $content) { $content = $new; $isModified = $true }
        }

        if ($RxFile.IsMatch($content)) {
            $new = $RxFile.Replace($content, "`$1$relPathDisplay")
            if ($new -ne $content) { $content = $new; $isModified = $true; $changes += "Path" }
        }

        if ($RxAuthor.IsMatch($content)) {
            $new = $RxAuthor.Replace($content, "`$1Steve R Lewis")
            if ($new -ne $content) { $content = $new; $isModified = $true; $changes += "Author" }
        }

        # --- Version Sync ---
        $revMatches = $RxHistory.Matches($content)
        if ($revMatches.Count -gt 0) {
            $latestRev = $revMatches[0].Value
            $verMatch = $RxVersionTag.Match($content)

            if ($verMatch.Success -and $verMatch.Groups[2].Value -ne $latestRev) {
                $content = $RxVersionTag.Replace($content, "`$1$latestRev")
                $isModified = $true
                $changes += "Ver: $latestRev"
            }
        }

        # --- Atomic Write ---
        if ($isModified) {
            # Utility: Set-ContentAtomic (from fileSystem.ps1)
            Set-ContentAtomic -Path $fileItem.FullName -Value $content
            Log-Info "Updated $relPathDisplay"
            Add-ReportEntry -File $relPathDisplay -Action "Updated" -Details ($changes -join ", ")
        }
    } catch {
        Log-Error "Failed: $_"
        Add-ReportEntry -File $relPathDisplay -Action "Error" -Details $_.Exception.Message
    }
}

function Validate-PackageJson {
    param($path, $expectedName, $rootPath)
    $relPath = Get-RelativePath -FullPath $path -RootPath $rootPath

    try {
        $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($content)) { return }
        $json = $content | ConvertFrom-Json

        if ($json.name -ne $expectedName) {
            Log-Warning "Updating package.json name to '$expectedName'"
            $json.name = $expectedName
            $newJson = $json | ConvertTo-Json -Depth 10

            # Utility: Set-ContentAtomic (from fileSystem.ps1)
            Set-ContentAtomic -Path $path -Value $newJson
            Add-ReportEntry -File $relPath -Action "Package Fix" -Details "Name set to $expectedName"
        }
    } catch {
        Log-Error "JSON Error: $_"
        Add-ReportEntry -File $relPath -Action "Error" -Details "JSON Invalid"
    }
}

# ---------------------------
# Main Execution
# ---------------------------
$global:DebugMode = $Debug; $global:LogMode = $Log

# --- Interactive Menu ---
if (-not $SkipMenu -and -not $Log -and -not $Debug) {
    $opts = @("Enable Logging", "Enable Debug Mode")
    $sel = Show-Menu -Title "Script Header Validator Config" -Options $opts -MultiSelect $true -ClearScreen $true
    if ($sel -contains "Enable Logging") { $global:LogMode = $true }
    if ($sel -contains "Enable Debug Mode") { $global:DebugMode = $true }
}

Initialize-Logger -LogToFile $global:LogMode -DebugMode $global:DebugMode -LogNamePrefix "validateHeaders"
Log-Info "Starting Script Header Validation..."

try {
    # Utility: Test-ProjectRoot (from project.ps1)
    Test-ProjectRoot

    $rootPath = (Get-Location).Path
    $rootName = Split-Path $rootPath -Leaf

    # Utility: Get-ProjectSourceFiles (from fileSystem.ps1)
    # Gathers files from Root + App/Layers/Server/Scripts, excluding node_modules etc.
    $allFiles = Get-ProjectSourceFiles -RootPath $rootPath -Extensions @(".ts", ".vue")

    $total = $allFiles.Count
    $count = 0

    if ($total -eq 0) { Log-Warning "No source files found." }

    foreach ($fileItem in $allFiles) {
        $count++
        Write-Progress -Activity "Header Validation" -Status "Processing: $($fileItem.Name)" -PercentComplete (($count / $total) * 100)

        # Utility: Get-FileProjectContext (from project.ps1)
        # Decides if file is '@monorepo/layer' or 'root-app'
        $projectField = Get-FileProjectContext -FilePath $fileItem.FullName -RootProjectName $rootName

        if ($fileItem.Name -eq "package.json") {
             Validate-PackageJson -path $fileItem.FullName -expectedName $projectField -rootPath $rootPath
        } else {
             # Skip definition files
             if ($fileItem.Name -notlike "*.d.ts") {
                Process-SourceFile -fileItem $fileItem -projectName $projectField -rootPath $rootPath
             }
        }
    }

    Log-Success "Validation Complete."

} catch {
    Log-Error "Fatal: $_"
    Add-ReportEntry -File "Global" -Action "Fatal" -Details $_.Exception.Message
} finally {
    Write-Progress -Activity "Header Validation" -Completed
    if ($global:OperationReport.Count -gt 0) {
        Write-Host "`nSummary:" -ForegroundColor Cyan
        $global:OperationReport | Format-Table -AutoSize
    } else {
        Write-Host "`nAll files checked. No issues found." -ForegroundColor Green
    }
    Stop-Logger
}
