<#
.SYNOPSIS
Gather on-device evidence for the top-ranked cause: faulty or mis-scoped Friday app deployment.

.DESCRIPTION
Targets one endpoint and collects structured evidence for:
- App deployment footprint (install/version/timing)
- App-related installer/events around the change window
- Login-delay signals that may correlate with deployment
- Shortcut/profile symptoms that were reported

Includes:
- AI-first version notes
- Hand-corrected version notes
- Dry run output mode for immediate triage use

.EXAMPLE
.\Floor6-DeploymentEvidence.ps1 -AppNameHint "document management" -DryRun

.EXAMPLE
.\Floor6-DeploymentEvidence.ps1 -AppNameHint "document management" -OutputPath "C:\Temp\Floor6Evidence.json"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$AppNameHint = "document management",

    [Parameter(Mandatory = $false)]
    [datetime]$ChangeWindowStart,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PWD -ChildPath ("Floor6-Evidence-{0}-{1}.json" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd-HHmmss")))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-DefaultFridayWindowStart {
    $today = Get-Date
    $daysSinceFriday = (([int]$today.DayOfWeek - [int][System.DayOfWeek]::Friday + 7) % 7)
    if ($daysSinceFriday -eq 0) {
        $daysSinceFriday = 7
    }

    return ($today.Date.AddDays(-$daysSinceFriday).AddHours(12))
}

function Convert-InstallDate {
    param([string]$InstallDate)

    if ([string]::IsNullOrWhiteSpace($InstallDate)) {
        return $null
    }

    if ($InstallDate -match "^\d{8}$") {
        try {
            return [datetime]::ParseExact($InstallDate, "yyyyMMdd", $null)
        }
        catch {
            return $null
        }
    }

    return $null
}

function Get-RegistryInstalledApps {
    param([string]$NameHint)

    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $apps = @()
    foreach ($path in $paths) {
        try {
            $apps += Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -and $_.DisplayName -match [regex]::Escape($NameHint) } |
                Select-Object 
                    @{ Name = "DisplayName"; Expression = { $_.DisplayName } },
                    @{ Name = "DisplayVersion"; Expression = { $_.DisplayVersion } },
                    @{ Name = "Publisher"; Expression = { $_.Publisher } },
                    @{ Name = "InstallDateRaw"; Expression = { $_.InstallDate } },
                    @{ Name = "InstallDateParsed"; Expression = { Convert-InstallDate -InstallDate $_.InstallDate } },
                    @{ Name = "UninstallString"; Expression = { $_.UninstallString } },
                    @{ Name = "RegistryPath"; Expression = { $_.PSPath } }
        }
        catch {
            # Non-fatal: continue to next registry path.
        }
    }

    return $apps | Sort-Object DisplayName, DisplayVersion -Unique
}

function Get-RelatedServices {
    param([string]$NameHint)

    $pattern = [regex]::Escape($NameHint)
    return Get-CimInstance Win32_Service |
        Where-Object { $_.Name -match $pattern -or $_.DisplayName -match $pattern } |
        Select-Object Name, DisplayName, State, StartMode, StartName, ProcessId
}

function Get-RelatedScheduledTasks {
    param([string]$NameHint)

    $pattern = [regex]::Escape($NameHint)

    try {
        return Get-ScheduledTask |
            Where-Object { $_.TaskName -match $pattern -or $_.TaskPath -match $pattern } |
            Select-Object TaskName, TaskPath, State
    }
    catch {
        return @(
            [pscustomobject]@{
                TaskName = "to confirm"
                TaskPath = "to confirm"
                State    = "Get-ScheduledTask unavailable or access denied"
            }
        )
    }
}

function Get-ShortcutEvidence {
    param([string]$NameHint)

    $desktopPaths = @(
        "$env:PUBLIC\Desktop",
        "$env:USERPROFILE\Desktop"
    )

    $found = @()
    foreach ($path in $desktopPaths) {
        if (Test-Path -LiteralPath $path) {
            $links = Get-ChildItem -LiteralPath $path -Filter "*.lnk" -File -ErrorAction SilentlyContinue
            $matched = $links | Where-Object { $_.Name -match [regex]::Escape($NameHint) }
            $found += [pscustomobject]@{
                DesktopPath      = $path
                TotalShortcuts   = $links.Count
                MatchedShortcuts = $matched.Count
                MatchedNames     = @($matched.Name)
            }
        }
        else {
            $found += [pscustomobject]@{
                DesktopPath      = $path
                TotalShortcuts   = "to confirm"
                MatchedShortcuts = "to confirm"
                MatchedNames     = @("Path not present")
            }
        }
    }

    return $found
}

