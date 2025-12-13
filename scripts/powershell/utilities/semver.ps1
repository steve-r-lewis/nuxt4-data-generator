<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/utilities/semver.ps1
 @version:    1.0.0
 @createDate: 2025 Dec 05
 @createTime: 19:49
 @author:     Steve R Lewis

 ================================================================================

 @description:
 Logic for parsing and incrementing V-formatted Semantic Versions (e.g. V1.0.2).

 ================================================================================

 @notes: Revision History

 V1.0.0, 20251205-19:49
 Initial creation and release of semver.ps1

 ================================================================================
#>

function Get-NextVersion {
    param(
        [string]$CurrentVersion, # e.g. "1.0.0" or "V1.0.0"
        [string]$IncrementType   # "Major", "Minor", "Patch"
    )

    # Strip "V" prefix if present
    $cleanVer = $CurrentVersion -replace "^[vV]", ""
    $parts = $cleanVer.Split(".")

    if ($parts.Count -lt 3) {
        Log-Warning "Invalid version format '$CurrentVersion'. Resetting to 1.0.0"
        return "V1.0.0"
    }

    [int]$major = $parts[0]
    [int]$minor = $parts[1]
    [int]$patch = $parts[2]

    switch ($IncrementType.ToLower()) {
        "major" { $major++; $minor = 0; $patch = 0 }
        "minor" { $minor++; $patch = 0 }
        "patch" { $patch++ }
        default { $patch++ } # Default to patch
    }

    return "V$major.$minor.$patch"
}
