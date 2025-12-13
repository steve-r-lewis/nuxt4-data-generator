#!/usr/bin/env pwsh

<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/gitManageRepos.ps1
 @version:    2.0.0
 @createDate: 2025 Dec 03
 @createTime: 17:50
 @author:     Steve R Lewis

 ================================================================================
.SYNOPSIS
 Automated Git & GitHub Repository Management.

.DESCRIPTION
    Idempotent manager for the Nuxt 4 monorepo Git structure.
    1. Ensures Root repo exists and remote is synced.
    2. Ensures Layer repos exist (via GitHub API) and are synced.
    3. Ensures Layers are linked as Submodules.

.PARAMETER Push
    If set, pushes changes to the remote origin. Default is $true.

.PARAMETER Debug
    Enables verbose debug logging.

.PARAMETER Log
    Enables file-based transcript logging.

.PARAMETER SkipMenu
    Skips interactive menus and runs with provided/default parameters.

.PARAMETER GitHubOrg
    The GitHub Organization or User account to create repositories under. Default: "steve-r-lewis".

.EXAMPLE
    ./gitManageRepos.ps1 -SkipMenu -Log
    Runs the full initialization process non-interactively with logging enabled.

 ================================================================================

.NOTES

.REVISION HISTORY

 V2.0.0, 20251208-14:00
 Renamed from gitManageRepos.ps1 to gitManageRepos.ps1 to reflect idempotent nature.
 Renamed internal function Init-GitRepo to Ensure-GitRepo.

 V1.4.0, 20251208-12:30
 Fixed imports to use 'llm.ps1'.

 V1.3.0, 20251205-15:45
 Integrated gemini-messages.ps1 to generate semantic commit messages
 when initializing existing dirty repositories.

 V1.2.1, 20251205-19:35
 Fixed Summary Table visibility by switching array to Generic List.

 V1.2.0, 20251205-14:15
 Added 'Remove-FailedSubmodule' rollback logic.
 Implemented 'git status --porcelain' for robust state checking.
 Refactored for better error handling during submodule addition.

 V1.1.0, 20251204-01:45
 Refactored to use shared utilities (project.ps1) and improved log hygiene.

 V1.0.0, 20251203-17:50
 Initial creation and release of gitManageRepos.ps1

 ================================================================================
#>

param(
    [switch]$Push = $true,
    [switch]$Debug,
    [switch]$Log,
    [switch]$SkipMenu,
    [string]$GitHubOrg = "steve-r-lewis"
)

# ---------------------------
# Configuration & Safety
# ---------------------------
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------
# Import Utilities
# ---------------------------
$utilitiesPath = Join-Path $PSScriptRoot "utilities"
$requiredScripts = @("showMenu.ps1", "logger.ps1", "github.ps1", "project.ps1", "llm.ps1", "llm-messages.ps1")

foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path $utilitiesPath $script
    if (Test-Path $scriptPath) { . $scriptPath }
    else { Write-Host "FATAL ERROR: Required utility '$script' not found." -ForegroundColor Red; exit 1 }
}

$global:DebugMode = $Debug
$global:LogMode = $Log

# Initialize AI (for commit messages if repo is dirty)
Initialize-LLM -SkipMenu:$SkipMenu

$global:OperationReport = @()

function Add-ReportEntry {
    param($Name, $Status, $Details)
    $global:OperationReport += [PSCustomObject]@{
        "Layer/Repo" = $Name
        "Status"     = $Status
        "Details"    = $Details
    }
}

# ---------------------------
# Local Helpers
# ---------------------------

function Sanitize-RepoToken {
    param([string]$name)
    if (-not $name) { return "" }
    return $name.ToLower() -replace '\s+', '-' -replace '[^a-z0-9\-]', '-' -replace '-+', '-' -replace '^-|-$', ''
}

function Remove-FailedSubmodule {
    param([string]$Path)
    Log-Warning "Rolling back failed submodule at $Path..."
    git submodule deinit -f $Path 2>$null | Out-Null
    git rm -f $Path 2>$null | Out-Null
    $gitDir = Join-Path (Split-Path -Parent $Path) ".git/modules/$Path"
    if (Test-Path $gitDir) { Remove-Item -Path $gitDir -Recurse -Force | Out-Null }
    if (Test-Path $Path) { Remove-Item -Path $Path -Recurse -Force | Out-Null }
    Log-Debug "Rollback complete for $Path."
}

