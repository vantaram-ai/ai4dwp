param(
    [string]$SubscriptionId = "265adc95-4fa6-4207-a717-b2cdcd750171",
    [string]$ResourceGroup = "dwp-lab-rg",
    [string]$HostPoolName = "POOL-FIN-01",
    [int]$TimeoutMinutes = 20
)

$ErrorActionPreference = "Stop"
az account set --subscription $SubscriptionId | Out-Null

$hostUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/hostPools/$HostPoolName/sessionHosts?api-version=2024-04-03"
$userUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/hostPools/$HostPoolName/userSessions?api-version=2024-04-03"

$start = [DateTime]::UtcNow
Write-Output ("MONITOR_START_UTC=" + $start.ToString("o"))
Write-Output "WAITING_FOR_SESSION..."

$detected = $false
while ((-not $detected) -and ([DateTime]::UtcNow -lt $start.AddMinutes($TimeoutMinutes))) {
    $h = az rest --method get --url $hostUrl --output json | ConvertFrom-Json
    $total = 0
    foreach ($row in $h.value) {
        $total += [int]$row.properties.sessions
    }

    if ($total -gt 0) {
        $u = az rest --method get --url $userUrl --output json | ConvertFrom-Json
        $cand = @($u.value | Where-Object { $_.properties.sessionState -eq "Active" -or $_.properties.sessionState -eq "Connected" })
        $first = $cand | Sort-Object { $_.properties.createTime } | Select-Object -First 1

        $detectedAt = [DateTime]::UtcNow.ToString("o")
        Write-Output ("SESSION_COUNT=" + $total)
        Write-Output ("SESSION_LANDED_UTC_DETECTED=" + $detectedAt)

        if ($first) {
            Write-Output ("SESSION_NAME=" + $first.name)
            Write-Output ("SESSION_USER=" + $first.properties.userPrincipalName)
            Write-Output ("SESSION_STATE=" + $first.properties.sessionState)
            Write-Output ("SESSION_CREATE_TIME_UTC=" + $first.properties.createTime)
        }
        else {
            Write-Output "SESSION_FOUND_BUT_USER_SESSION_DETAILS_NOT_RETURNED"
        }

        $detected = $true
    }
}

if (-not $detected) {
    Write-Output "NO_SESSION_DETECTED_WITHIN_TIMEOUT"
    exit 2
}
