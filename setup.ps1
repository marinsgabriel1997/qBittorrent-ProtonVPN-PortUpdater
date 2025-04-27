if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script requer privilegios de administrador."
    
    $currentUserSID = ([Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
    $currentUser = ([Security.Principal.WindowsIdentity]::GetCurrent()).Name    
    $updatePortVBSPath = Join-Path $PSScriptRoot "update_port.vbs"
    
    $confirmation = Read-Host "Deseja executar como administrador? (Y/N)"
    
    if ($confirmation -eq '' -or $confirmation -eq 'Y' -or $confirmation -eq 'y') {
        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" `"$currentUserSID`" `"$currentUser`" `"$updatePortVBSPath`"" -Verb RunAs
        Pause
        exit
    } else {
        Write-Host "Execução cancelada pelo usuário."
        exit
    }
}

$sid = $args[0]
$currentUser = $args[1]
$updatePortVBSPath = $args[2]
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
    Write-Host "Nenhuma rede ProtonVPN foi encontrada."
    exit 1
}

$destinationPath = "C:\Program Files\QbittorrentProtonVPNUpdater\update_port.vbs"

if (-not (Test-Path (Split-Path $destinationPath))) {
    Write-Host "Criando o diretório de destino..."
    New-Item -Path (Split-Path $destinationPath) -ItemType Directory
}

Copy-Item -Path $updatePortVBSPath -Destination $destinationPath -Force

Write-Host "Arquivo update_port.vbs copiado para $destinationPath"
Write-Host "GUID da ProtonVPN encontrado: $protonVPNGuid"
Write-Host "SID do usuario: $sid"

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
    Write-Host "Tarefa agendada atualizada com sucesso."
    Pause
} else {
    Write-Host "Nao foi possivel encontrar NetworkSettings no arquivo XML."
    Pause
    exit 1
}
