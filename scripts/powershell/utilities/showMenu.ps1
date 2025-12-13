<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/utilities/showMenu.ps1
 @version:    1.1.0
 @createDate: 2025 Dec 03
 @createTime: 23:23
 @author:     Steve R Lewis

 ================================================================================
 .SYNOPSIS
   Displays an interactive CLI menu navigable with arrow keys.

 .DESCRIPTION
   Renders a list of options to the console. The user can navigate using Up/Down arrows.
   Supports single-selection (Enter/Space to select) and multi-selection (Space to toggle, Enter to confirm).

 .PARAMETER Title
   The title displayed at the top of the menu.

 .PARAMETER Options
   An array of strings representing the menu items.

 .PARAMETER MultiSelect
   If true, allows selecting multiple items using checkboxes. Returns an array.
   If false, returns a single string.

 .PARAMETER ClearScreen
   If true, clears the host before rendering.

 .EXAMPLE
   $choice = Show-Menu -Title "Choose a Fruit" -Options @("Apple", "Banana", "Orange")

 ================================================================================

 @notes: Revision History

 V1.2.0, 20251208-01:11
 Switched to 'Clear-Host' strategy to eliminate ghosting artifacts.

 V1.1.0, 20251208-01:06
 Fixed redraw offset calculation to prevent ghosting artifacts.

 V1.0.0, 20251203-23:23
 Initial creation and release of showMenu2.ps1

 ================================================================================
#>

function Show-Menu {

    param(
        [string]$Title,
        [array]$Options,
        [bool]$MultiSelect = $false,
        [bool]$ClearScreen = $true
    )

    $selectedIndex = 0
    $checkedState = New-Object bool[] $Options.Count

    try { [Console]::CursorVisible = $false } catch {}

    while ($true) {
        # ARTIFACT FIX: Always clear the host.
        # Attempting to overwrite lines manually caused the glitching seen in your logs.
        Clear-Host

        # Header
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host "   $Title" -ForegroundColor White
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host " Use UP/DOWN to navigate, SPACE to select, ENTER to confirm" -ForegroundColor DarkGray
        Write-Host ""

        # Options
        for ($i = 0; $i -lt $Options.Count; $i++) {
            $prefix = "  "
            $item = $Options[$i]

            if ($i -eq $selectedIndex) {
                $prefix = "> "
            }

            $checkbox = ""
            if ($MultiSelect) {
                if ($checkedState[$i]) { $checkbox = "[x] " } else { $checkbox = "[ ] " }
            }

            if ($i -eq $selectedIndex) {
                Write-Host "$prefix$checkbox$item" -ForegroundColor Black -BackgroundColor Cyan
            } else {
                if ($MultiSelect -and $checkedState[$i]) {
                    Write-Host "$prefix$checkbox$item" -ForegroundColor Green
                } else {
                    Write-Host "$prefix$checkbox$item" -ForegroundColor White
                }
            }
        }

        # Footer
        Write-Host ""

        # Capture Input
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            38 { # Up
                if ($selectedIndex -gt 0) { $selectedIndex-- } else { $selectedIndex = $Options.Count - 1 }
            }
            40 { # Down
                if ($selectedIndex -lt ($Options.Count - 1)) { $selectedIndex++ } else { $selectedIndex = 0 }
            }
            32 { # Space
                if ($MultiSelect) { $checkedState[$selectedIndex] = -not $checkedState[$selectedIndex] }
                else { try { [Console]::CursorVisible = $true } catch {}; return $Options[$selectedIndex] }
            }
            13 { # Enter
                try { [Console]::CursorVisible = $true } catch {}
                if ($MultiSelect) {
                    $selectedItems = @()
                    for ($i = 0; $i -lt $Options.Count; $i++) { if ($checkedState[$i]) { $selectedItems += $Options[$i] } }
                    return $selectedItems
                } else { return $Options[$selectedIndex] }
            }
            81 { # Q
                if (-not $MultiSelect) { try { [Console]::CursorVisible = $true } catch {}; return "Quit" }
            }
        }
    }
}
