Dim translations, systemLang
Set translations = CreateObject("Scripting.Dictionary")

systemLang = GetSystemLanguage()

' Definindo os idiomas disponiveis
If systemLang = "pt-BR" Then
    ' Portugues
    translations.Add "START_CHECK", "Iniciando verificacao de conexao com qBittorrent."
    translations.Add "CONNECTION_SUCCESS", "Conexao estabelecida com qBittorrent."
    translations.Add "CONNECTION_FAIL", "Nao foi possivel conectar ao qBittorrent."
    translations.Add "PORT_FOUND", "Porta encontrada no log do ProtonVPN: "
    translations.Add "PORT_NOT_FOUND", "Nenhuma porta encontrada no log."
    translations.Add "LOG_FILE_NOT_FOUND", "Arquivo de log nao encontrado:"
    translations.Add "API_ERROR", "Erro ao conectar a API do qBittorrent:"
    translations.Add "HTTP_ERROR", "Erro HTTP ao atualizar porta:"
    translations.Add "PORT_UPDATED", "Porta atualizada no qBittorrent para: "
    translations.Add "PORT_UPDATED_TITLE", "Porta Atualizada"
    translations.Add "PORT_UPDATED_BODY", "Porta atualizada no qBittorrent para: "
    translations.Add "START_PORT_EXTRACTION", "Iniciando extracao da porta."
    translations.Add "LAST_SENT_PORT", "Ultima porta enviada para o qBittorrent: "
    translations.Add "NEW_PORT_DETECTED", "Nova porta detectada. Atualizando qBittorrent."
    translations.Add "PORT_NOT_CHANGED", "Porta nao mudou. Nenhuma atualizacao necessaria."
    translations.Add "NO_PORT_FOUND", "Nenhuma porta encontrada ou log inacessivel."
    translations.Add "ERROR", "Erro"

Else
    ' Idioma por padrao (caso nao reconhecido)
    translations.Add "START_CHECK", "Starting connection check with qBittorrent."
    translations.Add "CONNECTION_SUCCESS", "Connection established with qBittorrent."
    translations.Add "CONNECTION_FAIL", "Could not connect to qBittorrent after 20 attempts."
    translations.Add "PORT_FOUND", "Port found in log: "
    translations.Add "PORT_NOT_FOUND", "No port found in the log."
    translations.Add "LOG_FILE_NOT_FOUND", "Log file not found:"
    translations.Add "API_ERROR", "Error connecting to qBittorrent API:"
    translations.Add "HTTP_ERROR", "HTTP error updating port:"
    translations.Add "PORT_UPDATED", "Port updated in qBittorrent to: "
    translations.Add "PORT_UPDATED_TITLE", "Port Updated"
    translations.Add "PORT_UPDATED_BODY", "Port updated in qBittorrent to: "
    translations.Add "START_PORT_EXTRACTION", "Starting port extraction."
    translations.Add "LAST_SENT_PORT", "Last sent port: "
    translations.Add "NEW_PORT_DETECTED", "New port detected. Updating qBittorrent."
    translations.Add "PORT_NOT_CHANGED", "Port did not change. No update needed."
    translations.Add "NO_PORT_FOUND", "No port found or log inaccessible."
    translations.Add "ERROR", "Error"
End If

Function GetText(key)
    If translations.Exists(key) Then
        GetText = translations(key)
    Else
        GetText = key
    End If
End Function

Function GetSystemLanguage()
    Dim wshShell
    Set wshShell = CreateObject("WScript.Shell")
    GetSystemLanguage = wshShell.RegRead("HKEY_CURRENT_USER\Control Panel\International\LocaleName")
    Set wshShell = Nothing
End Function
