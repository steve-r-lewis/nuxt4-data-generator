#!/usr/bin/env pwsh

<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/provisionProject.ps1
 @version:    1.0.0
 @createDate: 2025 Dec 06
 @createTime: 00:26
 @author:     Steve R Lewis

 ================================================================================

 @description:
 "Zero to Hero" Project Bootstrapper.
 1. Validates System Prerequisites (Node, PNPM, Git).
 2. Sets up Environment Variables (.env).
 3. Hydrates Dependencies (via nuxtManager).
 4. Initializes Git Submodules (via gitManageRepos).
 5. Configures VS Code (Optional).

 ================================================================================

 @notes: Revision History

 V1.0.0, 20251206-00:26
 Initial creation and release of provisionProject.ps1

 ================================================================================
#>

param(
    [switch]$Debug,
    [switch]$Log,
    [switch]$SkipMenu
)

# ---------------------------
# Configuration
# ---------------------------
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$utilitiesPath = Join-Path $PSScriptRoot "utilities"
$requiredScripts = @("logger.ps1", "showMenu.ps1", "fileSystem.ps1")

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
    $selections = Show-Menu -Title "Provisioning Config" -Options $configOptions -MultiSelect $true -ClearScreen $true
    if ($selections -contains "Enable Logging") { $global:LogMode = $true }
    if ($selections -contains "Enable Debug Mode") { $global:DebugMode = $true }
}

Initialize-Logger -LogToFile $global:LogMode -DebugMode $global:DebugMode -LogNamePrefix "provisionProject"

# ---------------------------
# Logic Functions
# ---------------------------

function Test-Command {
    param($Name)
    if (Get-Command $Name -ErrorAction SilentlyContinue) { return $true }
    return $false
}

function Check-Prerequisites {
    Log-Info "Phase 1: System Health Check"

    # 1. Check Node.js (Requirement: >= 20.0.0 from package.json)
    if (Test-Command "node") {
        $nodeVerRaw = node -v
        $nodeVer = $nodeVerRaw -replace 'v',''
        if ([Version]$nodeVer -lt [Version]"20.0.0") {
            Log-Error "Node.js $nodeVer is too old. Please install v20.0.0+."
            throw "Prerequisite Check Failed"
        } else {
            Log-Debug "Node.js $nodeVer (OK)"
        }
    } else {
        Log-Error "Node.js not found."
        throw "Prerequisite Check Failed"
    }

    # 2. Check Git
    if (-not (Test-Command "git")) {
        Log-Error "Git not found."
        throw "Prerequisite Check Failed"
    }

    # 3. Check PNPM
    if (Test-Command "pnpm") {
        $pnpmVer = (pnpm -v)
        Log-Debug "PNPM $pnpmVer (OK)"
    } else {
        Log-Warning "PNPM not found. Installing via NPM..."
        try {
            npm install -g pnpm@10.24.0
            Log-Success "PNPM installed."
        } catch {
            Log-Error "Failed to install PNPM. Please install manually."
            throw $_
        }
    }

    Log-Success "System prerequisites met."
}

