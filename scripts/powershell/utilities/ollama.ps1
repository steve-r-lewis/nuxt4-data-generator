<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/utilities/ollama.ps1
 @version:    1.2.1
 @createDate: 2025 Dec 07
 @createTime: 22:58
 @author:     Steve R Lewis

 ================================================================================

 @description:
 Ollama API Integration Utility.
 Designed as a plug-and-play alternative to gemini.ps1.
 Handles authentication (if needed), JSON formatting, and system prompts.

 ================================================================================

 @notes: Revision History

 V1.2.1, 20251208-01:15
 Increased Test-Connection timeout to 5 seconds to prevent false negatives on local hardware.

 V1.2.0, 20251208-01:05
 Added missing 'Test-OllamaConnection' function required by the LLM Gateway.

 V1.1.0, 20251207-23:15
 Refactored to match Invoke-Gemini signature and project logging standards.
 Added support for native Ollama 'format: json'.

 V1.0.0, 20251207-22:58
 Initial creation and release of ollama.ps1

 ================================================================================
#>

function Get-OllamaConfig {
    # Defaults
    $baseUrl = "http://localhost:11434"
    $model = "llama3:8b"
    $timeout = 200

    if ($env:OLLAMA_BASE_URL) { $baseUrl = $env:OLLAMA_BASE_URL }
    if ($env:OLLAMA_MODEL)    { $model = $env:OLLAMA_MODEL }
    if ($env:OLLAMA_TIMEOUT)  { $timeout = [int]$env:OLLAMA_TIMEOUT }

    return @{
        BaseUrl = $baseUrl
        Model   = $model
        Timeout = $timeout
    }
}

function Test-OllamaConnection {
    $config = Get-OllamaConfig
    $url = $config.BaseUrl

    Log-Debug "Testing Ollama connection at $url..."

    try {
        # TIMEOUT INCREASED: 2 -> 5 Seconds
        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 5 -ErrorAction Stop

        if ($response -match "Ollama is running") {
            return @{ available = $true; url = $url }
        }
        return @{ available = $false; url = $url }
    } catch {
        Log-Debug "Ollama connection check failed: $_"
        return @{ available = $false; url = $url }
    }
}

function Invoke-Ollama {
    param(
        [Parameter(Mandatory=$true)][string]$Prompt,
        [string]$SystemPrompt,
        [double]$Temperature = 0.7,
        [switch]$JsonMode,
        [string]$ModelOverride
    )

    $config = Get-OllamaConfig
    $model  = if ($ModelOverride) { $ModelOverride } else { $config.Model }
    $apiUrl = "$($config.BaseUrl)/api/generate"

    $body = @{
        model  = $model
        prompt = $Prompt
        stream = $false
        options = @{
            temperature = $Temperature
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($SystemPrompt)) {
        $body.system = $SystemPrompt
    }

    if ($JsonMode) {
        $body.format = "json"
        $body.prompt += "`n`nIMPORTANT: Output ONLY valid JSON."
    }

    $jsonBody = $body | ConvertTo-Json -Depth 5

    Log-Debug "Invoking Ollama ($model) at $apiUrl..."

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $jsonBody -ContentType "application/json" -TimeoutSec $config.Timeout -ErrorAction Stop

        if ($response -and $response.response) {
            $content = $response.response.Trim()

            if ($JsonMode) {
                $content = $content -replace '^```json\s*', '' -replace '\s*```$', ''
            }

            return $content
        } else {
            Log-Error "Ollama returned an empty response."
            return $null
        }
    } catch {
        Log-Error "Ollama API Request Failed: $_"
        return $null
    }
}
