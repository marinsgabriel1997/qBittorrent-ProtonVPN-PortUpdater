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

' Uso
port = GetQBittorrentPort()
If port <> "" Then WScript.Echo port