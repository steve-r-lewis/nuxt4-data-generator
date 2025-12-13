<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/utilities/paths.ps1
 @version:    1.0.0
 @createDate: 2025 Dec 03
 @createTime: 23:18
 @author:     Steve R Lewis

 ================================================================================

 @description:
 Path Manipulation Utilities

 ================================================================================

 @notes: Revision History

 V1.0.0, 20251203-23:18
 Initial creation and release of paths.ps1

 ================================================================================
#>

function Get-RelativePath {
    <#
    .SYNOPSIS
        Converts a full path to a project-relative path (e.g., ~/app/test.ts).
    #>
    param(
        [string]$FullPath,
        [string]$RootPath = (Get-Location).Path
    )

    $stdFull = $FullPath -replace '\\', '/'
    $stdRoot = $RootPath -replace '\\', '/'

    # Simple string replacement
    $relPath = $stdFull.Replace($stdRoot, "")

    # Ensure it starts with / if not empty, then prepend ~
    if ($relPath -and $relPath -notmatch "^/") { $relPath = "/" + $relPath }

    return "~$relPath"
}
