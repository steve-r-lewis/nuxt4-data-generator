#!/usr/bin/env pwsh

<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/addCodeDocumentation.ps1
 @version:    1.0.0
 @createDate: 2025 Dec 08
 @createTime: 01:57
 @author:     Steve R Lewis

 ================================================================================

 @description:
 AI-Powered Code Documenter.
 - Single File Mode: Documents one file.
 - Batch Mode: Recursively scans a directory and prompts for file types.
 - Safety: Creates mirrored backups in ~/scripts/backup/.

 ================================================================================

 @notes: Revision History

 V1.0.0, 20251208-01:57
 Initial creation and release of addCodeDocumentation.ps1

 ================================================================================
#>

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$Target,

    [switch]$Debug,
    [switch]$Log,
    [switch]$NoBackup
)

# ---------------------------
# Configuration
# ---------------------------
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$utilitiesPath = Join-Path $PSScriptRoot "utilities"
$requiredScripts = @("logger.ps1", "llm.ps1", "fileSystem.ps1", "project.ps1", "showMenu.ps1", "paths.ps1")

foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path $utilitiesPath $script
    if (Test-Path $scriptPath) { . $scriptPath }
    else { Write-Host "FATAL: Missing utility '$script'" -ForegroundColor Red; exit 1 }
}

$global:DebugMode = $Debug
$global:LogMode = $Log

Initialize-Logger -LogToFile $global:LogMode -DebugMode $global:DebugMode -LogNamePrefix "autoDoc"
Initialize-LLM -SkipMenu:$false

# ---------------------------
# Logic Functions
# ---------------------------

function Create-Backup {
    param($SourcePath, $ProjectRoot)

    if ($NoBackup) { return }

    # Calculate Relative Path (e.g. layers/auth/index.ts)
    # We use Get-RelativePath logic but need raw string for join, not "~/"
    $relPath = $SourcePath.Replace($ProjectRoot, "").TrimStart("\/").TrimStart("/")

    # Construct Backup Path: ~/scripts/backup/<relPath>
    $backupRoot = Join-Path $ProjectRoot "scripts/backup"
    $destPath = Join-Path $backupRoot $relPath

    $destDir = Split-Path $destPath -Parent

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    Copy-Item -LiteralPath $SourcePath -Destination $destPath -Force
    Log-Debug "Backup created: $relPath"
}

function Document-File {
    param($FilePath, $RootPath)

    $fileName = Split-Path $FilePath -Leaf
    Log-Info "Processing: $fileName"

    # 1. Backup
    Create-Backup -SourcePath $FilePath -ProjectRoot $RootPath

    # 2. Read
    $code = Get-Content -LiteralPath $FilePath -Raw

    # 3. AI Processing
    $sysPrompt = @"
You are a Senior Technical Writer and Lead Developer.
Your task is to document the provided code file to Enterprise Standards.

Rules:
1. DO NOT change any logic, variable names, or functionality.
2. Add a file-level JSDoc header if missing (Project, File, Author, Description).
   - Use the filename provided.
3. Add JSDoc blocks (/** ... */) to all exported functions, classes, and interfaces.
   - Include @param and @returns tags with types.
4. Add concise inline comments (// ...) explaining complex logic or regex.
5. If it is a Vue file, document the <script setup> block and Props.
6. Output ONLY the valid, runnable code. Do not wrap in Markdown fences.
"@

    $userPrompt = "Filename: $fileName`n`nDocument this code:`n`n$code"

    Write-Host " -> Asking AI..." -ForegroundColor DarkGray

    # Low temperature for precision
    $documentedCode = Invoke-LLM -SystemPrompt $sysPrompt -Prompt $userPrompt -Temperature 0.2

    if (-not $documentedCode) {
        Log-Error "AI returned empty response for $fileName. Skipping."
        return
    }

    # Safety: Strip markdown fences
    $documentedCode = $documentedCode -replace '^```[a-z]*\s*', '' -replace '\s*```$', ''

    # 4. Write
    Set-ContentAtomic -Path $FilePath -Value $documentedCode
    Log-Success "Updated $fileName"
}

# ---------------------------
# Main Execution
# ---------------------------

Test-ProjectRoot
$projectRoot = (Get-Location).Path

# 1. Resolve Target (Interactive)
if ([string]::IsNullOrWhiteSpace($Target)) {
    Log-Empty
    Log-Raw "Auto-Documentation Wizard" -Color Cyan
    Log-Raw "Enter the path to a file OR a directory to scan." -Color Gray

    while ([string]::IsNullOrWhiteSpace($Target)) {
        $input = Read-Host "Target Path (e.g. layers/auth/)"
        if (-not [string]::IsNullOrWhiteSpace($input)) {
            # Resolve relative paths
            $resolved = $input
            if (-not (Test-Path $resolved)) {
                Log-Warning "Path not found: $input"
            } else {
                $Target = Resolve-Path $resolved
            }
        }
    }
} else {
    # Resolve CLI argument
    if (-not (Test-Path $Target)) {
        Log-Error "Path not found: $Target"
        exit 1
    }
    $Target = Resolve-Path $Target
}

$item = Get-Item $Target

# 2. Directory Mode (Batch)
if ($item.PSIsContainer) {
    Log-Info "Directory detected: $($item.Name)"

    # Extension Selection Menu
    $extOptions = @(".ts", ".vue", ".js", ".json")
    $selectedExts = Show-Menu -Title "Select File Types to Document" -Options $extOptions -MultiSelect $true -ClearScreen $true

    if ($selectedExts.Count -eq 0) {
        Log-Warning "No extensions selected. Exiting."
        exit
    }

    # Recursive Scan (Using fileSystem utility for exclusion logic would be best, but simple scan here for specific target)
    $files = Get-ChildItem -Path $item.FullName -Recurse -File | Where-Object { $selectedExts -contains $_.Extension }

    if ($files.Count -eq 0) {
        Log-Warning "No matching files found in directory."
        exit
    }

    Log-Info "Found $($files.Count) files to process."

    foreach ($file in $files) {
        Document-File -FilePath $file.FullName -RootPath $projectRoot
    }

}
# 3. Single File Mode
else {
    Document-File -FilePath $item.FullName -RootPath $projectRoot
}

Log-Success "Documentation Run Complete."
Log-Info "Backups located in: ~/scripts/backup/"
Stop-Logger
