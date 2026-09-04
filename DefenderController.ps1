#Requires -Version 5.1
<#
    DefenderController - kişisel makinenizde Windows Defender ayarlarını
    açıp kapatmak için basit bir WPF arayüz.

    Tamper Protection açıkken bazı adımlar Windows tarafından geri alınır;
    bu normaldir ve bilinçli bir Microsoft güvenlik tasarımıdır. Log
    panelinde her adımın gerçekten uygulanıp uygulanmadığı gösterilir.
#>

# ---- Admin olarak yeniden başlat ----
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Defender Controller" Height="360" Width="420"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        FontFamily="Segoe UI" Background="#F4F4F4">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Vertical" HorizontalAlignment="Center" Margin="0,0,0,18">
            <TextBlock x:Name="StatusIcon" Text="" FontSize="34" HorizontalAlignment="Center"/>
            <TextBlock x:Name="StatusText" Text="Durum kontrol ediliyor..." Margin="0,6,0,0" FontSize="15" FontWeight="SemiBold" HorizontalAlignment="Center"/>
            <TextBlock x:Name="TamperText" Text="" Margin="0,4,0,0" FontSize="11" Foreground="#888888" HorizontalAlignment="Center" TextAlignment="Center" TextWrapping="Wrap"/>
        </StackPanel>

        <StackPanel Grid.Row="1" Orientation="Vertical" Margin="0,0,0,12">
            <Button x:Name="DisableBtn" Content="Defender'ı Kapat" Height="46" Margin="0,0,0,10" Background="#C0392B" Foreground="White" FontWeight="Bold" FontSize="14" BorderThickness="0"/>
            <Button x:Name="EnableBtn" Content="Defender'ı Aç" Height="46" Background="#27AE60" Foreground="White" FontWeight="Bold" FontSize="14" BorderThickness="0"/>
        </StackPanel>

        <Expander Grid.Row="3" Header="Detaylı log" FontSize="11" Foreground="#666666">
            <TextBox x:Name="LogBox" IsReadOnly="True" Height="120" VerticalScrollBarVisibility="Auto"
                     FontFamily="Consolas" FontSize="11" TextWrapping="Wrap" Background="#1E1E1E" Foreground="#DCDCDC" Margin="0,6,0,0"/>
        </Expander>
    </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$StatusIcon = $window.FindName("StatusIcon")
$StatusText = $window.FindName("StatusText")
$TamperText = $window.FindName("TamperText")
$DisableBtn = $window.FindName("DisableBtn")
$EnableBtn  = $window.FindName("EnableBtn")
$LogBox     = $window.FindName("LogBox")

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $LogBox.AppendText("[$ts] [$Level] $Message`r`n")
    $LogBox.ScrollToEnd()
}

function Get-TamperProtectionState {
    try {
        $val = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -ErrorAction Stop
        # 5 = açık, 4 veya 0 = kapalı (sürüme göre değişebilir, bu yüzden kesin değil)
        return ($val -eq 5)
    } catch {
        return $null # okunamadı, muhtemelen erişim kısıtlı
    }
}

function Update-Status {
    try {
        $mp = Get-MpComputerStatus -ErrorAction Stop
        if ($mp.RealTimeProtectionEnabled) {
            $StatusIcon.Text = "🛡️"
            $StatusText.Text = "Koruma AÇIK"
            $StatusText.Foreground = "DarkGreen"
        } else {
            $StatusIcon.Text = "⚠️"
            $StatusText.Text = "Koruma KAPALI"
            $StatusText.Foreground = "DarkRed"
        }
    } catch {
        $StatusIcon.Text = "❔"
        $StatusText.Text = "Durum okunamadı"
        $StatusText.Foreground = "Gray"
    }

    $tamper = Get-TamperProtectionState
    if ($tamper -eq $true) {
        $TamperText.Text = "Tamper Protection açık - bazı değişiklikler geri alınabilir"
    } elseif ($tamper -eq $false) {
        $TamperText.Text = ""
    } else {
        $TamperText.Text = "Tamper Protection durumu okunamadı"
    }
}

function Set-DefenderPreferenceSafe {
    param([string]$Description, [scriptblock]$Action)
    try {
        & $Action
        Write-Log "OK  - $Description"
    } catch {
        Write-Log "HATA - $Description : $($_.Exception.Message)" "WARN"
    }
}

function Show-TamperWarning {
    $tamper = Get-TamperProtectionState
    if ($tamper -ne $true) { return }

    $result = [System.Windows.MessageBox]::Show(
        "Kurcalamaya Karşı Koruma (Tamper Protection) AÇIK.`n`n" +
        "Bu açıkken Defender ayarları script ile kalıcı olarak değiştirilemez - Windows onları otomatik geri alır. " +
        "Bu, Microsoft'un bilinçli bir güvenlik tasarımıdır ve script ile kapatılamaz, sadece elle kapatılabilir.`n`n" +
        "Adımlar:`n" +
        "1. Windows Security > Virüs ve tehdit koruması > Ayarları yönet`n" +
        "2. 'Kurcalamaya Karşı Koruma' anahtarını kapatın`n`n" +
        "Şimdi bu ekranı açmamı ister misiniz?",
        "Tamper Protection Açık",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )

    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        Start-Process "windowsdefender://threatsettings"
        Write-Log "Windows Security ayar ekranı açıldı. Tamper Protection'ı kapattıktan sonra 'Defender'ı Kapat' butonuna tekrar basın." "WARN"
    } else {
        Write-Log "Tamper Protection açık kaldı - aşağıdaki adımlardan bazıları başarısız olacaktır." "WARN"
    }
}