function Get-EventEvidence {
    param(
        [datetime]$StartTime,
        [string]$NameHint
    )

    $escapedHint = [regex]::Escape($NameHint)

    $applicationEvents = Get-WinEvent -FilterHashtable @{ LogName = "Application"; StartTime = $StartTime } -ErrorAction SilentlyContinue |
        Where-Object {
            $_.ProviderName -in @("MsiInstaller", "Application Error", "User Profile Service") -or
            $_.Message -match $escapedHint
        } |
        Select-Object -First 80 TimeCreated, Id, LevelDisplayName, ProviderName, MachineName, Message

    $appxEvents = Get-WinEvent -FilterHashtable @{ LogName = "Microsoft-Windows-AppXDeploymentServer/Operational"; StartTime = $StartTime } -ErrorAction SilentlyContinue |
        Where-Object { $_.Message -match $escapedHint } |
        Select-Object -First 40 TimeCreated, Id, LevelDisplayName, ProviderName, MachineName, Message

    return [pscustomobject]@{
        ApplicationLog = @($applicationEvents)
        AppXLog        = @($appxEvents)
    }
}

function Get-LoginSignal {
    param([datetime]$StartTime)

    $userProfileEvents = Get-WinEvent -FilterHashtable @{ LogName = "Application"; ProviderName = "User Profile Service"; StartTime = $StartTime } -ErrorAction SilentlyContinue |
        Select-Object -First 40 TimeCreated, Id, LevelDisplayName, ProviderName, Message

    return [pscustomobject]@{
        UserProfileServiceEvents = @($userProfileEvents)
    }
}

function Get-DeploymentCausalityAssessment {
    param(
        [array]$InstalledApps,
        [pscustomobject]$EventEvidence,
        [datetime]$ChangeWindowStart,
        [string]$NameHint
    )

    $InstalledApps = @($InstalledApps)

    $score = 0
    $notes = @()

    if ($InstalledApps.Count -gt 0) {
        $score += 2
        $notes += "App footprint present on device."

        $recentInstall = $InstalledApps | Where-Object {
            $_.InstallDateParsed -and $_.InstallDateParsed -ge $ChangeWindowStart.Date.AddDays(-1)
        }

        if ($recentInstall.Count -gt 0) {
            $score += 2
            $notes += "Install date aligns with Friday-to-Monday incident window."
        }
        else {
            $notes += "Install date alignment is to confirm (missing/invalid install date)."
        }
    }
    else {
        $notes += "No matching app footprint found with current name hint (to confirm)."
    }

    $matchingAppEvents = @($EventEvidence.ApplicationLog | Where-Object { $_.Message -match [regex]::Escape($NameHint) })
    if ($matchingAppEvents.Count -gt 0) {
        $score += 2
        $notes += "Application log has app-name-matching events in the change window."
    }
    else {
        $notes += "No direct app-name event match found in Application log (to confirm)."
    }

    $rating = "Low"
    if ($score -ge 5) {
        $rating = "High"
    }
    elseif ($score -ge 3) {
        $rating = "Medium"
    }

    return [pscustomobject]@{
        DeploymentLikelihood = $rating
        EvidenceScore        = $score
        Notes                = $notes
        ConfirmsDeployment   = @(
            "Common install/version footprint on affected devices",
            "Event timeline aligns with post-deployment first logon",
            "Behavior improves after controlled rollback/unassignment"
        )
        RulesOutDeployment   = @(
            "No affected-vs-unaffected deployment footprint difference",
            "No timeline alignment to deployment events",
            "No symptom change after rollback/unassignment"
        )
    }
}

