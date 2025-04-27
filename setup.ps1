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


    $confirmation = Read-Host "Do you want to run as administrator? ([Y]/N - Y Default)"
    
    if ($confirmation -eq '' -or $confirmation -eq 'Y' -or $confirmation -eq 'y') {
        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" `"$currentUserSID`" `"$currentUser`" `"$updatePortVBSPath`" `"$languagesVBSPath`"" -Verb RunAs
        exit
    } else {
        Write-Host "Script execution canceled."
        exit
    }
}

$sid = $args[0]
$currentUser = $args[1]
$updatePortVBSPath = $args[2]
$languagesVBSPath = $args[3]
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$xmlPath = Join-Path -Path $scriptDir -ChildPath "task_config.xml"

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
    exit 1
}

$destinationPath = "C:\Program Files\QbittorrentProtonVPNUpdater"

if (-not (Test-Path $destinationPath)) {
    New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
}

Copy-Item -Path $updatePortVBSPath -Destination $destinationPath -Force
Copy-Item -Path $languagesVBSPath -Destination $destinationPath -Force

$currentDateTime = [string](Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffffff")

[xml]$xmlContent = Get-Content -Path $xmlPath -Encoding Unicode

$RegistrationInfo = $xmlContent.Task.RegistrationInfo
$NetworkSettings = $xmlContent.Task.Settings.NetworkSettings
$UserIdNode = $xmlContent.Task.Principals.Principal

if ($sid) {
    $NetworkSettings.Id = $protonVPNGuid
    $UserIdNode.UserId = $sid
    $RegistrationInfo.Date = $currentDateTime
    $RegistrationInfo.Author = $currentUser

    Register-ScheduledTask -TaskName "Qbitorrent-ProtonVPN port Updater" -Xml $xmlContent.OuterXml -Force
    Write-Host "Scheduled task created successfully."
    Pause
    exit 0
} else {
    Write-Host "Failed to create scheduled task."
    Pause
    exit 1
}
