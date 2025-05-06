Set objShell = CreateObject("Wscript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
strCurrentPath = objFSO.GetParentFolderName(WScript.ScriptFullName)

objShell.Run "powershell.exe -ExecutionPolicy Bypass -NoProfile -File """ & strCurrentPath & ".\ProtonVPN-PortMonitor.ps1""", 0, False

WScript.Sleep 5000

objShell.Run "powershell.exe -ExecutionPolicy Bypass -NoProfile -File """ & strCurrentPath & ".\qBittorrent-PortSync.ps1""", 0, False