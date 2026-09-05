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
        Title="Defender Controller" Width="440" SizeToContent="Height"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        FontFamily="Segoe UI" Background="#F4F4F4">
    <StackPanel>
        <Border x:Name="BannerBorder" Background="#C0392B" Padding="18,16,14,16">
            <Grid>
                <TextBlock x:Name="BannerText" Text="Durum kontrol ediliyor..." Foreground="White" FontSize="17" FontWeight="Bold"
                           VerticalAlignment="Center" Margin="0,0,70,0"/>
                <Button x:Name="MenuBtn" Content="Menü ▾" FontSize="12" Foreground="White"
                        Background="#33FFFFFF" BorderBrush="#66FFFFFF" BorderThickness="1"
                        Padding="10,5" HorizontalAlignment="Right" VerticalAlignment="Center" Cursor="Hand"/>
            </Grid>
        </Border>

        <Grid Margin="18,16,18,4">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="86"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <Grid Grid.Column="0" Width="76" Height="76" VerticalAlignment="Top">
                <Path x:Name="ShieldPath" Data="M12 1 L21 5 V11 C21 16.5 17.5 21.2 12 23 C6.5 21.2 3 16.5 3 11 V5 Z"
                      Fill="#C0392B" Stretch="Uniform" Width="70" Height="70"
                      HorizontalAlignment="Center" VerticalAlignment="Center">
                    <Path.Effect>
                        <DropShadowEffect Color="Black" BlurRadius="8" ShadowDepth="1" Opacity="0.25"/>
                    </Path.Effect>
                </Path>
                <TextBlock x:Name="ShieldGlyph" Text="✕" FontSize="26" FontWeight="Bold" Foreground="White"
                           HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,4,0,0"/>
            </Grid>

            <StackPanel Grid.Column="1" Margin="14,0,0,0">
                <Button x:Name="DisableBtn" Content="Windows Defender'ı Devre Dışı Bırak" Height="34" Margin="0,0,0,8"
                        Background="White" BorderBrush="#CCCCCC" BorderThickness="1"/>
                <Button x:Name="EnableBtn" Content="Windows Defender'ı Etkinleştir" Height="34" Margin="0,0,0,8"
                        Background="White" BorderBrush="#CCCCCC" BorderThickness="1"/>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="OpenSecurityBtn" Grid.Column="0" Content="Güvenlik Merkezini Aç" Height="30" FontSize="11" Margin="0,0,4,0"/>
                    <Button x:Name="LogToggleBtn" Grid.Column="1" Content="Log Göster" Height="30" FontSize="11" Margin="4,0,0,0"/>
                </Grid>
            </StackPanel>
        </Grid>

        <TextBlock x:Name="TamperText" Text="" FontSize="11" Foreground="#B36B00" Margin="18,0,18,12" TextWrapping="Wrap"/>

        <Border x:Name="LogPanel" Visibility="Collapsed" Margin="18,0,18,16">
            <TextBox x:Name="LogBox" IsReadOnly="True" Height="140" VerticalScrollBarVisibility="Auto"
                     FontFamily="Consolas" FontSize="11" TextWrapping="Wrap" Background="#1E1E1E" Foreground="#DCDCDC"/>
        </Border>
    </StackPanel>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$BannerBorder    = $window.FindName("BannerBorder")
