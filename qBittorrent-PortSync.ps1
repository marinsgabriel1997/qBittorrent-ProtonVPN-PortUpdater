# # qBittorrent-PortSync.ps1
# # Script para atualizar a porta do qBittorrent com base na variável de ambiente PROTON_VPN_PORT_FORWARDING
# # Versão: 1.1

Clear-Host

# Configurações
$activateLog = $true
$logFilePath = "$PSScriptRoot\qbittorrent-update.log"
$envVarName = "PROTON_VPN_PORT_FORWARDING"

# Configurações de autenticação qBittorrent
# Deixe ambas vazias para usar sem autenticação. ativar "Ignorar autenticação para clientes no hospedeiro local" em `qBittorrent` → `Tools` → `Options` → `Web UI`)
# Se você deixou a autenticação ativa, adicione o usuário e a senha abaixo
$qbUsername = "administrador"
$qbPassword = "administrador"  # Agora usando string normal para senha

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
            Write-Host $logEntry
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
        "START_CHECK"        = "Nova execucao - Iniciando verificacao de conexao"
        "CONNECTION_SUCCESS" = "Conexao com qBittorrent estabelecida com sucesso"
        "CONNECTION_FAIL"    = "Falha ao conectar com qBittorrent apos varias tentativas"
        "PORT_UPDATED"       = "Porta atualizada para: "
        "PORT_UPDATED_TITLE" = "Porta Atualizada"
        "PORT_UPDATED_BODY"  = "Porta do qBittorrent atualizada para: "
        "PORT_TO_SEND"       = "Porta encontrada na variavel de ambiente: "
        "ERROR"              = "Erro"
        "API_ERROR"          = "Erro na API do qBittorrent:"
        "HTTP_ERROR"         = "Erro HTTP:"
        "NO_ENV_PORT"        = "Nenhuma porta válida na variável de ambiente"
        "QB_NOT_RUNNING"     = "qBittorrent não está em execução"
        "AUTH_DISABLED"      = "Autenticação desabilitada para localhost"
        "LOGIN_SUCCESS"      = "Login realizado com sucesso"
        "LOGIN_FAIL"         = "Falha no login: verifique as credenciais"
        "LOGIN_ERROR"        = "Erro durante o login:"
    }

    return $texts[$key]
}

# Garantir que o módulo BurntToast esteja disponível
function EnsureNotificationModuleAvailable {
    if (-not (Get-Module -ListAvailable -Name BurntToast)) {
        try {
            Install-Module -Name BurntToast -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        }
        catch {
            # Adicionar referência para MessageBox como fallback
            Add-Type -AssemblyName System.Windows.Forms
        }
    }
}

# Função para mostrar notificação
function ShowNotification([string]$title, [string]$message) {
    try {
        New-BurntToastNotification -Text $title, $message -Silent
    }
    catch {
        # Fallback caso o módulo BurntToast não esteja instalado
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($message, $title)
    }
}

# Verifica se o qBittorrent está em execução
function IsQBittorrentRunning {
    return $null -ne (Get-Process -Name qbittorrent -ErrorAction SilentlyContinue)
}

# Função para obter a porta do qBittorrent
function GetQBittorrentWebUiPort {
    try {
        # Pegar o PID
        $qbProcess = Get-Process -Name qbittorrent -ErrorAction SilentlyContinue
        
        if ($null -eq $qbProcess) {
            return 0  # Retornar 0 indica erro
        }
        
        # Buscar portas de escuta deste PID
        $tcpConnection = Get-NetTCPConnection -OwningProcess $qbProcess.Id -State Listen -ErrorAction SilentlyContinue | 
        Select-Object -First 1 LocalPort
        
        if ($null -eq $tcpConnection) {
            return 8080  # Porta padrão se não conseguir detectar
        }
        
        return $tcpConnection.LocalPort
    }
    catch {
        if ($activateLog) {
            $logger.Write("Erro ao obter porta do qBittorrent: $($_.Exception.Message)")
        }
        return 8080  # Porta padrão em caso de erro
    }
}