# ---------------------------
# Git Logic Functions
# ---------------------------

<#
 .SYNOPSIS
    Ensures a local directory is a valid Git repository.
    If dirty, it generates an AI commit message and commits changes.
#>
function Ensure-GitRepo {
    param([string]$Path)

    Push-Location $Path
    try {
        if (-not (Test-Path ".git")) {
            Log-Debug "Initializing Git repo at $Path..."
            git init -b master | Out-Null
            git add -A
            git commit -m "Initial commit" | Out-Null
            Log-Debug "Repo initialized (Fresh)."
        } else {
            # Idempotency Check: Is it clean?
            $status = git status --porcelain
            if (-not [string]::IsNullOrWhiteSpace($status)) {
                Log-Info "Repo exists but is dirty. Generating semantic commit..."

                git add -A

                # Get Diff for AI
                $diffRaw = git diff --staged
                if ($diffRaw) {
                    if ($diffRaw -is [array]) { $diff = $diffRaw -join "`n" } else { $diff = [string]$diffRaw }

                    if ($diff.Length -gt 6000) { $diff = $diff.Substring(0, 6000) + "...(truncated)" }

                    $aiMsg = Get-LLM-CommitMessage -Diff $diff
                    $commitMsg = if ($aiMsg) { $aiMsg } else { "Work in progress (AI Failed)" }
                } else {
                    $commitMsg = "Work in progress"
                }

                git commit -m "$commitMsg" | Out-Null
                Log-Success "Committed: $commitMsg"
            }
        }
    } catch {
        Log-Error "Error ensuring repo at ${Path}: $_"
        throw $_
    } finally {
        Pop-Location
    }
}

function Ensure-Remote-And-Push {
    param([string]$Path, [string]$RemoteUrl)

    Push-Location $Path
    try {
        $remotes = git remote
        if ($remotes -contains "origin") {
            $currentUrl = git remote get-url origin
            if ($currentUrl -ne $RemoteUrl) {
                Log-Warning "Updating remote origin to $RemoteUrl"
                git remote set-url origin $RemoteUrl
            }
        } else {
            git remote add origin $RemoteUrl
            Log-Debug "Added remote origin -> $RemoteUrl"
        }

        if ($global:PushEnabled) {
            Log-Debug "Pushing to remote..."
            git push -u origin --all 2>&1 | Out-Null
        }
    } catch {
        Log-Error "Error syncing remote at ${Path}: $_"
        throw $_
    } finally {
        Pop-Location
    }
}

function Ensure-Submodule {
    param([string]$RootPath, [string]$LayerDirName, [string]$LayerRemoteUrl)

    Push-Location $RootPath
    $layerPath = "layers/$LayerDirName"

    try {
        # Check if already tracked in index
        git ls-files --error-unmatch $layerPath 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Log-Debug "Submodule '$layerPath' is already tracked. Skipping."
            return
        }

        Log-Debug "Adding submodule: $LayerDirName..."

        $err = git submodule add $LayerRemoteUrl $layerPath 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Git Submodule Add Failed: $err" }

        git commit -m "Add $LayerDirName as submodule" 2>&1 | Out-Null

        if ($global:PushEnabled) {
            git push origin --all 2>&1 | Out-Null
        }
        Log-Debug "Submodule linked."

    } catch {
        Log-Error "Failed to add submodule ${LayerDirName}. Initiating rollback."
        Remove-FailedSubmodule -Path $layerPath
        throw $_
    } finally {
        Pop-Location
    }
}

# ---------------------------
# Main Execution
# ---------------------------

$global:PushEnabled = $Push
$global:AccountType = "User"

# 1. Safety Check
Test-ProjectRoot

# 2. Interactive Menus
if (-not $SkipMenu) {
    $modeOptions = @("Manage & Push (Default)", "Manage Local Only", "Quit")
    $selectedMode = Show-Menu -Title "Git Repository Manager: Select Mode" -Options $modeOptions -MultiSelect $false

    switch ($selectedMode) {
        "Manage & Push (Default)" { $global:PushEnabled = $true }
        "Manage Local Only"       { $global:PushEnabled = $false }
        "Quit"                    { exit 0 }
    }

    if ($global:PushEnabled) {
        $accountOptions = @("Personal User Account (Default)", "Organization Account")
        $selectedAccount = Show-Menu -Title "Where should repositories be created?" -Options $accountOptions -MultiSelect $false

        if ($selectedAccount -eq "Organization Account") {
            $global:AccountType = "Organization"
            if ($GitHubOrg -eq "steve-r-lewis") {
                Write-Host "Enter Organization Name:" -ForegroundColor Yellow
                $orgInput = Read-Host
                if (-not [string]::IsNullOrWhiteSpace($orgInput)) { $GitHubOrg = $orgInput }
            }
        }
    }
}

