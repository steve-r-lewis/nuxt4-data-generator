#!/usr/bin/env pwsh

<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/nuxtCreateLayer.ps1
 @version:    1.3.0
 @createDate: 2025 Dec 04
 @createTime: 20:40
 @author:     Steve R Lewis

 ================================================================================

.SYNOPSIS
    Provisions a new Nuxt layer using AI (Gemini or Ollama).

.DESCRIPTION
 Provisions a new Nuxt layer.
 - Scaffolds directory structure.
 - Generates package.json, nuxt.config.ts.old, and README.md.
 - Uses the active LLM to write contextual descriptions based on user purpose.

 ================================================================================

 @notes: Revision History

 V1.3.0, 20251208-00:05
 - Refactored to use `llm.ps1` gateway.
 - Replaced `Invoke-Gemini` with `Invoke-LLM`.
 - Added `Initialize-LLM` step.

 V1.2.0, 20251204-14:30
 Added interactive configuration menu (Show-Menu) and SkipMenu parameter.

 V1.1.0, 20251204-08:30
 Refactored to use secure utilities/gemini.ps1 and fileSystem.ps1.
 Removed hardcoded API keys.

 V1.0.0, 20251204-20:40
 Initial creation and release of nuxtCreateLayer.ps1

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
# CHANGED: Use llm.ps1
$requiredScripts = @("logger.ps1", "llm.ps1", "fileSystem.ps1", "showMenu.ps1")

foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path $utilitiesPath $script
    if (Test-Path $scriptPath) { . $scriptPath }
    else { Write-Host "FATAL: Missing utility '$script'" -ForegroundColor Red; exit 1 }
}

# ---------------------------
# File Templates (Raw Strings)
# ---------------------------

$TemplateGitIgnore = @'
# =============================================
# 1. Package Managers & Dependency Stores
# =============================================
**/.git
**/node_modules/
'@

$TemplatePkgJson = @'
{
    "name": "{{FULL_PACKAGE_NAME}}",
    "version": "1.0.0",
    "description": "{{DESCRIPTION}}",
    "private": true,
    "type": "module",
    "main": "./nuxt.config.ts.old",
    "exports": {
        ".": {
            "types": "./tsconfig.json",
            "import": "./nuxt.config.ts.old"
        }
    }
}
'@

$TemplateTsConfig = @'
{
    "extends": "../../.nuxt/tsconfig.json"
}
'@

$TemplateLicense = @'
Copyright {{YEAR}} {{AUTHOR}}

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files...
(The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.)
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED...
'@

$TemplateReadme = @'
# {{FULL_PACKAGE_NAME}}

{{DESCRIPTION_LONG}}
'@

$TemplateNuxtConfig = @'
/**
 * ================================================================================
 * @project:    {{FULL_PACKAGE_NAME}}
 * @file:       ~/layers/{{LAYER_NAME}}/nuxt.config.ts.old
 * @version:    1.0.0
 * @createDate: {{DATE}}
 * @createTime: {{TIME}}
 * @author:     {{AUTHOR}}
 * ================================================================================
 * @description:
{{JSDOC_BLOCK}}
 * ================================================================================
 * @notes: Revision History
 * V1.0.0, {{REV_CODE}}
 * Initial creation and release of nuxt.config.ts.old
 * ================================================================================
 */
export default defineNuxtConfig({
  compatibilityDate: "2025-10-08",
  devtools: { enabled: true },
  extends: []
})
'@

# ---------------------------
# Helper Functions
# ---------------------------

function Generate-LayerMetadata {
    param($LayerName, $Purpose)

    Log-Info "Contacting AI for layer descriptions..."

    $sysPrompt = "You are a code scaffolding assistant for a Nuxt 4 Monorepo."
    $userPrompt = @"
Context: Generating a layer named '@monorepo/$LayerName'.
User Purpose: "$Purpose".
Task: Return a raw JSON object with 3 keys:
1. "readme": A 2 to 3 paragraph technical description.
2. "jsdoc": A single paragraph (approx 60 words) describing the config file. Start with "This configuration file defines...".
3. "pkgJson": A short summary (max 20 words).
"@

    # CHANGED: Use generic Invoke-LLM
    $jsonString = Invoke-LLM -SystemPrompt $sysPrompt -Prompt $userPrompt -JsonMode

    if ($jsonString) {
        try {
            return ($jsonString | ConvertFrom-Json)
        } catch {
            Log-Error "Failed to parse AI JSON response."
            Log-Debug "Raw Response: $jsonString"
        }
    }

    Log-Warning "AI Generation failed or returned invalid data. Using defaults."
    return @{
        readme  = "The @monorepo/$LayerName layer. Purpose: $Purpose"
        jsdoc   = "Configuration for $LayerName."
        pkgJson = "Layer for $Purpose"
    }
}