# Função para verificar se a porta está aberta
function IsPortOpen([string]$url) {
    try {
        $request = [System.Net.WebRequest]::Create($url)
        $request.Timeout = 5000 # 5 segundos
        $response = $request.GetResponse()
        $response.Close()
        return $true
    }
    catch {
        return $false
    }
}

# Função para obter a última porta da variável de ambiente
function GetLastSentPort {
    try {
        $lastPort = [Environment]::GetEnvironmentVariable($envVarName, "User")
        
        if ([string]::IsNullOrEmpty($lastPort) -or $lastPort -eq "0") {
            return ""  # Retorna vazio para indicar erro
        }
        
        return $lastPort
    }
    catch {
        if ($activateLog) {
            $logger.Write("Erro ao obter última porta: $($_.Exception.Message)")
        }
        return ""
    }
}

# Função para fazer login no qBittorrent WebUI
function LoginToQBittorrent([string]$url, [string]$username, [string]$password) {
    # Se não tiver credenciais, assume que está usando LocalHostAuth=false
    if ([string]::IsNullOrEmpty($username) -or [string]::IsNullOrEmpty($password)) {
        if ($activateLog) {
            $logger.Write("Credenciais vazias, assumindo LocalHostAuth=false")
        }
        return $true
    }
    
    try {
        $loginUrl = "$url/api/v2/auth/login"
        $postData = "username=$username&password=$password"
        
        $response = Invoke-WebRequest -Uri $loginUrl -Method Post -Body $postData -ContentType "application/x-www-form-urlencoded" -SessionVariable script:qbSession -ErrorAction Stop
        
        if ($response.StatusCode -ne 200) {
            if ($activateLog) {
                $logger.Write("Falha no login: $($response.StatusCode)")
            }
            return $false
        }
        
        if ($activateLog) {
            $logger.Write("Login no qBittorrent realizado com sucesso")
        }
        return $true
    }
    catch {
        if ($activateLog) {
            $logger.Write("Erro durante o login: $($_.Exception.Message)")
        }
        return $false
    }
}

# Função para verificar conexão com qBittorrent
function EnsureQBittorrentConnection([string]$url) {
    if ($activateLog) {
        $logger.Write("------------------------------------------------")
        $logger.Write($(GetText 'START_CHECK'))
        $logger.Write("------------------------------------------------")
    }

    for ($i = 1; $i -le 20; $i++) {
        if (IsPortOpen $url) {
            if ($activateLog) {
                $logger.Write($(GetText 'CONNECTION_SUCCESS'))
            }
            return $true
        }
        Start-Sleep -Milliseconds 500
    }

    if ($activateLog) {
        $logger.Write($(GetText 'CONNECTION_FAIL'))
    }
    return $false
}

