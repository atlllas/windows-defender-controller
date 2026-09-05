# Defender Controller

A small WPF GUI to turn Windows Defender on or off with administrator rights, built as a personal utility (inspired by [Defender Control](https://www.sordum.org/9480/defender-control-v2-1/)).

![status](https://img.shields.io/badge/platform-Windows%2010%2F11-blue)

## Features

- One-click disable/enable of Windows Defender (real-time protection, cloud protection, script scanning, scheduled scans, and the underlying service)
- Detects Tamper Protection and walks you through turning it off manually (it can't be scripted — that's by design on Microsoft's part)
- 6 languages: English, Türkçe, Deutsch, Español, Français, Русский (remembers your choice)
- Runs as a plain `.exe` — no console window, admin elevation prompt handled automatically

## Usage

1. Download `DefenderController.ps1` (or build the `.exe` yourself — see below).
2. Run it. It will ask for administrator rights.
3. Click **Disable/Enable Windows Defender**. If Tamper Protection is on, follow the prompt to turn it off in Windows Security first — this is a Windows limitation, not a bug.
4. Some changes (the underlying service start type) only take full effect after a reboot.

## Building the .exe

```powershell
Install-Module ps2exe -Scope CurrentUser
Invoke-ps2exe -inputFile DefenderController.ps1 -outputFile DefenderController.exe -noConsole -requireAdmin -iconFile app.ico
```

## Notes

- This is a personal-use tool for managing your **own** machine's antivirus settings. It doesn't hide anything from you — Windows Security will always show the real protection status.
- Tested on Windows 10/11. Requires PowerShell 5.1+ (built in).
