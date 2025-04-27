' Configurações do qBittorrent
qbittorrentUrl = "http://localhost:8078"

' Caminho do arquivo de log
logProtonVPN = "C:\Users\Admin\AppData\Local\Proton\Proton VPN\Logs\client-logs.1.txt"

logScript = "C:\Users\Admin\Documents\github\proton_port_updater\log.txt"

' Nome da variável de ambiente global
envVarName = "LAST_SENT_PORT"

' Função para exibir notificações do Windows usando BurntToast
Sub ShowNotification(title, message)
    Dim psCommand
    psCommand = "powershell -Command ""New-BurntToastNotification -Text '" & title & "', '" & message & "' -Silent"""
    CreateObject("WScript.Shell").Run psCommand, 0, False
End Sub

' Função para verificar se a porta está aberta
Function IsPortOpen(url)
    On Error Resume Next
    Dim http
    Set http = CreateObject("MSXML2.XMLHTTP")
    http.Open "GET", url, False
    http.Send
    If Err.Number = 0 And http.Status = 200 Then
        IsPortOpen = True
    Else
        IsPortOpen = False
    End If
    Set http = Nothing
    On Error GoTo 0
End Function

' Tenta verificar a porta até 20 vezes com intervalos de 500ms
Dim i
For i = 1 To 20
    If IsPortOpen(qbittorrentUrl) Then
        Exit For
    End If
    WScript.Sleep 500
Next

' Função para extrair a última porta do log
Function GetLatestPort(logProtonVPN)
    Dim objFSO, objFile, line, matches, port
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    
    If objFSO.FileExists(logProtonVPN) Then
        Set objFile = objFSO.OpenTextFile(logProtonVPN, 1, False)
        
        Set matches = CreateObject("VBScript.RegExp")
        matches.Pattern = "Port pair (\d+)->\d+"
        matches.IgnoreCase = True
        matches.Global = False
        
        Do Until objFile.AtEndOfStream
            line = objFile.ReadLine
            If matches.Test(line) Then
                Set match = matches.Execute(line)
                port = match(0).SubMatches(0)
            End If
        Loop
        objFile.Close
        
        If IsEmpty(port) Or IsNull(port) Then
            GetLatestPort = ""
        Else
            GetLatestPort = port
        End If
    Else
        GetLatestPort = ""
    End If
End Function

' Função para atualizar a porta no qBittorrent
Sub UpdateqBittorrentPort(port)
    Dim http, updateUrl, postData
    updateUrl = qbittorrentUrl & "/api/v2/app/setPreferences"
    postData = "json={""listen_port"":" & port & "}"

    On Error Resume Next
    Set http = CreateObject("MSXML2.XMLHTTP")
    http.Open "POST", updateUrl, False
    http.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
    http.Send postData

    If Err.Number <> 0 Then
        ShowNotification "Erro", "Erro ao conectar a API do qBittorrent: " & Err.Description
        Err.Clear
    ElseIf http.Status <> 200 Then
        ShowNotification "Erro", "Erro ao atualizar porta: HTTP " & http.Status & " - " & http.StatusText
    Else
        Set objShell = CreateObject("WScript.Shell")
        objShell.Environment("SYSTEM")(envVarName) = port
        ShowNotification "Porta Atualizada", "Porta atualizada no qBittorrent para: " & port
    End If
    On Error GoTo 0
End Sub

' Função para obter a última porta enviada
Function GetLastSentPort()
    Set objShell = CreateObject("WScript.Shell")
    On Error Resume Next
    GetLastSentPort = objShell.Environment("SYSTEM")(envVarName)
    If Err.Number <> 0 Then
        objShell.Environment("SYSTEM")(envVarName) = "0"
        GetLastSentPort = "0"
    End If
    On Error GoTo 0
End Function

port = GetLatestPort(logProtonVPN)
If port <> "" Then
    lastSentPort = GetLastSentPort()
    If port <> lastSentPort Then
        UpdateqBittorrentPort port
    Else
    End If
Else
    ShowNotification "Erro", "Nenhuma porta encontrada no log ou log inacessivel."
End If
