# ProtonVPN-PortMonitor.ps1
# Script para extrair porta do ProtonVPN e armazenar na variável de ambiente PROTON_VPN_PORT_FORWARDING
# Versão: 1.0

# ### ProtonVPN-PortManager.ps1
# - Monitora logs do ProtonVPN
# - Extrai porta mais recente
# - Salva em variável de ambiente PROTON_VPN_PORT_FORWARDING
# - Não retorna nada
# - Tratamento de erros robusto
# - Todas as mensagens em arquivo de log, nunca use Write-Host.

Clear-Host

# Configurações
$activateLog = $true
$logFilePath = "$PSScriptRoot\protonvpn-port.log"
$envVarName = "PROTON_VPN_PORT_FORWARDING"

# Classe de logger
class Logger {
    [string]$LogPath

    Logger([string]$logPath) {
        $this.LogPath = $logPath
    }

    [void] Write([string]$message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp - $message"
        
        try {
            Add-Content -Path $this.LogPath -Value $logEntry -ErrorAction Stop
        }
        catch {
            Write-Host "Erro ao escrever no log: $($_.Exception.Message)"
        }
    }
}

# Inicializa o logger
$logger = [Logger]::new($logFilePath)

# Função para obter textos localizados
function GetText([string]$key) {
    $texts = @{
        "START_PORT_EXTRACTION" = "Iniciando extracao de porta dos logs do ProtonVPN"
        "PORT_FOUND"            = "Porta encontrada: "
        "PORT_NOT_FOUND"        = "Nenhuma informacao de porta encontrada nos logs"
        "LOG_FILE_NOT_FOUND"    = "Arquivo de log nao encontrado, conecte-se com a Proton VPN com o encaminhamento de porta habilitado:"
        "LAST_SENT_PORT"        = "Ultima porta enviada: "
        "NEW_PORT_DETECTED"     = "Nova porta detectada"
        "PORT_NOT_CHANGED"      = "Porta nao mudou, nenhuma atualizacao necessaria"
        "NO_PORT_FOUND"         = "Nenhuma porta encontrada nos logs do ProtonVPN"
        "PORT_UPDATED"          = "Porta atualizada para: "
        "ERROR"                 = "Erro"
    }

    return $texts[$key]
}

# Função para obter o usuário atual
function GetCurrentUser {
    return [System.Environment]::UserName
}

# Função para obter a última porta da variável de ambiente
function GetLastSentPort {
    try {
        $lastPort = [Environment]::GetEnvironmentVariable($envVarName, "User")
        
        if ([string]::IsNullOrEmpty($lastPort)) {
            [Environment]::SetEnvironmentVariable($envVarName, "0", "User")
            return "0"
        }
        
        return $lastPort
    }
    catch {
        if ($activateLog) {
            $logger.Write("Erro ao obter última porta: $($_.Exception.Message)")
        }
        return "0"
    }
}

# Função para obter a porta mais recente dos logs do ProtonVPN
function GetLatestPort([string]$logProtonVPN) {
    if (-not (Test-Path $logProtonVPN)) {
        if ($activateLog) {
            $logger.Write("$(GetText 'LOG_FILE_NOT_FOUND')")
        }
        return ""
    }
    
    try {
        $logContent = Get-Content $logProtonVPN -ErrorAction Stop
        
        # Procura pela última ocorrência de padrão "Port pair XXXX->YYYY"
        $portPattern = "Port pair (\d+)->\d+"
        
        for ($i = $logContent.Count - 1; $i -ge 0; $i--) {
            if ($logContent[$i] -match $portPattern) {
                $port = $matches[1]
                if ($activateLog) {
                    $logger.Write("$(GetText 'PORT_FOUND')$port")
                }
                return $port
            }
        }
        
        if ($activateLog) {
            $logger.Write($(GetText 'PORT_NOT_FOUND'))
        }
        return ""
    }
    catch {
        if ($activateLog) {
            $logger.Write("Erro ao ler arquivo de log: $($_.Exception.Message)")
        }
        return ""
    }
}

# Script Principal
if ($activateLog) {
    $logger.Write("--------------------------------")
    $logger.Write($(GetText 'START_PORT_EXTRACTION'))
}

# Configurar caminhos
$currentUser = GetCurrentUser
$logProtonVPN = "C:\Users\${currentUser}\AppData\Local\Proton\Proton VPN\Logs\client-logs.txt"

# Extrair informações de porta do ProtonVPN
$vpnPort = GetLatestPort $logProtonVPN

if ([string]::IsNullOrEmpty($vpnPort)) {
    if ($activateLog) {
        $logger.Write($(GetText 'NO_PORT_FOUND'))
    }
    exit
}

# Verificar se a porta mudou
$lastSentPort = GetLastSentPort
if ($activateLog) {
    $logger.Write("$(GetText 'LAST_SENT_PORT')$lastSentPort")
}

if ($vpnPort -ne $lastSentPort) {
    if ($activateLog) {
        $logger.Write($(GetText 'NEW_PORT_DETECTED'))
    }
    # Atualizar variável de ambiente com a nova porta
    [Environment]::SetEnvironmentVariable($envVarName, $vpnPort, "User")
    if ($activateLog) {
        $logger.Write("$(GetText 'PORT_UPDATED')$vpnPort")
    }
} 
else {
    if ($activateLog) {
        $logger.Write($(GetText 'PORT_NOT_CHANGED'))
    }
}