#!/usr/bin/env pwsh

<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/gitManageCommits.ps1
 @version:    1.4.0
 @createDate: 2025 Dec 04
 @createTime: 21:23
 @author:     Steve R Lewis

 ================================================================================

 @description:
 Automates Git commits across the Monorepo (Root + Layers).
 - Detects changes in git repositories.
 - Stages changes automatically.
 - Uses the active LLM Provider (Gemini/Ollama) to generate semantic commit messages.
 - Offers interactive review (Commit, Custom Message, Skip).
 - Auto-pushes on confirmation.

 ================================================================================

 @notes: Revision History

 V1.4.0, 20251208-00:00
 - Refactored to use the provider-agnostic `llm.ps1` gateway.
 - Replaced `Get-Gemini-CommitMessage` with `Get-LLM-CommitMessage`.
 - Added `Initialize-LLM` step to handle provider selection.

 V1.3.0, 20251206-21:35
 - Increased API throttling from 500ms to 2 seconds to respect free tier rate limits.

 V1.2.0, 20251205-00:35
 Added Interactive Config Menu.
 Fixed "Substring" crash by forcing string conversion.
 Added rate-limit throttling for LLM API.

 V1.1.0, 20251204-21:30
 Refactored to use secure utilities/gemini.ps1 and standardized logging.
 Renamed from manageGitCommits to gitManageCommits.

 V1.0.0, 20251204-21:23
 Initial creation and release of gitManageCommits.ps1

 ================================================================================
#>

param(
    [switch]$Debug,
    [switch]$Log,
    [switch]$SkipMenu
)

# ---------------------------
# Configuration & Imports
# ---------------------------
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$utilitiesPath = Join-Path $PSScriptRoot "utilities"
# CHANGED: Import llm.ps1 and llm-messages.ps1 instead of gemini.ps1
$requiredScripts = @("logger.ps1", "llm.ps1", "llm-messages.ps1", "showMenu.ps1", "project.ps1")

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
    $selections = Show-Menu -Title "Git Commit Manager Config" -Options $configOptions -MultiSelect $true -ClearScreen $true

    if ($selections -contains "Enable Logging") { $global:LogMode = $true }
    if ($selections -contains "Enable Debug Mode") { $global:DebugMode = $true }
}

Initialize-Logger -LogToFile $global:LogMode -DebugMode $global:DebugMode -LogNamePrefix "gitManageCommits"

# CHANGED: Initialize the generic LLM Gateway
Initialize-LLM -SkipMenu:$SkipMenu

# ---------------------------
# Helper Functions
# ---------------------------

function Process-Repo {
    param($RepoPath)

    Push-Location $RepoPath
    $repoName = Split-Path $RepoPath -Leaf

    try {
        # Check for changes
        if (git status --porcelain) {
            Log-Info "[$repoName] Changes detected."

            # Stage all changes
            git add -A 2>&1 | Out-Null

            # FORCE STRING: Join array of lines into single string
            $diffRaw = git diff --staged
            if ($diffRaw -is [array]) {
                $diff = $diffRaw -join "`n"
            } else {
                $diff = [string]$diffRaw
            }

            if ([string]::IsNullOrWhiteSpace($diff)) {
                Log-Warning "[$repoName] Staged changes are empty (binary files?). Skipping."
                return
            }

            if ($diff.Length -gt 6000) {
                $diff = $diff.Substring(0, 6000) + "...(truncated)"
            }

            # Get AI Suggestion
            Write-Host " -> Analyzing changes with AI..." -ForegroundColor DarkGray

            # Rate Limit Protection: Sleep to respect free tiers
            Start-Sleep -Seconds 2

            # CHANGED: Use Generic Message function
            $aiMsg = Get-LLM-CommitMessage -Diff $diff

            if (-not $aiMsg) {
                Log-Error "Failed to generate message for $repoName"
                return
            }

            # Interactive Decision
            $menuTitle = "Repo: $repoName | Proposed: '$aiMsg'"
            $options = @("Accept & Push", "Enter Custom Message", "Skip")

            # ClearScreen False to keep context visible
            $choice = Show-Menu -Title $menuTitle -Options $options -MultiSelect $false -ClearScreen $false

            switch ($choice) {
                "Accept & Push" {
                    git commit -m "$aiMsg" | Out-Null
                    git push 2>&1 | Out-Null
                    Log-Success "[$repoName] Pushed: $aiMsg"
                }
                "Enter Custom Message" {
                    $customMsg = Read-Host "Enter commit message"
                    if (-not [string]::IsNullOrWhiteSpace($customMsg)) {
                        git commit -m "$customMsg" | Out-Null
                        git push 2>&1 | Out-Null
                        Log-Success "[$repoName] Pushed: $customMsg"
                    } else {
                        Log-Warning "Empty message. Skipping."
                    }
                }
                "Skip" {
                    Log-Info "Skipped $repoName"
                }
            }
        } else {
            Log-Debug "[$repoName] Clean."
        }
    } catch {
        Log-Error "Error processing $repoName : $_"
    } finally {
        Pop-Location
    }
}

# ---------------------------
# Main Execution
# ---------------------------

# Safety Check
Test-ProjectRoot

$rootPath = (Get-Location).Path
$layersPath = Join-Path $rootPath "layers"

Log-Info "Scanning repositories..."

# 1. Process Root
Process-Repo -RepoPath $rootPath

# 2. Process Layers
if (Test-Path $layersPath) {
    $layers = Get-ChildItem -Path $layersPath -Directory
    foreach ($layer in $layers) {
        if (Test-Path (Join-Path $layer.FullName ".git")) {
            Process-Repo -RepoPath $layer.FullName
        }
    }
}

Log-Success "Sync complete."