function Write-TemplateFile {
    param($TargetDir, $FileName, $Template, $Replacements)

    $Content = $Template
    foreach ($key in $Replacements.Keys) {
        $Content = $Content.Replace("{{$key}}", $Replacements[$key])
    }

    $fullPath = Join-Path $TargetDir $FileName
    Set-ContentAtomic -Path $fullPath -Value $Content
    Log-Info "Created: $FileName"
}

# ---------------------------
# Main Execution
# ---------------------------

$global:DebugMode = $Debug
$global:LogMode = $Log

# --- Interactive Menu ---
if (-not $SkipMenu -and -not $Log -and -not $Debug) {
    $configOptions = @("Enable Logging", "Enable Debug Mode")
    $selections = Show-Menu -Title "Create Layer Config" -Options $configOptions -MultiSelect $true -ClearScreen $true

    if ($selections -contains "Enable Logging") { $global:LogMode = $true }
    if ($selections -contains "Enable Debug Mode") { $global:DebugMode = $true }
}

# Initialize Logger (Post-Menu)
Initialize-Logger -LogToFile $global:LogMode -DebugMode $global:DebugMode -LogNamePrefix "createLayer"

# CHANGED: Initialize AI Provider
Initialize-LLM -SkipMenu:$SkipMenu

$AuthorName = "Steve R Lewis"
# Resolve path relative to script location
$ProjectRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
$LayersRoot  = Join-Path $ProjectRoot "layers"

Clear-Host
Write-Host "@monorepo Layer Provisioner" -ForegroundColor Cyan
Write-Host "==========================="

# 1. Inputs
$LayerNameRaw = Read-Host "Enter Layer Name (e.g. 'billing')"
if ([string]::IsNullOrWhiteSpace($LayerNameRaw)) {
    Log-Error "Layer name is required."
    exit 1
}

$LayerName = $LayerNameRaw.ToLower().Trim()
$FullPackageName = "@monorepo/$LayerName"
$TargetDir = Join-Path $LayersRoot $LayerName

if (Test-Path $TargetDir) {
    Log-Error "Directory already exists: $TargetDir"
    exit 1
}

$Purpose = Read-Host "Enter a descriptive purpose (for AI context)"
if ([string]::IsNullOrWhiteSpace($Purpose)) { $Purpose = "Utility layer for $LayerName" }

# 2. AI Generation
$AI = Generate-LayerMetadata -LayerName $LayerName -Purpose $Purpose

# 3. Preparation
$DateStr = Get-Date -Format 'yyyy MMM dd'
$TimeStr = Get-Date -Format 'HH:mm'
$RevCode = "{0:yyyyMMdd}-{0:HH:mm}" -f (Get-Date)
$Year    = (Get-Date).Year

# Format JSDoc Block (Word Wrap)
$WrappedDesc = $AI.jsdoc -split ' '
$JSDocBlock = ''
$Line = ' *'
foreach ($Word in $WrappedDesc) {
    if (($Line.Length + $Word.Length) -gt 75) { $JSDocBlock += "$Line`n"; $Line = " * $Word" }
    else { $Line += " $Word" }
}
$JSDocBlock += $Line

# 4. Scaffolding
Log-Info "Scaffolding layer '$LayerName'..."
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

try {
    # package.json
    Write-TemplateFile -TargetDir $TargetDir -FileName 'package.json' -Template $TemplatePkgJson -Replacements @{
        'FULL_PACKAGE_NAME' = $FullPackageName
        'DESCRIPTION'       = $AI.pkgJson
    }

    # tsconfig.json
    Write-TemplateFile -TargetDir $TargetDir -FileName 'tsconfig.json' -Template $TemplateTsConfig -Replacements @{}

    # .gitignore
    Write-TemplateFile -TargetDir $TargetDir -FileName '.gitignore' -Template $TemplateGitIgnore -Replacements @{}

    # LICENSE
    Write-TemplateFile -TargetDir $TargetDir -FileName 'LICENSE' -Template $TemplateLicense -Replacements @{
        'YEAR'   = $Year
        'AUTHOR' = $AuthorName
    }

    # README.md
    Write-TemplateFile -TargetDir $TargetDir -FileName 'README.md' -Template $TemplateReadme -Replacements @{
        'FULL_PACKAGE_NAME' = $FullPackageName
        'DESCRIPTION_LONG'  = $AI.readme
    }

    # nuxt.config.ts.old
    Write-TemplateFile -TargetDir $TargetDir -FileName 'nuxt.config.ts.old' -Template $TemplateNuxtConfig -Replacements @{
        'FULL_PACKAGE_NAME' = $FullPackageName
        'LAYER_NAME'        = $LayerName
        'DATE'              = $DateStr
        'TIME'              = $TimeStr
        'AUTHOR'            = $AuthorName
        'JSDOC_BLOCK'       = $JSDocBlock
        'REV_CODE'          = $RevCode
    }

    Log-Success "Layer provisioned successfully at: $TargetDir"

} catch {
    Log-Error "Scaffolding failed: $_"
    exit 1
} finally {
    Stop-Logger
}
