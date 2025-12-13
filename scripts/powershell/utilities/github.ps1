<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/utilities/github.ps1
 @version:    1.2.0
 @createDate: 2025 Dec 03
 @createTime: 20:04
 @author:     Steve R Lewis

 ================================================================================

 @description:
 Reusable GitHub API Utilities
 Provides helper functions for interacting with the GitHub REST API.

 ================================================================================

 @notes: Revision History

 V1.2.0, 20251205-19:25
 Optimized error handling: 404s (Not Found) now exit the retry loop immediately
 to speed up 'Ensure-GitHubRepo' checks and reduce log noise.

 V1.1.0, 20251204-00:22
 Refactored the Invoke-GitHubApi to not dump the full raw json output.

 V1.0.0, 20251203-20:04
 Initial creation and release of github.ps1

 ================================================================================
#>

function Invoke-GitHubApi {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Method,

        [Parameter(Mandatory=$true)]
        [string]$Url,

        [hashtable]$Body = $null
    )

    if (-not $env:GITHUB_TOKEN) {
        Log-Error "GITHUB_TOKEN environment variable is missing!"
        throw "Missing GITHUB_TOKEN"
    }

    $headers = @{
        Authorization = "Bearer $env:GITHUB_TOKEN"
        "User-Agent"  = "PowerShell"
        Accept        = "application/vnd.github+json"
    }

    for ($attempt=1; $attempt -le 3; $attempt++) {
        try {
            if ($Body) {
                $jsonBody = $Body | ConvertTo-Json -Compress
                $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers -Body $jsonBody -ContentType "application/json" -ErrorAction Stop
            } else {
                $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers -ErrorAction Stop
            }

            # OPTIMIZATION: Only log summary, not full JSON
            if ($global:DebugMode) {
                $summary = "API $Method Success: "
                if ($response.id) { $summary += "ID=$($response.id) " }
                if ($response.html_url) { $summary += "URL=$($response.html_url)" }
                Log-Debug $summary
            }
            return $response
        } catch {
            $errMsg = $_.ToString()

            # IMPROVEMENT: If it is a 404 (Not Found), do NOT retry and do NOT log a warning.
            # This is common when checking if a repo exists before creating it.
            if ($errMsg -match "404" -or "$_" -match "Not Found") {
                if ($global:DebugMode) { Log-Debug "API 404 Not Found: $Url" }
                throw $_
            }

            $errParams = @{
                Message = "Attempt $attempt failed for API call: $Url. Error: $_"
            }
            if ($attempt -lt 3) {
                Log-Warning $errParams.Message
                Start-Sleep -Seconds (2 * $attempt)
            } else {
                throw $_
            }
        }
    }
}

function Ensure-GitHubRepo {
    <#
    .SYNOPSIS
        Ensures a GitHub repository exists, creating it if necessary.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepoName,

        [Parameter(Mandatory=$true)]
        [string]$GitHubOrgParam
    )

    $GitHubOrgLocal = $GitHubOrgParam
    $repoApiUrl = "https://api.github.com/repos/$GitHubOrgLocal/$RepoName"

    try {
        Invoke-GitHubApi -Url $repoApiUrl -Method GET | Out-Null
        Log-Warning "GitHub repo '$RepoName' already exists under '$GitHubOrgLocal'."
        return "https://github.com/$GitHubOrgLocal/$RepoName.git"
    } catch {
        Log-Info "GitHub repo '$RepoName' does not exist (or is inaccessible) — creating..."

        $body = @{
            name = $RepoName
            private = $true
            visibility = "private"
        }

        if ($global:AccountType -eq "Organization") {
            try {
                Invoke-GitHubApi -Url "https://api.github.com/orgs/$GitHubOrgLocal/repos" -Method POST -Body $body
                Log-Success "GitHub repo '$RepoName' created under Organization '$GitHubOrgLocal'."
            } catch {
                 Log-Error "Failed to create Organization repository '$RepoName'."
                 throw $_
            }
        } else {
            try {
                Invoke-GitHubApi -Url "https://api.github.com/user/repos" -Method POST -Body $body
                Log-Success "GitHub repo '$RepoName' created under User account."
            } catch {
                Log-Error "Failed to create User repository '$RepoName'."
                throw $_
            }
        }
        return "https://github.com/$GitHubOrgLocal/$RepoName.git"
    }
}
