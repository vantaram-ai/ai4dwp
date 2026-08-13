param(
    [string]$SubscriptionId = "265adc95-4fa6-4207-a717-b2cdcd750171",
    [string]$ResourceGroup = "dwp-lab-rg",
    [string]$Location = "centralus",
    [string]$HostPoolName = "POOL-FIN-01",
    [string]$WorkspaceName = "FinBridge-Workspace",
    [string]$AppGroupName = "POOL-FIN-01-DAG",
    [string]$VmName = "vm-fin-01",
    [string]$VmSize = "Standard_B2ms",
    [string]$VmImage = "MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest",
    [string]$AdminUsername = "localadminzippy",
    [string]$AdminPassword,
    [string]$EndUserUpn = "p07@zippyops.in"
)

$ErrorActionPreference = "Stop"

if (-not $AdminPassword) {
    throw "AdminPassword is required. Pass -AdminPassword <value>."
}

Write-Host "[1/9] Set subscription and validate CLI extension/providers..."
az account set --subscription $SubscriptionId | Out-Null
az extension add --name desktopvirtualization --upgrade --only-show-errors | Out-Null
az provider register --namespace Microsoft.DesktopVirtualization --only-show-errors | Out-Null
az provider register --namespace Microsoft.Compute --only-show-errors | Out-Null
az provider register --namespace Microsoft.Network --only-show-errors | Out-Null

Write-Host "[2/9] Ensure resource group exists..."
$rgExists = az group exists -n $ResourceGroup
if ($rgExists -eq "false") {
    az group create -n $ResourceGroup -l $Location --output none
}

Write-Host "[3/9] Create host pool, desktop app group, and workspace..."
$hpId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/hostPools/$HostPoolName"
$agId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/applicationGroups/$AppGroupName"

az desktopvirtualization hostpool create `
    -g $ResourceGroup -n $HostPoolName -l $Location `
    --host-pool-type Pooled `
    --load-balancer-type BreadthFirst `
    --max-session-limit 5 `
    --preferred-app-group-type Desktop `
    --custom-rdp-property "targetisaadjoined:i:1;aadcredsspsupport:i:1;enablerdsaadauth:i:1;" `
    --output none

az desktopvirtualization applicationgroup create `
    -g $ResourceGroup -n $AppGroupName -l $Location `
    --application-group-type Desktop `
    --host-pool-arm-path $hpId `
    --output none

az desktopvirtualization workspace create `
    -g $ResourceGroup -n $WorkspaceName -l $Location `
    --application-group-references $agId `
    --output none

Write-Host "[4/9] Generate host pool registration token..."
$expiry = (Get-Date).ToUniversalTime().AddHours(8).ToString("yyyy-MM-ddTHH:mm:ss.fffffffZ")
az desktopvirtualization hostpool update -g $ResourceGroup -n $HostPoolName --registration-info expiration-time=$expiry registration-token-operation=Update --output none
$token = az desktopvirtualization hostpool retrieve-registration-token -g $ResourceGroup -n $HostPoolName --query token -o tsv
if (-not $token) {
    throw "Could not retrieve host pool registration token."
}

Write-Host "[5/9] Create Trusted Launch Windows 11 AVD VM..."
az vm create `
    -g $ResourceGroup -n $VmName -l $Location `
    --image $VmImage `
    --size $VmSize `
    --admin-username $AdminUsername `
    --admin-password $AdminPassword `
    --authentication-type password `
    --security-type TrustedLaunch `
    --enable-secure-boot true `
    --enable-vtpm true `
    --assign-identity `
    --public-ip-sku Standard `
    --nsg-rule RDP `
    --vnet-name "vnet-fin-01" `
    --subnet "snet-avd" `
    --nsg "nsg-fin-01" `
    --public-ip-address "pip-vm-fin-01" `
    --license-type Windows_Client `
    --output none

az vm wait -g $ResourceGroup -n $VmName --created

Write-Host "[6/9] Enable Entra sign-in extension..."
az vm extension set --resource-group $ResourceGroup --vm-name $VmName --name AADLoginForWindows --publisher Microsoft.Azure.ActiveDirectory --output none

Write-Host "[7/9] Install AVD agent + bootloader and register host..."
$remoteScript = @"
`$ErrorActionPreference = 'Stop'
Set-Location 'C:\\Windows\\Temp'
`$u1 = 'https://go.microsoft.com/fwlink/?linkid=2310011'
`$u2 = 'https://go.microsoft.com/fwlink/?linkid=2311028'
`$r1 = (Invoke-WebRequest -UseBasicParsing -MaximumRedirection 0 -Uri `$u1 -ErrorAction SilentlyContinue).Headers.Location
if(-not `$r1){ `$r1 = `$u1 }
`$r2 = (Invoke-WebRequest -UseBasicParsing -MaximumRedirection 0 -Uri `$u2 -ErrorAction SilentlyContinue).Headers.Location
if(-not `$r2){ `$r2 = `$u2 }
Invoke-WebRequest -UseBasicParsing -Uri `$r1 -OutFile 'C:\\Windows\\Temp\\RDAgent.msi'
Invoke-WebRequest -UseBasicParsing -Uri `$r2 -OutFile 'C:\\Windows\\Temp\\RDBoot.msi'
`$p1 = Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i C:\\Windows\\Temp\\RDAgent.msi /qn /norestart REGISTRATIONTOKEN=$token /l*v C:\\Windows\\Temp\\RDAgent-install.log' -Wait -PassThru
`$p2 = Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i C:\\Windows\\Temp\\RDBoot.msi /qn /norestart /l*v C:\\Windows\\Temp\\RDBoot-install.log' -Wait -PassThru
if (`$p1.ExitCode -ne 0 -or `$p2.ExitCode -ne 0) { throw "Agent install failed. Agent exit=`$(`$p1.ExitCode), Boot exit=`$(`$p2.ExitCode)" }
Get-Service -Name 'RdAgent','RDAgentBootLoader' | Select-Object Name,Status,StartType
"@

$bytes = [System.Text.Encoding]::Unicode.GetBytes($remoteScript)
$enc = [Convert]::ToBase64String($bytes)
az vm run-command invoke -g $ResourceGroup -n $VmName --command-id RunPowerShellScript --scripts "powershell -ExecutionPolicy Bypass -EncodedCommand $enc" --output none

Write-Host "[8/9] Validate session host availability..."
$hostUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/hostPools/$HostPoolName/sessionHosts?api-version=2024-04-03"
$sessionHosts = az rest --method get --url $hostUrl --output json | ConvertFrom-Json
$target = $sessionHosts.value | Where-Object { $_.name -like "*$VmName" }
if (-not $target) {
    throw "Session host object not found in host pool."
}
if ($target.properties.status -ne "Available") {
    throw "Session host is not Available. Current status: $($target.properties.status)"
}

Write-Host "[9/9] Assign user roles for VM login and AVD desktop access..."
$vmScope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachines/$VmName"
$agScope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/applicationGroups/$AppGroupName"
az role assignment create --assignee $EndUserUpn --role "Virtual Machine User Login" --scope $vmScope --output none 2>$null
az role assignment create --assignee $EndUserUpn --role "Desktop Virtualization User" --scope $agScope --output none 2>$null

Write-Host "Done. AVD deployment complete."
Write-Host "Workspace: $WorkspaceName"
Write-Host "Published desktop name: SessionDesktop"
Write-Host "User assigned: $EndUserUpn"
