# Defender Controller

A small WPF GUI to turn Windows Defender on or off with administrator rights, built as a personal utility (inspired by [Defender Control](https://www.sordum.org/9480/defender-control-v2-1/)).

![platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue?style=for-the-badge)
![license](https://img.shields.io/github/license/atlllas/windows-defender-controller?style=for-the-badge)
![release](https://img.shields.io/github/v/release/atlllas/windows-defender-controller?style=for-the-badge&color=2E86DE)
![downloads](https://img.shields.io/github/downloads/atlllas/windows-defender-controller/total?style=for-the-badge&color=27AE60)

### [![Download](https://img.shields.io/badge/⬇️_DOWNLOAD-DefenderController.exe-2E86DE?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/atlllas/windows-defender-controller/releases/latest/download/DefenderController.exe)

## Features

- One-click disable/enable of Windows Defender (real-time protection, cloud protection, script scanning, scheduled scans, and the underlying service)
- Detects Tamper Protection and walks you through turning it off manually (it can't be scripted — that's by design on Microsoft's part)
- 6 languages: English, Türkçe, Deutsch, Español, Français, Русский (remembers your choice)
- Runs as a plain `.exe` — no console window, admin elevation prompt handled automatically

## Usage

1. [Download the .exe](https://github.com/atlllas/windows-defender-controller/releases/latest/download/DefenderController.exe) (or grab `DefenderController.ps1` and build it yourself — see below).
2. Run it. It will ask for administrator rights.
3. Click **Disable/Enable Windows Defender**. If Tamper Protection is on, follow the prompt to turn it off in Windows Security first — this is a Windows limitation, not a bug.
4. Some changes (the underlying service start type) only take full effect after a reboot.

## Building the .exe

```powershell
Install-Module ps2exe -Scope CurrentUser
Invoke-ps2exe -inputFile DefenderController.ps1 -outputFile DefenderController.exe -noConsole -requireAdmin -iconFile app.ico
```

## About the security warnings

Windows SmartScreen or your antivirus may flag this file the first time you run it — that's expected, not a sign of anything malicious:

- The `.exe` is **self-signed**, not signed by a paid, trusted certificate authority, so Windows can't verify a known publisher. A real CA-issued certificate costs money and isn't worth it for a free personal tool.
- A tool that toggles Windows Defender's protection looks similar to techniques malware uses, so some antivirus engines flag it heuristically even though the behavior here is fully user-initiated and visible (nothing is hidden from Windows Security).

If SmartScreen blocks it: click **More info → Run anyway**. If you want to verify the file yourself instead of trusting the above:

- The source is entirely in [`DefenderController.ps1`](DefenderController.ps1) — read it, or build the `.exe` yourself (see below) instead of using the prebuilt one.
- You can check the SHA-256 hash of the exact release binary against what GitHub records for that release asset:
  ```powershell
  Get-FileHash DefenderController.exe -Algorithm SHA256
  ```

## Notes

- This is a personal-use tool for managing your **own** machine's antivirus settings. It doesn't hide anything from you — Windows Security will always show the real protection status.
- Tested on Windows 10/11. Requires PowerShell 5.1+ (built in).