function Disable-Defender {
    Write-Log "Defender kapatma işlemi başlıyor..."
    Show-TamperWarning

    Set-DefenderPreferenceSafe "Gerçek zamanlı koruma kapatılıyor" { Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop }
    Set-DefenderPreferenceSafe "Davranış izleme kapatılıyor" { Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction Stop }
    Set-DefenderPreferenceSafe "IOAV (indirilen dosya) koruması kapatılıyor" { Set-MpPreference -DisableIOAVProtection $true -ErrorAction Stop }
    Set-DefenderPreferenceSafe "Script taraması kapatılıyor" { Set-MpPreference -DisableScriptScanning $true -ErrorAction Stop }
    Set-DefenderPreferenceSafe "Bulut tabanlı koruma kapatılıyor" { Set-MpPreference -MAPSReporting 0 -ErrorAction Stop }
    Set-DefenderPreferenceSafe "Örnek gönderimi kapatılıyor" { Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction Stop }

    Set-DefenderPreferenceSafe "Zamanlanmış tarama görevi devre dışı bırakılıyor" {
        Get-ScheduledTask -TaskPath "\Microsoft\Windows\Windows Defender\" -ErrorAction Stop |
            Disable-ScheduledTask -ErrorAction Stop | Out-Null
    }

    Set-DefenderPreferenceSafe "Policy registry anahtarı (DisableAntiSpyware) ayarlanıyor" {
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        New-ItemProperty -Path $path -Name "DisableAntiSpyware" -PropertyType DWord -Value 1 -Force -ErrorAction Stop | Out-Null
    }

    # Security Center, WinDefend servisi çalıştığı sürece Defender'ı "aktif sağlayıcı"
    # olarak görmeye devam eder. Servis "Protected Process Light" olduğu için çalışırken
    # Stop-Service/Set-Service ile durdurulamaz (Erişim Engellendi) - bu Tamper Protection'dan
    # bağımsız, ayrı bir OS korumasıdır ve kasıtlı olarak aşılamaz. Bunun yerine registry'deki
    # başlangıç tipini doğrudan değiştirip bir sonraki açılışta başlamamasını sağlıyoruz.
    Set-DefenderPreferenceSafe "WinDefend başlangıç tipi devre dışı yapılıyor (etkisi yeniden başlatmada)" {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name "Start" -Value 4 -Type DWord -ErrorAction Stop
    }
    Set-DefenderPreferenceSafe "WdNisSvc başlangıç tipi devre dışı yapılıyor (etkisi yeniden başlatmada)" {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WdNisSvc" -Name "Start" -Value 4 -Type DWord -ErrorAction Stop
    }

    Write-Log "Kapatma işlemi tamamlandı. Yukarıdaki HATA satırları Tamper Protection'ın engellediği adımlardır."
    Write-Log "Servis değişikliği ancak yeniden başlatma sonrası etkili olur. Bilgisayarı yeniden başlatın, ardından Windows Security'nin 'kuruluşunuz tarafından yönetilir' haline geçtiğini kontrol edin." "WARN"
    Update-Status
}

function Enable-Defender {
    Write-Log "Defender açma işlemi başlıyor..."

    Set-DefenderPreferenceSafe "Gerçek zamanlı koruma açılıyor" { Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop }
    Set-DefenderPreferenceSafe "Davranış izleme açılıyor" { Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction Stop }
    Set-DefenderPreferenceSafe "IOAV (indirilen dosya) koruması açılıyor" { Set-MpPreference -DisableIOAVProtection $false -ErrorAction Stop }
    Set-DefenderPreferenceSafe "Script taraması açılıyor" { Set-MpPreference -DisableScriptScanning $false -ErrorAction Stop }
    Set-DefenderPreferenceSafe "Bulut tabanlı koruma açılıyor" { Set-MpPreference -MAPSReporting 2 -ErrorAction Stop }
    Set-DefenderPreferenceSafe "Örnek gönderimi varsayılana alınıyor" { Set-MpPreference -SubmitSamplesConsent 1 -ErrorAction Stop }

    Set-DefenderPreferenceSafe "Zamanlanmış tarama görevi yeniden etkinleştiriliyor" {
        Get-ScheduledTask -TaskPath "\Microsoft\Windows\Windows Defender\" -ErrorAction Stop |
            Enable-ScheduledTask -ErrorAction Stop | Out-Null
    }

    Set-DefenderPreferenceSafe "Policy registry anahtarı (DisableAntiSpyware) kaldırılıyor" {
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        if (Test-Path $path) {
            Remove-ItemProperty -Path $path -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
        }
    }

    Set-DefenderPreferenceSafe "WinDefend başlangıç tipi normale (Manual) alınıyor" {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name "Start" -Value 3 -Type DWord -ErrorAction Stop
    }
    Set-DefenderPreferenceSafe "WdNisSvc başlangıç tipi normale (Manual) alınıyor" {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WdNisSvc" -Name "Start" -Value 3 -Type DWord -ErrorAction Stop
    }
    Set-DefenderPreferenceSafe "WinDefend servisi başlatılıyor" { Start-Service -Name WinDefend -ErrorAction Stop }
    Set-DefenderPreferenceSafe "WdNisSvc servisi başlatılıyor" { Start-Service -Name WdNisSvc -ErrorAction Stop }

    Write-Log "Açma işlemi tamamlandı. Değişikliklerin tam yansıması için bilgisayarı yeniden başlatmanız gerekebilir."
    Update-Status
}

$DisableBtn.Add_Click({ Disable-Defender })
$EnableBtn.Add_Click({ Enable-Defender })

Update-Status
Write-Log "Araç başlatıldı. Tamper Protection açıksa bazı adımlar başarısız görünecektir - bu beklenen bir davranıştır."

$window.ShowDialog() | Out-Null
