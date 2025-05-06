# qBittorrent ProtonVPN Port Updater

## Overview

This project provides an automated solution to keep qBittorrent's listening port synchronized with the forwarded port provided by ProtonVPN. When using ProtonVPN's port forwarding feature, this tool automatically detects the new forwarded port and updates qBittorrent's settings accordingly.

The solution consists of several components:

-   A VBScript that performs the port detection and update
-   A PowerShell setup script for installation
-   A scheduled task configuration for automatic execution
-   Multi-language support for notifications and logging

## Key Features

-   **Automatic Port Detection**: Scans ProtonVPN logs for forwarded port information
-   **qBittorrent Integration**: Updates qBittorrent's listening port via its web API
-   **Multi-language Support**: Notifications available in 7 languages (English, Portuguese, Spanish, French, Russian, Arabic, Chinese)
-   **Event-based Execution**: Runs automatically when:
    -   qBittorrent starts
    -   ProtonVPN connection changes
-   **User Notifications**: Provides desktop notifications about port updates
-   **Port Change Detection**: Only updates qBittorrent when the forwarded port actually changes

## Prerequisites

Before using this tool, ensure you have:

1. **qBittorrent** installed with the following **Web UI settings** (`Tools` → `Options` → `Web UI`):

    - Web UI enabled
    - Any username and password configured
    - Authentication disabled for localhost connections
    - IP field can be left empty (the script connects to `localhost`)
    - **The Web UI port does not need to be changed manually, but you can change it if you want; the vbs script will detect it automatically**

2. **ProtonVPN** installed with:

    - Port forwarding enabled in your account settings
    - At least one successful connection established to generate log files

3. **Windows Requirements**:
    - PowerShell 5.1 or later
    - Windows Script Host (enabled by default on Windows)
    - Administrator privileges for installation

## Installation Instructions (Automatic or Manual)

### Automatic Installation

1. **Download the project files**:

    - Clone the repository or download the ZIP file containing:
        - `update_port.vbs`
        - `languages.vbs`
        - `setup.ps1`
        - `task_config.xml`

2. **Run the setup script**:

    - Right-click `setup.ps1` and select "Run with PowerShell".
    - Confirm running as Administrator when prompted.
    - The script will:
        - Create `C:\Program Files\QbittorrentProtonVPNUpdater`
        - Copy all necessary files into the folder
        - Create and register the scheduled task automatically

3. **Verify the installation**:
    - Open Task Scheduler.
    - Look for the task "Qbittorrent-ProtonVPN port Updater".
    - Ensure the files exist in `C:\Program Files\QbittorrentProtonVPNUpdater`.

### Manual Installation

1. **Download the project files**:

    - Download or clone the repository to a local folder.

2. **Create the installation directory manually**:

    - Open File Explorer.
    - Create the folder `C:\Program Files\QbittorrentProtonVPNUpdater`.

3. **Copy files manually**:

    - Copy `update_port.vbs` and `languages.vbs` into `C:\Program Files\QbittorrentProtonVPNUpdater`.

4. **Generate and Edit the Scheduled Task XML manually**:

    - Open PowerShell as Administrator.
    - Run these commands exactly as in `setup.ps1` to gather the values:

        - **Date** (for `<Date>`):
            ```powershell
            [string](Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffffff")
            ```
        - **Author** (for `<Author>`):
            ```powershell
            ([Security.Principal.WindowsIdentity]::GetCurrent()).Name
            ```
        - **UserId** (for `<UserId>`):
            ```powershell
            ([Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
            ```
        - **Task Id** (for `<Id>`):
            ```powershell
            if ($protonVPNGuid = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" | Where-Object { (Get-ItemProperty $_.PSPath).ProfileName -eq "ProtonVPN" } | Select-Object -ExpandProperty PSChildName)) { Write-Host "`nProtonVPN profile found with GUID:`n`n$protonVPNGuid`n" } else { Write-Host "ProtonVPN profile not found in the registry.`n"; Pause; exit 1 }
            ```

    - Note each output.
    - Open `task_config.xml` in a text editor.
    - Replace the placeholders with your collected values:
        - `<Date>` in `<RegistrationInfo>` → output of the **Date** command
        - `<Author>` in `<RegistrationInfo>`→ output of the **Author** command
        - `<UserId>` in `<Principals>` → output of the **UserId** command
        - `<Id>` in `<NetworkSettings>` → output from the **ProtonVPN GUID** command.
    - Save the file.
    - In Task Scheduler, choose **Import Task…**, select your edited `task_config.xml` and finish the import.

5. **Import the Scheduled Task manually**:

    - Open Task Scheduler.
    - Click "Import Task...".
    - Select your edited `task_config.xml`.
    - Complete the import process.

6. **Verify manual installation**:
    - Ensure "Qbittorrent-ProtonVPN port Updater" exists in Task Scheduler.
    - Verify that `update_port.vbs` and `languages.vbs` are in the correct directory.

### Final Verification

Regardless of the installation method:

-   Open Task Scheduler and confirm the task exists and is configured correctly.
-   Test running the task manually to confirm it updates qBittorrent's port successfully.

## Configuration

### qBittorrent Web UI Setup

1. Open qBittorrent
2. Go to Tools → Options → Web UI
3. Enable the Web UI checkbox
4. Set the port (default is 8078) - **this must match the port in the script**
5. If you use authentication, you'll need to modify the script to include credentials
6. Click "Save"

### Script Configuration (if needed)

The main configuration variables in `update_port.vbs` are:

```vbs
' qBittorrent Web UI URL (change the port if needed)
qbittorrentUrl = "http://localhost:8078"