# 3. Config
if (-not $SkipMenu -and -not $Debug -and -not $Log) {
    $configOptions = @("Debug Mode", "Enable Logging")
    $selectedConfig = Show-Menu -Title "Configuration" -Options $configOptions -MultiSelect $true -ClearScreen $true

    if ($selectedConfig -contains "Debug Mode") { $global:DebugMode = $true }
    if ($selectedConfig -contains "Enable Logging") { $global:LogMode = $true }
}

Initialize-Logger -LogToFile $global:LogMode -DebugMode $global:DebugMode -LogNamePrefix "gitManageRepos"

# 4. Execution
Log-Empty
Log-Info "Starting Repository Management..."
Log-Empty
Log-Divider

if ($global:PushEnabled) {
    Log-Info "Mode: Remote Sync Enabled | Target: $global:AccountType ($GitHubOrg)"
} else {
    Log-Warning "Mode: Local Management Only"
}

try {
    $rootPath = Resolve-Path "."
    $rootRepoName = Split-Path $rootPath -Leaf

    # --- ROOT ---
    Write-Progress -Activity "Repo Management" -Status "Processing Root" -PercentComplete 0
    try {
        Ensure-GitRepo -Path $rootPath

        if ($global:PushEnabled) {
            $rootRemote = Ensure-GitHubRepo -RepoName $rootRepoName -GitHubOrgParam $GitHubOrg
            Ensure-Remote-And-Push -Path $rootPath -RemoteUrl $rootRemote
        }

        Add-ReportEntry -Name "ROOT: $rootRepoName" -Status "Success" -Details "Managed"
    } catch {
        Add-ReportEntry -Name "ROOT: $rootRepoName" -Status "Failed" -Details $_.Exception.Message
        throw $_
    }

    # --- LAYERS ---
    $layersPath = Join-Path $rootPath "layers"
    if (-not (Test-Path $layersPath)) { New-Item -ItemType Directory -Path $layersPath | Out-Null }

    $layers = Get-ChildItem -Path $layersPath -Directory
    $totalLayers = $layers.Count
    $processed = 0

    foreach ($layer in $layers) {
        $processed++
        $percent = [int](($processed / $totalLayers) * 100)
        Write-Progress -Activity "Repo Management" -Status "Layer ($processed/$totalLayers): $($layer.Name)" -PercentComplete $percent

        $layerDirName = $layer.Name
        $sanitised = Sanitize-RepoToken $layerDirName
        $layerRepoName = "nuxt4-layer-$sanitised"

        Log-Debug "Processing layer '$layerDirName'..."

        try {
            Ensure-GitRepo -Path $layer.FullName

            if ($global:PushEnabled) {
                $layerRemoteUrl = Ensure-GitHubRepo -RepoName $layerRepoName -GitHubOrgParam $GitHubOrg
                Ensure-Remote-And-Push -Path $layer.FullName -RemoteUrl $layerRemoteUrl
                Ensure-Submodule -RootPath $rootPath -LayerDirName $layerDirName -LayerRemoteUrl $layerRemoteUrl
                Add-ReportEntry -Name "LAYER: $layerDirName" -Status "Success" -Details "Synced & Linked"
            } else {
                Add-ReportEntry -Name "LAYER: $layerDirName" -Status "Success" -Details "Local Verified"
            }
        } catch {
            Log-Error "Failed to process layer '$layerDirName': $_"
            Add-ReportEntry -Name "LAYER: $layerDirName" -Status "Failed" -Details "See Logs"
        }
    }

    Log-Success "Operation Completed."

} catch {
    Log-Error "Fatal error: $_"
    Add-ReportEntry -Name "Global" -Status "Fatal" -Details $_.Exception.Message
} finally {
    Write-Progress -Activity "Repo Management" -Completed

    Log-Empty
    Log-Divider
    Log-Raw " MANAGEMENT SUMMARY " -Color Cyan
    Log-Divider
    if ($global:OperationReport.Count -gt 0) {
        $global:OperationReport | Format-Table -AutoSize | Out-String | Log-Raw
    }
    Stop-Logger
}
