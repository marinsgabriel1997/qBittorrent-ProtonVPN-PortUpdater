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
Clear-Host

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  
    Write-Host "This script requires administrator privileges."
    
    $currentUserSID = ([Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
    $currentUser = ([Security.Principal.WindowsIdentity]::GetCurrent()).Name    
    $updatePortVBSPath = Join-Path $PSScriptRoot "update_port.vbs"
    $ProtonVPNPortMonitor = Join-Path $PSScriptRoot "ProtonVPN-PortMonitor.ps1"
    $qBittorrentPortSync = Join-Path $PSScriptRoot "qBittorrent-PortSync.ps1"    
    $xmlPath = Join-Path $PSScriptRoot "task_config.xml"

    $confirmation = Read-Host "Do you want to run as administrator? ([Y]/N - Y Default)"
    
    if ($confirmation -ne '' -and $confirmation -ne 'Y' -and $confirmation -ne 'y') {
        Write-Host "Script execution canceled."
        return
    }
    
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$currentUserSID`" `"$currentUser`" `"$updatePortVBSPath`" `"$ProtonVPNPortMonitor`" `"$qBittorrentPortSync`" `"$xmlPath`"" -Verb RunAs
    exit
}

Clear-Host

$sid = if ($args.Count -gt 0) { $args[0] } else { ([Security.Principal.WindowsIdentity]::GetCurrent()).User.Value }
$currentUser = if ($args.Count -gt 1) { $args[1] } else { ([Security.Principal.WindowsIdentity]::GetCurrent()).Name }
$updatePortVBSPath = if ($args.Count -gt 2) { $args[2] } else { Join-Path $PSScriptRoot "update_port.vbs" }
$ProtonVPNPortMonitor = if ($args.Count -gt 3) { $args[3] } else { Join-Path $PSScriptRoot "ProtonVPN-PortMonitor.ps1" }
$qBittorrentPortSync = if ($args.Count -gt 4) { $args[4] } else { Join-Path $PSScriptRoot "qBittorrent-PortSync.ps1" }
$xmlPath = if ($args.Count -gt 5) { $args[5] } else { Join-Path $PSScriptRoot "task_config.xml" }

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
    Write-Host "ProtonVPN profile not found in the registry. Please start Proton VPN and connect using port forwarding."
    Pause
}

$destinationPath = "C:\Program Files\QbittorrentProtonVPNUpdater"

if (-not (Test-Path $destinationPath)) {
    New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
}

Copy-Item -Path $updatePortVBSPath -Destination $destinationPath -Force
Copy-Item -Path $ProtonVPNPortMonitor -Destination $destinationPath -Force
Copy-Item -Path $qBittorrentPortSync -Destination $destinationPath -Force

$systemLanguage = (Get-WinSystemLocale).Name


if ($systemLanguage -eq 'pt-BR') {
    auditpol /set /subcategory:"Criação de processo" /success:enable /failure:enable
}
elseif ($systemLanguage -eq 'en-US') {
    auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable
}
else {
    Write-Host ""
    Write-Host "WARNING:" -ForegroundColor Yellow
    Write-Host "Failed to set the audit policy for monitoring the Qbittorrent process." -ForegroundColor Red
    Write-Host "Search for 'Enable Audit Process Creation' and configure it manually via Local Security Policy or Group Policy." -ForegroundColor White
    Write-Host "Without this policy, the port will only update automatically when ProtonVPN connects — not when Qbittorrent starts." -ForegroundColor White
    Write-Host "" 
    Write-Host "Press any key to continue the setup..." -ForegroundColor Cyan
    Write-Host ""
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 
}

$currentDateTime = [string](Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffffff")

[xml]$xmlContent = Get-Content -Path $xmlPath -Encoding Unicode

$qbittorrentPath = $null

do {
    # Clear-Host
    Write-Host "_____________________________________________________________________________________________"
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
    Clear-Host
    Write-Host "Itens copied to $destinationPath"
    Write-Host "Scheduled task created successfully."
    Pause
    exit 0
}
else {
    Write-Host "Failed to create scheduled task."
    Pause
    exit 1
}