$BannerText      = $window.FindName("BannerText")
$MenuBtn         = $window.FindName("MenuBtn")
$ShieldPath      = $window.FindName("ShieldPath")
$ShieldGlyph     = $window.FindName("ShieldGlyph")
$TamperText      = $window.FindName("TamperText")
$DisableBtn      = $window.FindName("DisableBtn")
$EnableBtn       = $window.FindName("EnableBtn")
$OpenSecurityBtn = $window.FindName("OpenSecurityBtn")
$LogToggleBtn    = $window.FindName("LogToggleBtn")
$LogPanel        = $window.FindName("LogPanel")
$LogBox          = $window.FindName("LogBox")

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
    $resolved = $false
    try {
        $mp = Get-MpComputerStatus -ErrorAction Stop
        if ($mp.RealTimeProtectionEnabled) {
            $BannerBorder.Background = "#27AE60"
            $BannerText.Text = "Windows Defender Açık"
            $ShieldPath.Fill = "#27AE60"
            $ShieldGlyph.Text = "✓"
        } else {
            $BannerBorder.Background = "#C0392B"
            $BannerText.Text = "Windows Defender Kapalı"
            $ShieldPath.Fill = "#C0392B"
            $ShieldGlyph.Text = "✕"
        }
        $resolved = $true
    } catch {
        # WMI sağlayıcısı (MsMpEng) cevap vermiyor olabilir - WinDefend servisi
        # devre dışıysa bu normaldir, servis durumuna bakarak yine de anlamlı bir
        # durum gösterebiliriz.
        try {
            $svc = Get-Service -Name WinDefend -ErrorAction Stop
            if ($svc.Status -ne 'Running') {
                $BannerBorder.Background = "#C0392B"
                $BannerText.Text = "Windows Defender Kapalı"
                $ShieldPath.Fill = "#C0392B"
                $ShieldGlyph.Text = "✕"
                $resolved = $true
            }
        } catch { }
    }

    if (-not $resolved) {
        $BannerBorder.Background = "#7F8C8D"
        $BannerText.Text = "Durum okunamadı"
        $ShieldPath.Fill = "#7F8C8D"
        $ShieldGlyph.Text = "?"
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

    for ($i = 0; $i -lt 3; $i++) {
        Start-Sleep -Milliseconds 800
        Update-Status
    }
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

    # WinDefend yeni başladığında MsMpEng motoru birkaç saniye içinde ayağa kalkıyor;
    # hemen sorgulanırsa eski/boş durum dönebiliyor. Kısa aralıklarla birkaç kez
    # tekrar sorgulayıp arayüzü güncel tutuyoruz.
    for ($i = 0; $i -lt 5; $i++) {
        Start-Sleep -Milliseconds 800
        Update-Status
    }
}

$DisableBtn.Add_Click({ Disable-Defender })
$EnableBtn.Add_Click({ Enable-Defender })
$OpenSecurityBtn.Add_Click({ Start-Process "windowsdefender://" })
$LogToggleBtn.Add_Click({
    if ($LogPanel.Visibility -eq [System.Windows.Visibility]::Visible) {
        $LogPanel.Visibility = [System.Windows.Visibility]::Collapsed
        $LogToggleBtn.Content = "Log Göster"
    } else {
        $LogPanel.Visibility = [System.Windows.Visibility]::Visible
        $LogToggleBtn.Content = "Log Gizle"
    }
})

# ---- Üst şeritteki "⋮" menüsü ----
$AppMenu = New-Object System.Windows.Controls.ContextMenu
$AppMenu.PlacementTarget = $MenuBtn
$AppMenu.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom

function New-AppMenuItem {
    param([string]$Header, [scriptblock]$OnClick)
    $item = New-Object System.Windows.Controls.MenuItem
    $item.Header = $Header
    $item.Add_Click($OnClick)
    return $item
}

$AppMenu.Items.Add((New-AppMenuItem "Defender Ayarlarını Aç" { Start-Process "windowsdefender://threatsettings" })) | Out-Null
$AppMenu.Items.Add((New-AppMenuItem "Durumu Yenile" { Update-Status; Write-Log "Durum manuel olarak yenilendi." })) | Out-Null
$AppMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null
$AppMenu.Items.Add((New-AppMenuItem "GitHub Reposunu Aç" { Start-Process "https://github.com/atlllas/windows-defender-controller" })) | Out-Null
$AppMenu.Items.Add((New-AppMenuItem "Hakkında" {
    [System.Windows.MessageBox]::Show(
        "Defender Controller`n`nKişisel kullanım için Windows Defender aç/kapa aracı.",
        "Hakkında", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
})) | Out-Null

$MenuBtn.Add_Click({ $AppMenu.IsOpen = $true })

Update-Status
Write-Log "Araç başlatıldı. Tamper Protection açıksa bazı adımlar başarısız görünecektir - bu beklenen bir davranıştır."

$window.ShowDialog() | Out-Null
