<#
 ================================================================================

 @project:    nuxt4-monorepo-base-app
 @file:       ~/scripts/powershell/utilities/logger2.ps1
 @version:    1.1.0
 @createDate: 2025 Dec 03
 @createTime: 23:26
 @author:     Steve R Lewis

 ================================================================================

 @description:
# Reusable Logging Utility
 Supports file transcription, debug mode, custom colors, and formatting helpers.

 ================================================================================

 @notes: Revision History

 V1.2.0, 20251204-23:07
 Updated the output formatting options.

 v1.1.0, 20251204-22:15

 V1.0.0, 20251203-23:26
 Initial creation and release of logger2.ps1

 ================================================================================
#>

function Initialize-Logger {
    param(
        [bool]$LogToFile = $false,
        [bool]$DebugMode = $false,
        [string]$LogNamePrefix = "script"
    )

    # Set Global Debug Mode
    $global:DebugMode = $DebugMode
    $script:LoggingActive = $false

    if ($LogToFile) {
        # Resolve logs directory relative to this script
        $logDir = Join-Path $PSScriptRoot "../../logs"
        $logDir = $logDir -replace '\\', '/'

        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir | Out-Null
        }

        $logDir = Resolve-Path $logDir
        $logFile = Join-Path $logDir "${LogNamePrefix}_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

        Start-Transcript -Path $logFile -Append | Out-Null
        Write-Host "Logging enabled: $logFile" -ForegroundColor DarkGray

        $script:LoggingActive = $true
    }
}

function Stop-Logger {
    if ($script:LoggingActive) {
        Stop-Transcript | Out-Null
        $script:LoggingActive = $false
    }
}

# ---------------------------
# Internal Helper (Private)
# ---------------------------
function Write-LogEntry {
    param(
        [string]$Message,
        [string]$Level,
        [ConsoleColor]$Color
    )
    $time = Get-Date -Format "HH:mm:ss"
    # Ensure message handles newlines correctly by respecting the console width if needed,
    # but Write-Host usually handles `n fine.
    Write-Host "[$time] [$Level] $Message" -ForegroundColor $Color
}

# ---------------------------
# Formatting Functions
# ---------------------------

function Log-Empty {
    <#
    .SYNOPSIS
        Prints a blank line to the console/log without timestamp prefixes.
    #>
    Write-Host ""
}

function Log-Divider {
    <#
    .SYNOPSIS
        Prints a divider line.
    #>
    param([string]$Char = "-", [int]$Length = 50)
    $line = [string]::new($Char[0], $Length)
    Write-Host $line -ForegroundColor DarkGray
}

function Log-Raw {
    <#
    .SYNOPSIS
        Prints raw text (no timestamp/level) with specific color.
    #>
    param(
        [string]$Message,
        [ConsoleColor]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# ---------------------------
# Standard Log Functions
# ---------------------------

function Log-Info {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ConsoleColor]$Color = "Cyan"
    )
    Write-LogEntry -Message $Message -Level "INFO" -Color $Color
}

function Log-Success {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ConsoleColor]$Color = "Green"
    )
    Write-LogEntry -Message $Message -Level "SUCCESS" -Color $Color
}

function Log-Warning {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ConsoleColor]$Color = "Yellow"
    )
    Write-LogEntry -Message $Message -Level "WARN" -Color $Color
}

function Log-Error {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ConsoleColor]$Color = "Red"
    )
    Write-LogEntry -Message $Message -Level "ERROR" -Color $Color
}

function Log-Debug {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ConsoleColor]$Color = "Magenta"
    )
    if ($global:DebugMode) {
        Write-LogEntry -Message $Message -Level "DEBUG" -Color $Color
    }
}