function Setup-Environment {
    Log-Info "Phase 2: Environment Configuration"
    $root = (Get-Location).Path
    $envPath = Join-Path $root ".env"
    $envExample = Join-Path $root ".env.example"

    if (-not (Test-Path $envPath)) {
        if (Test-Path $envExample) {
            Copy-Item $envExample $envPath
            Log-Success "Created .env from template."
        } else {
            # Create a blank starter if no example exists
            $content = "# Nuxt 4 Monorepo Config`nGEMINI_API_CREDENTIALS=''`nGITHUB_TOKEN=''`n"
            Set-ContentAtomic -Path $envPath -Value $content
            Log-Warning "Created blank .env (No template found)."
        }
    } else {
        Log-Debug ".env already exists."
    }

    # Interactive Gemini Check
    if (-not $env:GEMINI_API_CREDENTIALS) {
        # Try to read from the file we might have just created
        $envContent = Get-Content $envPath -Raw
        if ($envContent -match "GEMINI_API_CREDENTIALS='(.+?)'") {
            if (-not [string]::IsNullOrWhiteSpace($matches[1])) {
                $env:GEMINI_API_CREDENTIALS = $matches[1]
                Log-Debug "Loaded Gemini Credentials from .env"
            }
        }

        if (-not $env:GEMINI_API_CREDENTIALS -and -not $SkipMenu) {
            Log-Divider
            Log-Raw "OPTIONAL: Gemini AI Setup" -Color Yellow
            Log-Raw "This is required for Auto-Versioning and Commit generation." -Color Gray
            $choice = Show-Menu -Title "Configure Gemini API now?" -Options @("Yes", "No (Skip)") -MultiSelect $false -ClearScreen $false

            if ($choice -eq "Yes") {
                $key = Read-Host "Enter your Gemini API Key"
                if (-not [string]::IsNullOrWhiteSpace($key)) {
                    $json = '{"APIKey": "' + $key + '", "Model": "gemini-2.0-flash"}'
                    $env:GEMINI_API_CREDENTIALS = $json

                    # Persist to .env (Simple append logic)
                    Add-Content -Path $envPath -Value "`nGEMINI_API_CREDENTIALS='$json'"
                    Log-Success "Gemini Key saved to session and appended to .env."
                }
            }
        }
    }
}

function Setup-VSCode {
    Log-Info "Phase 5: Editor Configuration"
    $root = (Get-Location).Path
    $vscodeDir = Join-Path $root ".vscode"

    # Handle Extensions
    $extExample = Join-Path $vscodeDir "extensions.json.example"
    $extReal = Join-Path $vscodeDir "extensions.json"

    if ((Test-Path $extExample) -and (-not (Test-Path $extReal))) {
        Copy-Item $extExample $extReal
        Log-Success "Initialized VS Code Recommended Extensions."
    }

    # Handle Settings
    $setExample = Join-Path $vscodeDir "settings.json.example"
    $setReal = Join-Path $vscodeDir "settings.json"

    if ((Test-Path $setExample) -and (-not (Test-Path $setReal))) {
        Copy-Item $setExample $setReal
        Log-Success "Initialized VS Code Workspace Settings."
    }
}

# ---------------------------
# Execution Flow
# ---------------------------

Log-Raw "==========================================" -Color Cyan
Log-Raw "   NUXT 4 MONOREPO: BOOTSTRAP WIZARD      " -Color Cyan
Log-Raw "==========================================" -Color Cyan
Log-Empty

try {
    # 1. System Check
    Check-Prerequisites

    # 2. Secrets & Env
    Setup-Environment

    # 3. Hydration (Delegated to nuxtManager)
    Log-Info "Phase 3: Installing Dependencies..."
    $nuxtMgr = Join-Path $PSScriptRoot "nuxtManager.ps1"
    # Call with SkipMenu to force 'Clean & Reset' defaults, but pass Debug/Log flags
    if (Test-Path $nuxtMgr) {
        & $nuxtMgr -SkipMenu -Log:$global:LogMode -Debug:$global:DebugMode
    } else {
        Log-Error "Could not find nuxtManager.ps1. Skipping hydration."
    }

    # 4. Git Setup (Delegated to gitManageRepos)
    Log-Info "Phase 4: Initializing Repositories..."
    $gitInit = Join-Path $PSScriptRoot "gitManageRepos.ps1"
    # Call Local Only (no push)
    if (Test-Path $gitInit) {
        & $gitInit -SkipMenu -Push:$false -Log:$global:LogMode -Debug:$global:DebugMode
    } else {
        Log-Error "Could not find gitManageRepos.ps1. Skipping git setup."
    }

    # 5. Editor
    Setup-VSCode

    Log-Empty
    Log-Divider "="
    Log-Success "PROJECT READY! 🚀"
    Log-Raw "Run 'pnpm dev' to start the development server." -Color Cyan
    Log-Divider "="

} catch {
    Log-Error "Provisioning failed: $_"
    Add-ReportEntry -File "Provisioning" -Action "Fatal" -Details $_
    exit 1
} finally {
    Stop-Logger
}