function Get-VersionComparison {
    return @(
        [pscustomobject]@{
            Topic         = "Install date parsing"
            AIFirst       = "Used raw InstallDate string"
            HandCorrected = "Parses YYYYMMDD to DateTime with validation"
            FixNote       = "Fixed to avoid false timeline matches when registry date is malformed."
        },
        [pscustomobject]@{
            Topic         = "Event query scope"
            AIFirst       = "Pulled broad Application events only"
            HandCorrected = "Adds targeted providers and AppX deployment log"
            FixNote       = "Fixed to reduce noise and improve deployment-correlation signal."
        },
        [pscustomobject]@{
            Topic         = "Output shape"
            AIFirst       = "Mostly status text"
            HandCorrected = "Structured object with findings, score, and confirm/rule-out evidence"
            FixNote       = "Fixed so another engineer can act without re-parsing free text."
        }
    )
}

if (-not $PSBoundParameters.ContainsKey("ChangeWindowStart")) {
    $ChangeWindowStart = Get-DefaultFridayWindowStart
}

$installedApps = @(Get-RegistryInstalledApps -NameHint $AppNameHint)
$relatedServices = @(Get-RelatedServices -NameHint $AppNameHint)
$relatedTasks = @(Get-RelatedScheduledTasks -NameHint $AppNameHint)
$shortcutEvidence = @(Get-ShortcutEvidence -NameHint $AppNameHint)
$eventEvidence = Get-EventEvidence -StartTime $ChangeWindowStart -NameHint $AppNameHint
$loginSignal = Get-LoginSignal -StartTime $ChangeWindowStart
$assessment = Get-DeploymentCausalityAssessment -InstalledApps $installedApps -EventEvidence $eventEvidence -ChangeWindowStart $ChangeWindowStart -NameHint $AppNameHint
$versionComparison = Get-VersionComparison

$result = [pscustomobject]@{
    RunContext = [pscustomobject]@{
        ComputerName      = $env:COMPUTERNAME
        RunUtc            = (Get-Date).ToUniversalTime().ToString("o")
        AnalystObjective  = "Validate whether Friday app deployment is the most likely primary cause"
        AppNameHint       = $AppNameHint
        ChangeWindowStart = $ChangeWindowStart.ToString("o")
        DryRun            = [bool]$DryRun
    }
    VersionNotes = [pscustomobject]@{
        GeneratedWithAI = "Initial draft generated with AI first"
        HandCorrected   = "Final script hand-corrected for date parsing, event scope, and structured output"
        SideBySide      = $versionComparison
    }
    Evidence = [pscustomobject]@{
        InstalledApps    = @($installedApps)
        RelatedServices  = @($relatedServices)
        RelatedTasks     = @($relatedTasks)
        ShortcutEvidence = @($shortcutEvidence)
        EventEvidence    = $eventEvidence
        LoginSignal      = $loginSignal
    }
    Findings = @(
        [pscustomobject]@{
            Check      = "App deployment footprint"
            Status     = $(if ($installedApps.Count -gt 0) { "Observed" } else { "to confirm" })
            WhyItMatters = "Confirms whether the target app is actually present and versioned on this device"
            FastAction = "Compare this footprint with unaffected and affected peer devices"
        },
        [pscustomobject]@{
            Check      = "Timeline correlation to change window"
            Status     = "to confirm"
            WhyItMatters = "Establishes whether symptoms and install/events align after Friday rollout"
            FastAction = "Cross-check event times with first user symptom reports"
        },
        [pscustomobject]@{
            Check      = "Rule-in / rule-out deployment"
            Status     = $assessment.DeploymentLikelihood
            WhyItMatters = "Produces a decision-ready confidence indicator"
            FastAction = "If confidence is Medium/High, run controlled rollback/unassignment test"
        }
    )
    CausalityAssessment = $assessment
}

if ($DryRun) {
    Write-Host "Dry run enabled. Printing structured evidence list only; no file write." -ForegroundColor Yellow
    $result.Findings | Format-Table -AutoSize
    $result.VersionNotes.SideBySide | Format-Table -AutoSize
    $result | ConvertTo-Json -Depth 8
    return
}

$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Evidence saved: {0}" -f $OutputPath) -ForegroundColor Green
