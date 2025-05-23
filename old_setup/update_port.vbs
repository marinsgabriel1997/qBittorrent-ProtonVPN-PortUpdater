' Use log for debugging purposes, set `activateLog` to False to disable logging
' ## Overview
' This VBScript is designed to check and manage port connections for qBittorrent through Proton VPN.

' ## Features
' - Checks qBittorrent port availability
' - Logs connection attempts
' - Supports Windows desktop notifications
' - Monitors Proton VPN log files for port information

' ## Functions

' ### `IsPortOpen(url)`
' Checks if a specified URL/port is accessible
' - Parameters:
'   - `url`: The URL to test connection
' - Returns: Boolean indicating port availability

' ### `ShowNotification(title, message)`
' Displays a Windows toast notification
' - Parameters:
'   - `title`: Notification title
'   - `message`: Notification message
' - Uses PowerShell to generate notifications

' ### `GetLatestPort(logProtonVPN)`
' Extracts the latest port information from Proton VPN logs
' - Parameters:
'   - `logProtonVPN`: Path to Proton VPN log file
' - Functionality:
'   - Reads log file
'   - Uses regex to find port pair information

' ## Configuration
' - Default qBittorrent URL: `http://localhost:8078`
' - Default Proton VPN Log Path: `C:\Users\Admin\AppData\Local\Proton\Proton VPN\Logs\client-logs.txt`

' ## Dependencies
' - Windows Script Host
' - PowerShell (for notifications)
' - Proton VPN
' - qBittorrent

Dim fso, langFile, currentPath, activateLog
Set fso = CreateObject("Scripting.FileSystemObject")
currentPath = fso.GetParentFolderName(WScript.ScriptFullName)
Set langFile = fso.OpenTextFile(currentPath & "\languages.vbs", 1)
ExecuteGlobal langFile.ReadAll
langFile.Close

Function GetCurrentUser()
    Dim network
    Set network = CreateObject("WScript.Network")
    GetCurrentUser = network.UserName
End Function

Function GetQBittorrentPort()
    Dim shell, exec, line, parts, port
    
    Set shell = CreateObject("WScript.Shell")
    
    ' Verificar se o qBittorrent está rodando e pegar o PID
    Set exec = shell.Exec("cmd /c tasklist /fi ""imagename eq qbittorrent.exe"" /fo csv /nh")
    line = exec.StdOut.ReadLine()
    
    If Len(line) = 0 Then Exit Function  ' qBittorrent não está rodando
    
    ' Extrair o PID
    qbPID = Split(Replace(line, """", ""), ",")(1)
    
    ' Buscar portas de escuta deste PID
    Set exec = shell.Exec("cmd /c netstat -ano | findstr " & qbPID & " | findstr LISTENING")
    
    ' Encontrar a primeira porta
    Do Until exec.StdOut.AtEndOfStream
        line = exec.StdOut.ReadLine()
        parts = Split(Trim(line))
        
        For Each part In parts
            If InStr(part, ":") > 0 Then
                port = Mid(part, InStrRev(part, ":") + 1)
                GetQBittorrentPort = port
                Exit Function
            End If
        Next
    Loop
End Function


Sub Log(message)
    WScript.Echo Now & " - " & message
End Sub

Sub ShowNotification(title, message)
    Dim psCommand
    psCommand = "powershell -Command ""New-BurntToastNotification -Text '" & title & "', '" & message & "' -Silent"""
    CreateObject("WScript.Shell").Run psCommand, 0, False
End Sub

' Uso
port = GetQBittorrentPort()

' Usa 8080 se não conseguir pegar a porta do qBittorrent
If port = "" Then
    port = 8080
End If

currentUser = GetCurrentUser()
logProtonVPN = "C:\Users\" & currentUser & "\AppData\Local\Proton\Proton VPN\Logs\client-logs.txt"
envVarName = "LAST_SENT_PORT"
qbittorrentUrl = "http://localhost:" & port
activateLog = False

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

Dim i
If activateLog Then Log GetText("START_CHECK")
For i = 1 To 20
    If IsPortOpen(qbittorrentUrl) Then
        If activateLog Then Log GetText("CONNECTION_SUCCESS")
        Exit For
    End If
    WScript.Sleep 500
Next
If i > 20 Then
    If activateLog Then Log GetText("CONNECTION_FAIL")
End If

Function GetLatestPort(logProtonVPN)
    Dim objFSO, objFile, lines, line, matches, port, i
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    
    If objFSO.FileExists(logProtonVPN) Then
        Set objFile = objFSO.OpenTextFile(logProtonVPN, 1, False)
        lines = Split(objFile.ReadAll, vbCrLf)
        objFile.Close

        Set matches = CreateObject("VBScript.RegExp")
        matches.Pattern = "Port pair (\d+)->\d+"
        matches.IgnoreCase = True
        matches.Global = False

        For i = UBound(lines) To 0 Step - 1
            line = lines(i)
            If matches.Test(line) Then
                Set match = matches.Execute(line)
                port = match(0).SubMatches(0)
                If activateLog Then Log GetText("PORT_FOUND") & port
                Exit For
            End If
        Next

        If IsEmpty(port) Or IsNull(port) Then
            GetLatestPort = ""
            If activateLog Then Log GetText("PORT_NOT_FOUND")
        Else
            GetLatestPort = port
        End If
    Else
        GetLatestPort = ""
        If activateLog Then Log GetText("LOG_FILE_NOT_FOUND") & " " & logProtonVPN
    End If
End Function

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
        If activateLog Then Log GetText("API_ERROR") & " " & Err.Description
        ShowNotification GetText("ERROR"), GetText("API_ERROR") & " " & Err.Description
        Err.Clear
    ElseIf http.Status <> 200 Then
        If activateLog Then Log GetText("HTTP_ERROR") & " " & http.Status & " - " & http.StatusText
        ShowNotification GetText("ERROR"), GetText("HTTP_ERROR") & " " & http.Status & " - " & http.StatusText
    Else
        Set objShell = CreateObject("WScript.Shell")
        objShell.Environment("USER")(envVarName) = port
        If activateLog Then Log GetText("PORT_UPDATED") & port
        ShowNotification GetText("PORT_UPDATED_TITLE"), GetText("PORT_UPDATED_BODY") & port
    End If
    On Error GoTo 0
End Sub

Function GetLastSentPort()
    Set objShell = CreateObject("WScript.Shell")
    On Error Resume Next
    GetLastSentPort = objShell.Environment("USER")(envVarName)
    If Err.Number <> 0 Then
        objShell.Environment("USER")(envVarName) = "0"
        GetLastSentPort = "0"
    End If
    On Error GoTo 0
End Function

If activateLog Then Log GetText("START_PORT_EXTRACTION")
port = GetLatestPort(logProtonVPN)
If port <> "" Then
    lastSentPort = GetLastSentPort()
    If activateLog Then Log GetText("LAST_SENT_PORT") & lastSentPort
    If port <> lastSentPort Then
        If activateLog Then Log GetText("NEW_PORT_DETECTED")
        UpdateqBittorrentPort port
    Else
        If activateLog Then Log GetText("PORT_NOT_CHANGED")
    End If
Else
    If activateLog Then Log GetText("NO_PORT_FOUND")
    ShowNotification GetText("ERROR"), GetText("NO_PORT_FOUND")
End If
