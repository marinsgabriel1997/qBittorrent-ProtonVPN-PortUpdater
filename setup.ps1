<#
.SYNOPSIS
    Checks and elevates script execution to administrator privileges.

.DESCRIPTION
    Verifies if the current PowerShell script is running with administrative rights. 
    If not, prompts the user to restart the script with elevated permissions.

.PARAMETER None

.EXAMPLE
    The script will automatically prompt for elevation if run without admin rights.

.NOTES
    - Captures current user SID and username before attempting elevation
    - Allows user to cancel elevation
    - Uses Start-Process with RunAs verb to request admin rights
    - Passes current user details and script paths as arguments when elevating
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  
    Write-Host "This script requires administrator privileges."
    
    $currentUserSID = ([Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
    $currentUser = ([Security.Principal.WindowsIdentity]::GetCurrent()).Name    
    $updatePortVBSPath = Join-Path $PSScriptRoot "update_port.vbs"
    $languagesVBSPath = Join-Path $PSScriptRoot "languages.vbs"
    $xmlPath = Join-Path $PSScriptRoot "languages.vbs"

    $confirmation = Read-Host "Do you want to run as administrator? ([Y]/N - Y Default)"
    
    if ($confirmation -ne '' -and $confirmation -ne 'Y' -and $confirmation -ne 'y') {
        Write-Host "Script execution canceled."
        return
    }
    
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$currentUserSID`" `"$currentUser`" `"$updatePortVBSPath`" `"$languagesVBSPath`" `"$xmlPath`"" -Verb RunAs
    exit
}

$sid = if ($args.Count -gt 0) { $args[0] } else { ([Security.Principal.WindowsIdentity]::GetCurrent()).User.Value }
$currentUser = if ($args.Count -gt 1) { $args[1] } else { ([Security.Principal.WindowsIdentity]::GetCurrent()).Name }
$updatePortVBSPath = if ($args.Count -gt 2) { $args[2] } else { Join-Path $PSScriptRoot "update_port.vbs" }
$languagesVBSPath = if ($args.Count -gt 3) { $args[3] } else { Join-Path $PSScriptRoot "languages.vbs" }
$xmlPath = if ($args.Count -gt 4) { $args[4] } else { Join-Path $PSScriptRoot "task_config.xml" }

$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles"
$protonVPNGuid = $null

foreach ($profile in $profiles) {
    $profileName = (Get-ItemProperty -Path $profile.PSPath -Name ProfileName -ErrorAction SilentlyContinue).ProfileName
    if ($profileName -eq "ProtonVPN") {
        $protonVPNGuid = $profile.PSChildName
        break
    }
}

if (-not $protonVPNGuid) {
    Write-Host "ProtonVPN profile not found in the registry."
    Pause
}

$destinationPath = "C:\Program Files\QbittorrentProtonVPNUpdater"

if (-not (Test-Path $destinationPath)) {
    New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
}

Copy-Item -Path $updatePortVBSPath -Destination $destinationPath -Force
Copy-Item -Path $languagesVBSPath -Destination $destinationPath -Force

try {
    if ($systemLanguage -eq 'pt-BR') {
        auditpol /set /subcategory:"Criação de processo" /success:enable /failure:enable
    }
    else {
        auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable
    }
}
catch {
    Write-Host "Failed to set audit policy to monitor Qbitorrent process. Search for Audit Process Creation on Google and create it manually."
    Write-Host "If the policy is not enabled, the port will not be automatically updated when Qbitorrent is opened, only when ProtonVPN connects."
    Write-Host "Press any key to continue the rest of the setup"
    Pause
}

$currentDateTime = [string](Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffffff")

[xml]$xmlContent = Get-Content -Path $xmlPath -Encoding Unicode

$qbittorrentPath = $null

do {
    Clear-Host
    Write-Host "Please enter the path to qbittorrent.exe (e.g., C:\Program Files\qBittorrent\qbittorrent.exe)"
    $qbittorrentPath = Read-Host ">> "
    
    if (Test-Path $qbittorrentPath) {
        break
    }
    else {
        Write-Host "The path you entered does not exist. Please try again."
    }
} while ($true)

# <QueryList>
#   <Query Id="0" Path="Security">
#     <Select Path="Security">
#       *[System[(EventID=4688)]] and 
#       *[EventData[Data[@Name='NewProcessName'] and (Data='D:\ServerMedia\.qbittorrent\qbittorrent.exe')]]
#     </Select>
#     <Select Path="Microsoft-Windows-NetworkProfile/Operational">
#       *[System[Provider[@Name='Microsoft-Windows-NetworkProfile'] and (EventID=10000)]] and
#       *[EventData[Data[@Name='Name'] and (Data='ProtonVPN')]]
#     </Select>
#   </Query>
# </QueryList>


if ($sid) {
    Clear-Host
    $xmlContent.Task.Settings.NetworkSettings.Id = $protonVPNGuid
    $xmlContent.Task.Principals.Principal.UserId = $sid
    $xmlContent.Task.RegistrationInfo.Date = $currentDateTime
    $xmlContent.Task.RegistrationInfo.Author = $currentUser
    $xmlContent.Task.Triggers.EventTrigger.Subscription = @"
        <QueryList>
            <Query Id="0" Path="Security">
                <Select Path="Security">
                    *[System[(EventID=4688)]] and 
                    *[EventData[Data[@Name='NewProcessName'] and (Data='$qbittorrentPath')]]
                </Select>
                <Select Path="Microsoft-Windows-NetworkProfile/Operational">
                    *[System[Provider[@Name='Microsoft-Windows-NetworkProfile'] and (EventID=10000)]] and
                    *[EventData[Data[@Name='Name'] and (Data='ProtonVPN')]]
                </Select>
            </Query>
        </QueryList>
"@

    Register-ScheduledTask -TaskName "Qbitorrent-ProtonVPN port Updater" -Xml $xmlContent.OuterXml -Force
    Write-Host "Scheduled task created successfully."
    Pause
    exit 0
}
else {
    Write-Host "Failed to create scheduled task."
    Pause
    exit 1
}
