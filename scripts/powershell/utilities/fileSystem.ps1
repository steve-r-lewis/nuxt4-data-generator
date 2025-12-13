<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/utilities/fileSystem.ps1
 @version:    1.0.0
 @createDate: 2025 Dec 03
 @createTime: 23:20
 @author:     Steve R Lewis

 ================================================================================

 @description:
# File I/O and Search Utilities

 ================================================================================

 @notes: Revision History

 V1.2.0, 20251205-14:32
 Optimized for memory efficiency using Generic Lists instead of Arrays.

 V1.0.0, 20251203-23:20
 Initial creation and release of fileSystem.ps1

 ================================================================================
#>

function Set-ContentAtomic {
    <#
    .SYNOPSIS
        Writes file content safely using a .tmp file swap strategy.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Value,
        [string]$Encoding = "UTF8"
    )

    $tempFile = "$Path.tmp"

    try {
        Set-Content -LiteralPath $tempFile -Value $Value -Encoding $Encoding -Force
        if (Test-Path -LiteralPath $tempFile) {
            Move-Item -LiteralPath $tempFile -Destination $Path -Force
            return $true
        }
        return $false
    } catch {
        Write-Error "Atomic write failed for $Path : $_"
        if (Test-Path -LiteralPath $tempFile) { Remove-Item -LiteralPath $tempFile -Force }
        throw $_
    }
}

function Get-ProjectSourceFiles {
    <#
    .SYNOPSIS
        Scans for SOURCE code (ts, vue, json), excluding artifacts.
        Optimized: Uses Generic List for performance.
    #>
    param(
        [string]$RootPath,
        [string[]]$TargetDirs = @("app", "layers", "server", "scripts"),
        [string[]]$Extensions = @(".ts", ".vue", ".json"),
        [string[]]$ExcludedDirs = @("node_modules", ".nuxt", ".output", "dist", "coverage", ".git"),
        [string[]]$ExcludedFiles = @("package-lock.json", "yarn.lock", "pnpm-lock.yaml")
    )

    # Use Generic List for O(1) additions (High Performance)
    $foundFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

    # 1. Root Level Scan
    Get-ChildItem -Path $RootPath -File | ForEach-Object {
        if ($ExcludedFiles -contains $_.Name) { return }
        if ($Extensions -contains $_.Extension -or $_.Name -eq "package.json") {
            $foundFiles.Add($_)
        }
    }

    # 2. Sub-directory Scan
    foreach ($dirName in $TargetDirs) {
        $dirPath = Join-Path $RootPath $dirName
        if (Test-Path $dirPath) {
            Get-ChildItem -Path $dirPath -Recurse -File | ForEach-Object {
                $f = $_.FullName
                # Fast path exclusion check
                foreach ($ex in $ExcludedDirs) {
                    if ($f.Contains([System.IO.Path]::DirectorySeparatorChar + $ex + [System.IO.Path]::DirectorySeparatorChar)) { return }
                }

                if ($ExcludedFiles -contains $_.Name) { return }

                if ($Extensions -contains $_.Extension -or $_.Name -eq "package.json") {
                    $foundFiles.Add($_)
                }
            }
        }
    }

    return $foundFiles
}

function Get-ProjectArtifacts {
    <#
    .SYNOPSIS
        Scans for BUILD ARTIFACTS (node_modules, .nuxt, lockfiles).
        Optimized: Stops recursion on match; Uses Generic List.
    #>
    param(
        [string]$RootPath,
        [string[]]$ArtifactDirs = @(".nuxt", "node_modules", ".output", "dist", "coverage"),
        [string[]]$ArtifactFiles = @("package-lock.json", "yarn.lock", "pnpm-lock.yaml")
    )

    $results = [System.Collections.Generic.List[System.IO.FileSystemInfo]]::new()

    # Helper function defined inside to capture $results by closure reference
    function Recurse-Scan {
        param($CurrentPath)

        $items = Get-ChildItem -Path $CurrentPath -Force -ErrorAction SilentlyContinue

        foreach ($item in $items) {
            # 1. Check Directories
            if ($item.PSIsContainer) {
                if ($ArtifactDirs -contains $item.Name) {
                    # FOUND ARTIFACT: Add it, and DO NOT recurse inside it
                    $results.Add($item)
                }
                elseif ($item.Name -eq ".cache" -and $item.FullName.Contains("node_modules")) {
                    # Special case for node_modules/.cache
                    $results.Add($item)
                }
                else {
                    # NOT AN ARTIFACT: Recurse deeper (Skip .git for speed)
                    if ($item.Name -ne ".git") {
                        Recurse-Scan -CurrentPath $item.FullName
                    }
                }
            }
            # 2. Check Files
            else {
                if ($ArtifactFiles -contains $item.Name) {
                    $results.Add($item)
                }
            }
        }
    }

    Recurse-Scan -CurrentPath $RootPath
    return $results
}

function Remove-FileOrFolder {
    <#
    .SYNOPSIS
        Robustly deletes a file or folder.
    #>
    param ([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -LiteralPath $Path

        if ($item.PSIsContainer -and $IsWindows) {
            # Robust Windows Delete for deep folders
            cmd /c "rmdir /s /q `"$Path`"" 2>$null
        } else {
            # Standard Delete
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
        }
        return $true
    }
    return $false
}
