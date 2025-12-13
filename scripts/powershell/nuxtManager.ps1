#!/usr/bin/env pwsh

<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/nuxtManager.ps1
 @version:    1.2.1
 @createDate: 2025 Dec 03
 @createTime: 17:54
 @author:     Steve R Lewis

 ================================================================================

 @description:
 Interactive Nuxt 4 Monorepo Manager

 ================================================================================

 @notes: Revision History

 V1.2.1, 20251204-01:25
 Fixed scalar unwrapping bug by wrapping artifact results in array operator @().

 V1.2.0, 20251204-01:15
 Refactored to use shared utilities. Moved Logger initialization to prevent
 menu UI artifacts from cluttering the log file.

 V1.1.0, 20251204-01:00
 Refactored to use shared utilities (fileSystem, project, logger).

 V1.0.0, 20251203-17:54
 Initial creation and release of nuxtManager.ps1

 ================================================================================
#>

param(
    [switch]$Debug = $false,
    [switch]$Log = $false,
    [switch]$SkipMenu = $false
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
$requiredScripts = @("logger.ps1", "showMenu.ps1", "fileSystem.ps1", "project.ps1")

foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path $utilitiesPath $script
    if (Test-Path $scriptPath) { . $scriptPath }
    else { Write-Host "FATAL: Missing utility '$script'" -ForegroundColor Red; exit 1 }
}

# ---------------------------
# Logic Functions
# ---------------------------

function Invoke-Clean {
    Log-Info "Starting Full Cleanup..."
    $root = (Get-Location).Path

    Log-Debug "Scanning for artifacts..."

    # WRAP IN @() TO FORCE ARRAY
    $items = @(Get-ProjectArtifacts -RootPath $root)

    if ($items.Count -eq 0) {
        Log-Info "System already clean."
        return
    }

    foreach ($item in $items) {
        Log-Debug "Removing: $($item.FullName)"
        Remove-FileOrFolder -Path $item.FullName | Out-Null
    }

    Log-Success "Removed $($items.Count) artifacts."
}

function Invoke-CleanCache {
    Log-Info "Starting Cache Cleanup..."
    $root = (Get-Location).Path

    # WRAP IN @() TO FORCE ARRAY
    $items = @(Get-ProjectArtifacts -RootPath $root -ArtifactDirs @(".nuxt") -ArtifactFiles @())

    # Manual scan for node_modules/.cache
    $caches = @(Get-ChildItem -Path $root -Recurse -Directory -Filter ".cache" -ErrorAction SilentlyContinue |
              Where-Object { $_.FullName -match "node_modules[\\/]\.cache" })

    # Combine arrays
    $allTargets = $items + $caches

    if ($allTargets.Count -eq 0) {
        Log-Info "No cache directories found."
        return
    }

    foreach ($item in $allTargets) {
        Log-Debug "Removing Cache: $($item.FullName)"
        Remove-FileOrFolder -Path $item.FullName | Out-Null
    }

    Log-Success "Removed $($allTargets.Count) cache directories."
}

function Invoke-Reset {
    if (-not (Get-Command "pnpm" -ErrorAction SilentlyContinue)) {
        Log-Error "Prerequisite missing: pnpm"
        throw "pnpm not found"
    }

    Log-Info "Installing dependencies..."
    try {
        & pnpm install | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "pnpm install returned exit code $LASTEXITCODE" }
        Log-Success "Environment reset complete."
    } catch {
        Log-Error "Installation failed: $_"
        throw $_
    }
}

# ---------------------------
# Main Execution
# ---------------------------
$global:DebugMode = $Debug; $global:LogMode = $Log

# 1. Safety Check
Test-ProjectRoot

# 2. Menu Selection
if (-not $SkipMenu) {
    if (-not $Log -and -not $Debug) {
        $opts = @("Enable Logging", "Enable Debug Mode")
        $sel = Show-Menu -Title "Nuxt Manager Config" -Options $opts -MultiSelect $true -ClearScreen $true
        if ($sel -contains "Enable Logging") { $global:LogMode = $true }
        if ($sel -contains "Enable Debug Mode") { $global:DebugMode = $true }
    }

    $procOpts = @("Clean (Remove artifacts)", "Reset (pnpm install)", "Clean & Reset", "Clean Cache Only", "Quit")
    $selectedProcess = Show-Menu -Title "Select Action" -Options $procOpts -MultiSelect $false

    if ($selectedProcess -eq "Quit") { exit 0 }
} else {
    $selectedProcess = "Clean & Reset"
}

# 3. Initialize Logger
Initialize-Logger -LogToFile $global:LogMode -DebugMode $global:DebugMode -LogNamePrefix "nuxtManager"

Log-Info "Action: $selectedProcess"

try {
    switch ($selectedProcess) {
        "Clean (Remove artifacts)" { Invoke-Clean }
        "Reset (pnpm install)"     { Invoke-Reset }
        "Clean & Reset"            { Invoke-Clean; Invoke-Reset }
        "Clean Cache Only"         { Invoke-CleanCache }
    }
} catch {
    Log-Error "Fatal Error: $_"
    exit 1
} finally {
    Stop-Logger
}
