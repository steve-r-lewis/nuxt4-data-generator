#!/usr/bin/env pwsh

<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/nuxtExtractLayerDescriptions.ps1
 @version:    1.4.2
 @createDate: 2025 Dec 04
 @createTime: 21:45
 @author:     Steve R Lewis

 ================================================================================

 @description:
 Analyzes the project 'layers' directory and extracts documentation from
 package.json, nuxt.config.ts.old, and README.md.
 Outputs a timestamped Markdown report.

 ================================================================================

 @notes: Revision History

 V1.4.2, 20251208-01:35
 - Fixed "Count cannot be found" crash by wrapping the Extract-Content call
   in an array subexpression @(...). This forces the result to be an array
   regardless of whether the function returns $null, a single string, or a list.

 V1.4.1, 20251208-01:30
 - Fixed "Property Count cannot be found" error.
 - Forced Extract-Content to return arrays @() to satisfy Strict Mode checks.

 V1.4.0, 20251208-00:15
 - Integrated `llm.ps1` gateway.
 - Upgraded code file parsing to use AI summarization via `Invoke-LLM`.

 V1.3.0, 20251206-20:00
 Added File Type Selection menu and wildcard file support.
 Expanded Extract-Content to parse .vue and .ts files for @description tags.

 V1.2.0, 20251204-22:45
 Added interactive configuration menu (Show-Menu).

 V1.1.0, 20251204-12:00
 Refactored to use shared utilities (logger, project) and enforcing root context.

 V1.0.0, 20251204-21:45
 Initial creation and release of nuxtExtractLayerDescriptions.ps1

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
$requiredScripts = @("logger.ps1", "project.ps1", "showMenu.ps1", "llm.ps1")

foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path $utilitiesPath $script
    if (Test-Path $scriptPath) { . $scriptPath }
    else { Write-Host "FATAL: Missing utility '$script'" -ForegroundColor Red; exit 1 }
}

# ---------------------------
# Helper Functions
# ---------------------------