' ProtonVPN log file path (update if your username isn't "Admin")
logProtonVPN = "C:\Users\Admin\AppData\Local\Proton\Proton VPN\Logs\client-logs.txt"
```

If you need to modify these:

1. Edit `update_port.vbs` with a text editor
2. Update the values as needed
3. Save the file
4. Copy it again to `C:\Program Files\QbittorrentProtonVPNUpdater` (overwriting the existing file)

## How It Works

1. **Port Detection**:

    - The script monitors ProtonVPN's log file (`client-logs.txt`)
    - Searches for entries containing "Port pair X->Y" patterns
    - Extracts the forwarded port number (X)

2. **qBittorrent Communication**:

    - Connects to qBittorrent's Web UI
    - Sends a POST request to update the listening port
    - Verifies the connection is successful

3. **Change Detection**:

    - Compares the newly detected port with the last used port
    - Only updates qBittorrent if the port has changed
    - Stores the last used port in an environment variable

4. **Notifications**:
    - Shows Windows toast notifications for:
        - Successful port updates
        - Errors (failed connections, missing logs)
    - Notifications appear in your system's language when supported

## Trigger Events

The scheduled task runs automatically in these scenarios:

1. When qBittorrent starts
2. When ProtonVPN connects or disconnects
3. When network profile changes occur

## Manual Execution

You can run the script manually if needed:

1. Open Command Prompt
2. Navigate to the script directory:
    ```cmd
    cd "C:\Program Files\QbittorrentProtonVPNUpdater"
    ```
3. Execute the script:
    ```cmd
    cscript update_port.vbs
    ```

## Troubleshooting

### Common Issues

1. **Script fails to connect to qBittorrent**:

    - Verify qBittorrent's Web UI is enabled
    - Check that the port in the script matches qBittorrent's Web UI port
    - Ensure qBittorrent isn't blocked by Windows Firewall

2. **No port found in ProtonVPN logs**:

    - Confirm you're using a ProtonVPN server that supports port forwarding
    - Check that port forwarding is enabled in your ProtonVPN account settings
    - Verify the log file path is correct for your system

3. **Notifications not appearing**:
    - Ensure your Windows version supports toast notifications
    - Check notification settings in Windows Action Center

### Logging

For debugging, you can uncomment the `Log` function calls in `update_port.vbs`:

1. Remove the comment (`'`) before each `Log GetText(...)` line
2. Run the script manually from Command Prompt to see the output

## Uninstallation

To completely remove the tool:

1. Delete the program files:

    ```cmd
    rmdir /s /q "C:\Program Files\QbittorrentProtonVPNUpdater"
    ```

2. Remove the scheduled task:
    - Open Task Scheduler
    - Find and delete "Qbitorrent-ProtonVPN port Updater"

## Security Considerations

-   The script requires administrator privileges for installation but runs with user privileges
-   If using qBittorrent's Web UI without authentication, ensure your network is secure
-   The script only communicates with localhost (127.0.0.1) by default

## Support

The script supports the following languages for notifications:

-   English (default)
-   Portuguese (Brazil)
-   Spanish
-   French
-   Russian
-   Arabic
-   Chinese (Simplified)

The language is automatically detected from your Windows system settings.

## License

This project is licensed under the GPL-3.0 License. This ensures that any modification or redistribution of the code remains open-source, keeping it free and available to the community.

---

For questions or issues, please open an issue on the GitHub repository.