# Função para atualizar a porta no qBittorrent
function UpdateQBittorrentPort([string]$port, [string]$qbittorrentUrl) {
    # Endpoints da API
    $getPrefsUrl = "$qbittorrentUrl/api/v2/app/preferences"
    $updateUrl = "$qbittorrentUrl/api/v2/app/setPreferences"
    $postData = "json={""listen_port"":$port}"
    
    # Verifica autenticação somente se necessário
    if (-not [string]::IsNullOrEmpty($qbUsername) -and -not [string]::IsNullOrEmpty($qbPassword)) {
        $loginSuccess = LoginToQBittorrent $qbittorrentUrl $qbUsername $qbPassword
        
        if (-not $loginSuccess) {
            if ($activateLog) {
                $logger.Write("Falha na autenticação. Não foi possível verificar/atualizar a porta.")
            }
            
            ShowNotification $(GetText 'ERROR') "Falha na autenticação no qBittorrent"
            return $false
        }
    }
    
    try {
        # Prepara parâmetros para obter configurações
        $invokeParams = @{
            Uri         = $getPrefsUrl
            Method      = 'GET'
            ErrorAction = 'Stop'
        }
        
        # Adiciona WebSession apenas se estiver autenticado
        if (-not [string]::IsNullOrEmpty($qbUsername) -and -not [string]::IsNullOrEmpty($qbPassword)) {
            $invokeParams['WebSession'] = $script:qbSession
        }
        
        # Obter configurações atuais
        $prefsResponse = Invoke-WebRequest @invokeParams
        
        if ($prefsResponse.StatusCode -ne 200) {
            if ($activateLog) {
                $logger.Write("Erro ao obter preferências: $($prefsResponse.StatusCode)")
            }
            return $false
        }
        
        $currentPrefs = $prefsResponse.Content | ConvertFrom-Json
        $currentPort = $currentPrefs.listen_port
        
        if ($activateLog) {
            $logger.Write("Porta atual configurada: $currentPort")
            $logger.Write("Porta desejada: $port")
        }
        
        # Verificar se a porta já está configurada com o valor desejado
        if ($currentPort -eq $port) {
            if ($activateLog) {
                $logger.Write("Porta já está configurada corretamente. Nenhuma atualização necessária.")
            }
            return $true
        }
        
        # Porta diferente, prosseguir com a atualização
        if ($activateLog) {
            $logger.Write("Porta diferente. Iniciando atualização...")
        }
        
        # Prepara parâmetros para atualização
        $updateParams = @{
            Uri         = $updateUrl
            Method      = 'Post'
            Body        = $postData
            ContentType = 'application/x-www-form-urlencoded'
            ErrorAction = 'Stop'
        }
        
        # Adiciona WebSession apenas se estiver autenticado
        if (-not [string]::IsNullOrEmpty($qbUsername) -and -not [string]::IsNullOrEmpty($qbPassword)) {
            $updateParams['WebSession'] = $script:qbSession
        }
        
        $response = Invoke-WebRequest @updateParams
        
        if ($response.StatusCode -ne 200) {
            if ($activateLog) {
                $logger.Write("$(GetText 'HTTP_ERROR') $($response.StatusCode)")
            }
            
            ShowNotification $(GetText 'ERROR') "$(GetText 'HTTP_ERROR') $($response.StatusCode)"
            return $false
        }
        
        if ($activateLog) {
            $logger.Write("Porta atualizada com sucesso de $currentPort para $port")
        }
        
        ShowNotification "$(GetText 'PORT_UPDATED_TITLE')" "$(GetText 'PORT_UPDATED_BODY')${port}"
        return $true
    }
    catch {
        if ($activateLog) {
            $logger.Write("$(GetText 'API_ERROR') $($_.Exception.Message)")
        }
        
        ShowNotification $(GetText 'ERROR') "$(GetText 'API_ERROR') $($_.Exception.Message)"
        return $false
    }
}

# --- INÍCIO DA EXECUÇÃO PRINCIPAL ---

# Preparação inicial - Garantir que o módulo de notificações esteja disponível
EnsureNotificationModuleAvailable

# 1. VERIFICAÇÃO RÁPIDA: Verificar se o qBittorrent está rodando (early return)
if (-not (IsQBittorrentRunning)) {
    if ($activateLog) {
        $logger.Write($(GetText 'QB_NOT_RUNNING'))
    }
    exit
}

# 2. Obter a porta do qBittorrent WebUI
$port = GetQBittorrentWebUiPort
if ($port -eq 0) {
    if ($activateLog) {
        $logger.Write("Falha ao obter porta do qBittorrent WebUI")
    }
    exit
}

# 3. Configurar URL e verificar conexão
$qbittorrentUrl = "http://localhost:${port}"
if (-not (EnsureQBittorrentConnection $qbittorrentUrl)) {
    exit
}

# 4. Obter a porta da variável de ambiente (early return)
$vpnPort = GetLastSentPort
if ([string]::IsNullOrEmpty($vpnPort)) {
    if ($activateLog) {
        $logger.Write($(GetText 'NO_ENV_PORT'))
    }
    exit
}

# 5. Logar a porta que será configurada
if ($activateLog) {
    $logger.Write("$(GetText 'PORT_TO_SEND')$vpnPort")
}

# 6. Atualizar a porta no qBittorrent
$null = UpdateQBittorrentPort $vpnPort $qbittorrentUrl