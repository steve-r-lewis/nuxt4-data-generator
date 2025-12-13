<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/utilities/llm.ps1
 @version:    1.0.0
 @createDate: 2025 Dec 07
 @createTime: 23:49
 @author:     Steve R Lewis

 ================================================================================

 @description:
 Central Gateway for LLM interactions.
 Orchestrates selection between Gemini and Ollama via Menu or Env Var.

 ================================================================================

 @notes: Revision History

 V1.0.0, 20251207-23:49
 Initial creation and release of llm.ps1

 ================================================================================
#>

# Import the concrete implementations
$currentDir = Split-Path $MyInvocation.MyCommand.Path
. (Join-Path $currentDir "gemini.ps1")
. (Join-Path $currentDir "ollama.ps1")
if (-not (Get-Command "Show-Menu" -ErrorAction SilentlyContinue)) {
    . (Join-Path $currentDir "showMenu.ps1")
}

$script:ActiveProvider = "gemini"

function Initialize-LLM {
    param(
        [switch]$SkipMenu
    )

    # 1. Environment Variable Priority
    if ($env:LLM_PROVIDER) {
        $script:ActiveProvider = $env:LLM_PROVIDER.ToLower()
        Log-Debug "LLM Provider set from Environment: $script:ActiveProvider"
        return
    }

    # 2. CI/Non-Interactive Fallback
    if ($SkipMenu) {
        Log-Warning "Non-interactive mode: Defaulting LLM to Gemini."
        $script:ActiveProvider = "gemini"
        return
    }

    # 3. Interactive Menu Selection
    # CHANGED: Ollama is now the first option (Default)
    $options = @("Ollama (Local - Llama3)", "Gemini (Cloud - Google)")

    # CHANGED: ClearScreen set to $true to prevent visual ghosting
    $choice = Show-Menu -Title "Select AI Provider" -Options $options -MultiSelect $false -ClearScreen $true

    if ($choice -match "Ollama") {
        $script:ActiveProvider = "ollama"
        $status = Test-OllamaConnection
        if (-not $status.available) {
            Log-Warning "Ollama server not detected at $($status.url). Ensure 'ollama serve' is running."
        }
    } else {
        $script:ActiveProvider = "gemini"
    }

    Log-Info "AI Provider Active: $script:ActiveProvider"
}

function Invoke-LLM {
    param(
        [Parameter(Mandatory=$true)][string]$Prompt,
        [string]$SystemPrompt,
        [double]$Temperature = 0.7,
        [switch]$JsonMode,
        [string]$ModelOverride
    )

    if ($script:ActiveProvider -eq "ollama") {
        return Invoke-Ollama -Prompt $Prompt -SystemPrompt $SystemPrompt -Temperature $Temperature -JsonMode:$JsonMode -ModelOverride $ModelOverride
    } else {
        return Invoke-Gemini -Prompt $Prompt -SystemPrompt $SystemPrompt -Temperature $Temperature -JsonMode:$JsonMode -ModelOverride $ModelOverride
    }
}