function Extract-Content {
    param([string]$file)

    if (-not (Test-Path $file)) { return @() }

    $fileName = Split-Path $file -Leaf
    $extension = [System.IO.Path]::GetExtension($file)

    # 1. Handle JSON
    if ($fileName -eq "package.json") {
        try {
            $json = Get-Content $file -Raw | ConvertFrom-Json
            if ($json.description) {
                return "`"$($json.description)`""
            } else {
                return '"No description found"'
            }
        } catch {
            Log-Warning "Error parsing package.json at $file"
            return '"Error parsing package.json"'
        }
    }
    # 2. Handle Markdown
    elseif ($extension -eq ".md") {
        # Return first 30 lines of README
        return Get-Content $file -TotalCount 30
    }
    # 3. Handle Code Files (TS, Vue, JS) - UPGRADED TO AI
    elseif ($extension -in @(".ts", ".js", ".vue")) {
        $content = Get-Content $file -Raw

        # Use AI to summarize
        $summary = Invoke-LLM -SystemPrompt "Summarize this code file in 1 sentence. Focus on its responsibility." -Prompt $content

        if ($summary) {
            return "@ai-summary: $summary"
        } else {
            return "(AI summarization failed)"
        }
    }

    return @()
}

# ---------------------------
# Main Execution
# ---------------------------

$global:DebugMode = $Debug
$global:LogMode = $Log

# Defaults
$searchPatterns = @("package.json", "nuxt.config.ts.old", "README.md")

# --- Interactive Menu ---
if (-not $SkipMenu -and -not $Log -and -not $Debug) {
    # Menu 1: Configuration
    $configOptions = @("Enable Logging", "Enable Debug Mode")
    $selections = Show-Menu -Title "Step 1: Configuration" -Options $configOptions -MultiSelect $true -ClearScreen $true

    if ($selections -contains "Enable Logging") { $global:LogMode = $true }
    if ($selections -contains "Enable Debug Mode") { $global:DebugMode = $true }

    # Menu 2: File Selection
    $fileOptions = @("package.json", "nuxt.config.ts.old", "*.vue", "*.ts", "README.md")
    $selectedFiles = Show-Menu -Title "Step 2: Select File Types to Scan" -Options $fileOptions -MultiSelect $true -ClearScreen $true

    if ($selectedFiles.Count -gt 0) {
        $searchPatterns = $selectedFiles
    } else {
        Write-Host "No files selected. Exiting." -ForegroundColor Yellow
        exit 0
    }
}

# Initialize Logger
Initialize-Logger -LogToFile $global:LogMode -DebugMode $global:DebugMode -LogNamePrefix "extract-layer-descriptions"

# Initialize AI
Initialize-LLM -SkipMenu:$SkipMenu

Log-Info "Starting Layer Description Extraction..."
if ($global:DebugMode) { Log-Debug "Search Patterns: $($searchPatterns -join ', ')" }

Log-Empty

try {
    # 1. Safety Check
    Test-ProjectRoot
    $rootPath = (Get-Location).Path

    # 2. Path Setup
    $layersDir  = Join-Path $rootPath "layers"
    $outputBase = Join-Path $rootPath "scripts/output"

    if (-not (Test-Path $layersDir)) {
        throw "Layers directory not found at: $layersDir"
    }

    if (-not (Test-Path $outputBase)) {
        New-Item -ItemType Directory -Path $outputBase -Force | Out-Null
        Log-Debug "Created output directory: $outputBase"
    }

    # 3. Processing
    Log-Info "Scanning layers in: $layersDir"

    $tocEntries = [System.Collections.Generic.List[string]]::new()
    $bodyContent = [System.Text.StringBuilder]::new()

    $layerFolders = Get-ChildItem -Path $layersDir -Directory | Sort-Object Name

    foreach ($folder in $layerFolders) {
        $layerName = "@monorepo/$($folder.Name)"
        Log-Debug "Processing $layerName..."

        # Build TOC
        $anchorId = $layerName.ToLower() -replace '@','%40' -replace ' ','-' -replace '/',''
        $tocEntries.Add("- [$layerName](#$anchorId)")

        # Build Body Header
        [void]$bodyContent.AppendLine("---")
        [void]$bodyContent.AppendLine("# Nuxt4 Layer: $layerName")
        [void]$bodyContent.AppendLine("")

        # Scan for selected file patterns
        foreach ($pattern in $searchPatterns) {
            $pathToCheck = Join-Path $folder.FullName $pattern

            # Use Get-ChildItem to resolve wildcards (e.g. *.vue)
            $foundFiles = Get-ChildItem -Path $pathToCheck -ErrorAction SilentlyContinue | Sort-Object Name

            foreach ($fileItem in $foundFiles) {
                $relName = $fileItem.Name # Just filename for header

                # FIX: Force result into array using @(...) to guarantee .Count property exists
                $extracted = @(Extract-Content -file $fileItem.FullName)

                # Only output if we found content (or if it's a critical file like package.json)
                if ($extracted.Count -gt 0 -or $fileItem.Name -eq "package.json") {
                    [void]$bodyContent.AppendLine("## $relName")
                    [void]$bodyContent.AppendLine('```')

                    if ($extracted.Count -eq 0) {
                        [void]$bodyContent.AppendLine("(No description found)")
                    } else {
                        foreach ($line in $extracted) {
                            [void]$bodyContent.AppendLine($line)
                        }
                    }

                    [void]$bodyContent.AppendLine('```')
                    [void]$bodyContent.AppendLine("")
                }
            }
        }
    }

    # 4. Output Generation
    $timeStamp = Get-Date -Format "yyyyMMdd-HHmm"
    $outputFile = Join-Path $outputBase "monorepo-layer-descriptions-$timeStamp.md"

    Log-Info "Generating Markdown Report..."

    # Write Header
    "# Layer Descriptions (Generated: $timeStamp)" | Out-File $outputFile -Encoding utf8
    "Search Patterns: $($searchPatterns -join ', ')" | Out-File $outputFile -Append -Encoding utf8
    "" | Out-File $outputFile -Append -Encoding utf8

    # Write TOC
    "## Table of Contents" | Out-File $outputFile -Append -Encoding utf8
    $tocEntries | Out-File $outputFile -Append -Encoding utf8
    "" | Out-File $outputFile -Append -Encoding utf8

    # Write Body
    $bodyContent.ToString() | Out-File $outputFile -Append -Encoding utf8

    Log-Empty
    Log-Success "Report generated: $outputFile"

} catch {
    Log-Error "Extraction failed: $_"
    exit 1
} finally {
    Stop-Logger
}
