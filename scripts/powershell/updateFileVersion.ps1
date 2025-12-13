#!/usr/bin/env pwsh

<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/updateFileVersion.ps1
 @version:    1.1.0
 @createDate: 2025 Dec 05
 @createTime: 19:50
 @author:     Steve R Lewis

 ================================================================================

 @description:
 AI-Powered Automatic Versioning.
 1. Scans for modified .ts/.vue files using Git.
 2. Uses the active LLM to analyze the Diff (Fix vs Feature).
 3. Increments the @version header.
 4. Injects a timestamped entry into the Revision History.

 ================================================================================

 @notes: Revision History

 V1.1.0, 20251208-00:10
 - Refactored to use `llm.ps1` and `llm-messages.ps1`.
 - Replaced `Get-Gemini-VersionAnalysis` with `Get-LLM-VersionAnalysis`.
 - Added `Initialize-LLM` logic.

 V1.0.0, 20251205-19:50
 Initial creation and release of updateFileVersion.ps1

 ================================================================================
#>

param(
    [switch]$Debug,
    [switch]$Log,
    [switch]$SkipMenu,
    [switch]$All # If set, processes all modified files without asking per file
)

# ---------------------------
# Configuration & Imports
# ---------------------------
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$utilitiesPath = Join-Path $PSScriptRoot "utilities"
# CHANGED: Use llm-* utils
$requiredScripts = @("logger.ps1", "llm.ps1", "llm-messages.ps1", "fileSystem.ps1", "semver.ps1", "showMenu.ps1", "project.ps1")

foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path $utilitiesPath $script
    if (Test-Path $scriptPath) { . $scriptPath }
    else { Write-Host "FATAL: Missing utility '$script'" -ForegroundColor Red; exit 1 }
}

$global:DebugMode = $Debug
$global:LogMode = $Log

# --- Interactive Menu ---
if (-not $SkipMenu -and -not $Log -and -not $Debug) {
    $configOptions = @("Enable Logging", "Enable Debug Mode")
    $selections = Show-Menu -Title "Auto-Versioner Config" -Options $configOptions -MultiSelect $true -ClearScreen $true
    if ($selections -contains "Enable Logging") { $global:LogMode = $true }
    if ($selections -contains "Enable Debug Mode") { $global:DebugMode = $true }
}

Initialize-Logger -LogToFile $global:LogMode -DebugMode $global:DebugMode -LogNamePrefix "autoVersion"

# CHANGED: Initialize LLM Provider
Initialize-LLM -SkipMenu:$SkipMenu

# ---------------------------
# Regex Patterns
# ---------------------------
$RxVersion = [regex]::new('(@version:\s*)([vV]?\d+\.\d+\.\d+)', 'Compiled')
$RxHistory = [regex]::new('(@notes: Revision History\s*)', 'Compiled')

# ---------------------------
# Core Logic
# ---------------------------

function Process-File {
    param($FilePath)

    $fileName = Split-Path $FilePath -Leaf
    Log-Info "Processing: $fileName"

    # 1. Get Diff
    $diffRaw = git diff HEAD -- $FilePath
    if (-not $diffRaw) {
        Log-Warning "No diff found for $fileName (is it new/untracked?). Skipping."
        return
    }
    $diff = [string]($diffRaw -join "`n") # Force string

    # 2. Analyze with AI
    Write-Host " -> Asking AI ($($fileName))..." -ForegroundColor DarkGray
    # Throttling protection
    Start-Sleep -Milliseconds 500

    # CHANGED: Use generic call
    $analysis = Get-LLM-VersionAnalysis -Diff $diff

    if (-not $analysis) {
        Log-Error "AI Analysis failed for $fileName"
        return
    }

    Log-Debug "AI Recommendation: $($analysis.increment) - $($analysis.note)"

    # 3. Read File
    $content = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8
    $originalContent = $content

    # 4. Calculate New Version
    $match = $RxVersion.Match($content)
    if (-not $match.Success) {
        Log-Error "Could not find @version header in $fileName"
        return
    }

    $currentVer = $match.Groups[2].Value
    $newVer = Get-NextVersion -CurrentVersion $currentVer -IncrementType $analysis.increment

    # 5. Review (Unless -All is set)
    if (-not $All) {
        $title = "$fileName | $currentVer -> $newVer ($($analysis.increment))"
        $opts = @("Apply Update", "Skip", "Quit")
        $choice = Show-Menu -Title $title -Options $opts -MultiSelect $false -ClearScreen $false
        if ($choice -eq "Skip") { return }
        if ($choice -eq "Quit") { exit }
    }

    # 6. Apply Changes (Regex Replace)

    # A. Update Version Number
    $content = $content -replace '(@version:\s*)([vV]?\d+\.\d+\.\d+)', "`$1$newVer"

    # B. Inject Revision History
    # Date format: V1.1.0, 20251205-1430
    $dateStr = Get-Date -Format "yyyyMMdd-HHmm"
    $historyEntry = "`n V$($newVer -replace 'V',''), $dateStr`n $($analysis.note)`n"

    # We look for "@notes: Revision History" and append our entry immediately after it
    if ($RxHistory.IsMatch($content)) {
        $content = $RxHistory.Replace($content, "`$1$historyEntry", 1)
    } else {
        Log-Warning "Could not find Revision History block. Version updated, but history skipped."
    }

    # 7. Atomic Save
    if ($content -ne $originalContent) {
        Set-ContentAtomic -Path $FilePath -Value $content
        Log-Success "Updated $fileName to $newVer"
    }
}

# ---------------------------
# Execution Flow
# ---------------------------
Test-ProjectRoot

Log-Info "Scanning for modified files..."

# Find modified source files (exclude deleted files)
$modifiedFiles = git diff --name-only --diff-filter=d HEAD | Where-Object { $_ -match "\.(ts|vue)$" }

if (-not $modifiedFiles) {
    Log-Warning "No modified TypeScript or Vue files found."
    exit
}

foreach ($relPath in $modifiedFiles) {
    $fullPath = Resolve-Path $relPath
    Process-File -FilePath $fullPath
}

Log-Success "Auto-Versioning Complete."
Stop-Logger
