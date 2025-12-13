<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/utilities/llm-messages.ps1
 @version:    1.1.0
 @createDate: 2025 Dec 05
 @createTime: 19:40
 @author:     Steve R Lewis

 ================================================================================

 @description:
 Provider-Agnostic Prompt Engineering Library.
 Transforms raw data (Diffs) into structured AI prompts for specific tasks.
 Delegates execution to the central 'Invoke-LLM' gateway.

 ================================================================================

 @notes: Revision History

 V1.1.0, 20251208-00:30
 Refactored to use Invoke-LLM gateway instead of direct Gemini calls.
 Renamed functions from Get-Gemini-* to Get-LLM-*.

 V1.0.0, 20251205-19:40
 Initial creation and release of llm-messages.ps1

 ================================================================================
#>

function Get-LLM-CommitMessage {
    param([string]$Diff)

    $sys = "You are a git commit message generator. Output ONLY the commit message. No quotes, no explanations. Format: 'type: description'. Keep it under 50 chars."
    $user = "Generate a commit message for this diff:`n`n$Diff"

    # Uses the gateway (Gemini or Ollama)
    $msg = Invoke-LLM -SystemPrompt $sys -Prompt $user
    if ($msg) { return $msg.Trim() }
    return $null
}

function Get-LLM-VersionAnalysis {
    param([string]$Diff)

    $sys = "You are a Semantic Versioning expert. You analyze code changes to determine impact and write concise changelog notes."

    $user = @"
Analyze the following git diff.
Task 1: Determine the Semantic Versioning increment required (Patch, Minor, or Major).
   - Patch: Bug fixes, small tweaks, refactors.
   - Minor: New features, non-breaking changes.
   - Major: Breaking changes.
Task 2: Write a single-line technical revision note (max 15 words).

Return ONLY valid JSON in this format:
{
    "increment": "Patch",
    "note": "Fixed null reference in user loop."
}

DIFF:
$Diff
"@

    # Request JSON Mode via Gateway
    $jsonStr = Invoke-LLM -SystemPrompt $sys -Prompt $user -JsonMode

    if ($jsonStr) {
        try {
            return ($jsonStr | ConvertFrom-Json)
        } catch {
            Log-Error "Failed to parse AI Version Analysis."
            Log-Debug $jsonStr
        }
    }
    return $null
}
