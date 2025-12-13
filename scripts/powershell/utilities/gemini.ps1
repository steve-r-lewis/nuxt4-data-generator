<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/utilities/gemini.ps1
 @version:    1.1.0
 @createDate: 2025 Dec 04
 @createTime: 00:43
 @author:     Steve R Lewis

 ================================================================================

 @description:
 Centralized utility for Gemini 2.0 API interactions.
 Handles authentication via JSON Environment Variable and standardizes
 request/response processing.

 ================================================================================

 @notes: Revision History

 V1.2.0, 20251206-21:35
 - Added exponential backoff retry logic for 429 Rate Limit errors.
 - Fixed error stream reading for PowerShell Core compatibility to prevent "Method invocation failed" errors.

 V1.1.0, 20251205-00:26
 Updated the error handling block to be compatible with PowerShell 7+. This
 allows the actual error message from Google (e.g., "429 Too Many Requests")
 instead of a script crash.

 V1.0.0, 20251204-00:43
 Initial creation and release of gemini.ps1

 ================================================================================
#>

function Get-GeminiConfig {
    if (-not $env:GEMINI_API_CREDENTIALS) {
        Log-Error "Environment variable 'GEMINI_API_CREDENTIALS' is missing."
        Log-Error "Please set it with: `$env:GEMINI_API_CREDENTIALS = '{ `"APIKey`": `"YOUR_KEY`", `"Model`": `"gemini-2.0-flash`" }'"
        throw "Missing Configuration"
    }

    try {
        $config = $env:GEMINI_API_CREDENTIALS | ConvertFrom-Json
        if (-not $config.APIKey) { throw "JSON is valid but 'APIKey' field is missing." }
        return $config
    } catch {
        Log-Error "Failed to parse 'GEMINI_API_CREDENTIALS'. Ensure it is valid JSON."
        Log-Debug "Error Details: $_"
        throw "Configuration Error"
    }
}

function Invoke-Gemini {
    param(
        [Parameter(Mandatory=$true)][string]$Prompt,
        [string]$SystemPrompt,
        [double]$Temperature = 0.7,
        [switch]$JsonMode,
        [string]$ModelOverride
    )

    $config = Get-GeminiConfig
    $apiKey = $config.APIKey
    $model  = if ($ModelOverride) { $ModelOverride } elseif ($config.Model) { $config.Model } else { "gemini-2.0-flash" }
    $apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/$($model):generateContent?key=$apiKey"

    if (-not [string]::IsNullOrWhiteSpace($SystemPrompt)) {
        $finalText = "$SystemPrompt`n`n$Prompt"
    } else {
        $finalText = $Prompt
    }

    if ($JsonMode) {
        $finalText += "`n`nIMPORTANT: Output ONLY valid JSON. No markdown formatting."
    }

    $body = @{
        contents = @( @{ parts = @( @{ text = $finalText } ) } )
        generationConfig = @{ temperature = $Temperature }
    }

    if ($JsonMode) {
        $body.generationConfig["responseMimeType"] = "application/json"
    }

    $jsonBody = $body | ConvertTo-Json -Depth 5

    Log-Debug "Invoking Gemini ($model)..."

    # --- RETRY LOGIC (Exponential Backoff) ---
    $maxRetries = 3
    $retryCount = 0
    $requestSuccess = $false
    $response = $null

    while (-not $requestSuccess -and $retryCount -lt $maxRetries) {
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $jsonBody -ContentType "application/json" -ErrorAction Stop
            $requestSuccess = $true
        } catch {
            $err = $_
            $statusCode = 0

            # Extract status code if possible
            if ($err.Exception -and $err.Exception.Response) {
                $statusCode = [int]$err.Exception.Response.StatusCode
            }

            # Handle Rate Limiting (429)
            if ($statusCode -eq 429) {
                $retryCount++
                $waitSecs = [math]::Pow(2, $retryCount) # 2s, 4s, 8s...
                Log-Warning "Gemini Rate Limit (429) hit. Retrying in $waitSecs seconds..."
                Start-Sleep -Seconds $waitSecs
            } else {
                # Non-recoverable error, break loop and handle below
                break
            }
        }
    }

    # If still failed after retries
    if (-not $requestSuccess) {
        Log-Error "Gemini API Request Failed."

        # Modern PowerShell Core Error Handling
        if ($_) {
             if ($_.Exception -and $_.Exception.Response) {
                # Attempt to read the error stream safely
                try {
                    $stream = $_.Exception.Response.GetResponseStream()
                    if ($stream) {
                        $reader = [System.IO.StreamReader]::new($stream)
                        $errDetails = $reader.ReadToEnd()
                        Log-Debug "API Error Response: $errDetails"
                    }
                } catch {
                    Log-Debug "Could not read error stream: $($_.Exception.Message)"
                }
            } else {
                Log-Debug "Exception: $_"
            }
        }
        return $null
    }

    # Success processing
    if ($response.candidates -and $response.candidates.Count -gt 0) {
        $content = $response.candidates[0].content.parts[0].text
        if ($JsonMode) {
            $content = $content -replace '^```json\s*', '' -replace '\s*```$', ''
        }
        return $content
    } else {
        Log-Warning "Gemini returned no candidates (Empty Response)."
        return $null
    }
}
