#Requires -Version 5.1
<#
    DefenderController - kisisel makinenizde Windows Defender ayarlarini
    acip kapatmak icin basit bir WPF arayuz. Coklu dil destegi vardir.

    Tamper Protection acikken bazi adimlar Windows tarafindan geri alinir;
    bu normaldir ve bilincli bir Microsoft guvenlik tasarimidir. Log
    panelinde her adimin gercekten uygulanip uygulanmadigi gosterilir.
#>

# ---- Admin olarak yeniden baslat ----
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ---- Diller ----
function Get-Strings {
    @{
        en = @{
            Banner_Checking = "Checking status..."
            Banner_On = "Windows Defender is On"
            Banner_Off = "Windows Defender is Off"
            Banner_Unknown = "Status unknown"
            Tamper_On = "Tamper Protection is on - some changes may be reverted"
            Tamper_Unknown = "Could not read Tamper Protection status"
            Btn_Disable = "Disable Windows Defender"
            Btn_Enable = "Enable Windows Defender"
            Btn_OpenSecurity = "Open Security Center"
            Btn_LogShow = "Show Log"
            Btn_LogHide = "Hide Log"
            Btn_Menu = "Menu"
            Menu_DefenderSettings = "Open Defender Settings"
            Menu_Refresh = "Refresh Status"
            Menu_Github = "Open GitHub Repo"
            Menu_Language = "Language"
            Menu_About = "About"
            Log_AppStarted = "Tool started. If Tamper Protection is on, some steps will appear to fail - this is expected."
            Log_DisableStart = "Starting to disable Defender..."
            Log_EnableStart = "Starting to enable Defender..."
            Log_RefreshManual = "Status refreshed manually."
            Log_OK = "OK"
            Log_FAILED = "FAILED"
            Log_DisableDone = "Disable finished. The FAILED lines above are blocked by Tamper Protection."
            Log_DisableRebootNote = "Service changes only take effect after a reboot. Restart the computer, then check that Windows Security shows it is managed by your organization."
            Log_EnableDone = "Enable finished. A reboot may be needed for changes to fully apply."
            Step_RealtimeOff = "Turning off real-time protection"
            Step_BehaviorOff = "Turning off behavior monitoring"
            Step_IOAVOff = "Turning off downloaded file protection (IOAV)"
            Step_ScriptOff = "Turning off script scanning"
            Step_CloudOff = "Turning off cloud-delivered protection"
            Step_SamplesOff = "Turning off sample submission"
            Step_TaskOff = "Disabling the scheduled scan task"
            Step_PolicySet = "Setting the policy registry key (DisableAntiSpyware)"
            Step_WinDefendDisable = "Disabling WinDefend start type (takes effect after reboot)"
            Step_WdNisDisable = "Disabling WdNisSvc start type (takes effect after reboot)"
            Step_RealtimeOn = "Turning on real-time protection"
            Step_BehaviorOn = "Turning on behavior monitoring"
            Step_IOAVOn = "Turning on downloaded file protection (IOAV)"
            Step_ScriptOn = "Turning on script scanning"
            Step_CloudOn = "Turning on cloud-delivered protection"
            Step_SamplesOn = "Resetting sample submission to default"
            Step_TaskOn = "Re-enabling the scheduled scan task"
            Step_PolicyRemoved = "Removing the policy registry key (DisableAntiSpyware)"
            Step_WinDefendManual = "Setting WinDefend start type back to Manual"
            Step_WdNisManual = "Setting WdNisSvc start type back to Manual"
            Step_WinDefendStart = "Starting the WinDefend service"
            Step_WdNisStart = "Starting the WdNisSvc service"
            Tamper_Title = "Tamper Protection Is On"
            Tamper_Body = "Tamper Protection is ON.`n`nWhile it's on, Defender settings can't be permanently changed by a script - Windows reverts them automatically. This is a deliberate Microsoft security design and can't be turned off by a script, only by hand.`n`nSteps:`n1. Windows Security > Virus & threat protection > Manage settings`n2. Turn off 'Tamper Protection'`n`nWould you like me to open that screen now?"
            Tamper_Opened = "Opened the Windows Security settings screen. After turning off Tamper Protection, click Disable again."
            Tamper_StayedOn = "Tamper Protection stayed on - some of the steps below will fail."
            About_Title = "About"
            About_Subtitle = "A personal tool to turn Windows Defender on or off with administrator rights."
            About_Tagline = "Personal project - built together"
            About_Github = "GitHub Repo"
            About_Issue = "Report an Issue"
            About_Author = "Author"
            About_Website = "Website"
            About_OK = "OK"
        }
        tr = @{
            Banner_Checking = "Durum kontrol ediliyor..."
            Banner_On = "Windows Defender Açık"
            Banner_Off = "Windows Defender Kapalı"
            Banner_Unknown = "Durum okunamadı"
            Tamper_On = "Tamper Protection açık - bazı değişiklikler geri alınabilir"
            Tamper_Unknown = "Tamper Protection durumu okunamadı"
            Btn_Disable = "Windows Defender'ı Devre Dışı Bırak"
            Btn_Enable = "Windows Defender'ı Etkinleştir"
            Btn_OpenSecurity = "Güvenlik Merkezini Aç"
            Btn_LogShow = "Log Göster"
            Btn_LogHide = "Log Gizle"
            Btn_Menu = "Menü"
            Menu_DefenderSettings = "Defender Ayarlarını Aç"
            Menu_Refresh = "Durumu Yenile"
            Menu_Github = "GitHub Reposunu Aç"
            Menu_Language = "Dil"
            Menu_About = "Hakkında"
            Log_AppStarted = "Araç başlatıldı. Tamper Protection açıksa bazı adımlar başarısız görünecektir - bu beklenen bir davranıştır."
            Log_DisableStart = "Defender kapatma işlemi başlıyor..."
            Log_EnableStart = "Defender açma işlemi başlıyor..."
            Log_RefreshManual = "Durum manuel olarak yenilendi."
            Log_OK = "OK"
            Log_FAILED = "HATA"
            Log_DisableDone = "Kapatma işlemi tamamlandı. Yukarıdaki HATA satırları Tamper Protection'ın engellediği adımlardır."
            Log_DisableRebootNote = "Servis değişikliği ancak yeniden başlatma sonrası etkili olur. Bilgisayarı yeniden başlatın, ardından Windows Security'nin 'kuruluşunuz tarafından yönetilir' haline geçtiğini kontrol edin."
            Log_EnableDone = "Açma işlemi tamamlandı. Değişikliklerin tam yansıması için bilgisayarı yeniden başlatmanız gerekebilir."
            Step_RealtimeOff = "Gerçek zamanlı koruma kapatılıyor"
            Step_BehaviorOff = "Davranış izleme kapatılıyor"
            Step_IOAVOff = "IOAV (indirilen dosya) koruması kapatılıyor"
            Step_ScriptOff = "Script taraması kapatılıyor"
            Step_CloudOff = "Bulut tabanlı koruma kapatılıyor"
            Step_SamplesOff = "Örnek gönderimi kapatılıyor"
            Step_TaskOff = "Zamanlanmış tarama görevi devre dışı bırakılıyor"
            Step_PolicySet = "Policy registry anahtarı (DisableAntiSpyware) ayarlanıyor"
            Step_WinDefendDisable = "WinDefend başlangıç tipi devre dışı yapılıyor (etkisi yeniden başlatmada)"
            Step_WdNisDisable = "WdNisSvc başlangıç tipi devre dışı yapılıyor (etkisi yeniden başlatmada)"
            Step_RealtimeOn = "Gerçek zamanlı koruma açılıyor"
            Step_BehaviorOn = "Davranış izleme açılıyor"
            Step_IOAVOn = "IOAV (indirilen dosya) koruması açılıyor"
            Step_ScriptOn = "Script taraması açılıyor"
            Step_CloudOn = "Bulut tabanlı koruma açılıyor"
            Step_SamplesOn = "Örnek gönderimi varsayılana alınıyor"
            Step_TaskOn = "Zamanlanmış tarama görevi yeniden etkinleştiriliyor"
            Step_PolicyRemoved = "Policy registry anahtarı (DisableAntiSpyware) kaldırılıyor"
            Step_WinDefendManual = "WinDefend başlangıç tipi normale (Manual) alınıyor"
            Step_WdNisManual = "WdNisSvc başlangıç tipi normale (Manual) alınıyor"
            Step_WinDefendStart = "WinDefend servisi başlatılıyor"
            Step_WdNisStart = "WdNisSvc servisi başlatılıyor"
            Tamper_Title = "Tamper Protection Açık"
            Tamper_Body = "Kurcalamaya Karşı Koruma (Tamper Protection) AÇIK.`n`nBu açıkken Defender ayarları script ile kalıcı olarak değiştirilemez - Windows onları otomatik geri alır. Bu, Microsoft'un bilinçli bir güvenlik tasarımıdır ve script ile kapatılamaz, sadece elle kapatılabilir.`n`nAdımlar:`n1. Windows Security > Virüs ve tehdit koruması > Ayarları yönet`n2. 'Kurcalamaya Karşı Koruma' anahtarını kapatın`n`nŞimdi bu ekranı açmamı ister misiniz?"
            Tamper_Opened = "Windows Security ayar ekranı açıldı. Tamper Protection'ı kapattıktan sonra 'Devre Dışı Bırak' butonuna tekrar basın."
            Tamper_StayedOn = "Tamper Protection açık kaldı - aşağıdaki adımlardan bazıları başarısız olacaktır."
            About_Title = "Hakkında"
            About_Subtitle = "Yönetici haklarıyla Windows Defender'ı açıp kapatmak için kişisel bir araç."
            About_Tagline = "Kişisel proje - birlikte geliştirildi"
            About_Github = "GitHub Reposu"
            About_Issue = "Sorun Bildir"
            About_Author = "Yazar"
            About_Website = "Web Sitesi"
            About_OK = "Tamam"
        }
        de = @{
            Banner_Checking = "Status wird gepruft..."
            Banner_On = "Windows Defender ist aktiv"
            Banner_Off = "Windows Defender ist deaktiviert"
            Banner_Unknown = "Status unbekannt"
            Tamper_On = "Manipulationsschutz ist aktiv - manche Anderungen konnen zuruckgesetzt werden"
            Tamper_Unknown = "Status des Manipulationsschutzes konnte nicht gelesen werden"
            Btn_Disable = "Windows Defender deaktivieren"
            Btn_Enable = "Windows Defender aktivieren"
            Btn_OpenSecurity = "Sicherheitscenter offnen"
            Btn_LogShow = "Protokoll anzeigen"
            Btn_LogHide = "Protokoll ausblenden"
            Btn_Menu = "Menu"
            Menu_DefenderSettings = "Defender-Einstellungen offnen"
            Menu_Refresh = "Status aktualisieren"
            Menu_Github = "GitHub-Repo offnen"
            Menu_Language = "Sprache"
            Menu_About = "Uber"
            Log_AppStarted = "Tool gestartet. Wenn der Manipulationsschutz aktiv ist, schlagen manche Schritte scheinbar fehl - das ist normal."
            Log_DisableStart = "Defender wird deaktiviert..."
            Log_EnableStart = "Defender wird aktiviert..."
            Log_RefreshManual = "Status manuell aktualisiert."
            Log_OK = "OK"
            Log_FAILED = "FEHLER"
            Log_DisableDone = "Deaktivierung abgeschlossen. Die FEHLER-Zeilen oben werden vom Manipulationsschutz blockiert."
            Log_DisableRebootNote = "Dienstanderungen wirken erst nach einem Neustart. Starten Sie den Computer neu und prufen Sie, ob Windows Security anzeigt, dass es von Ihrer Organisation verwaltet wird."
            Log_EnableDone = "Aktivierung abgeschlossen. Fur die vollstandige Wirkung ist eventuell ein Neustart notig."
            Step_RealtimeOff = "Echtzeitschutz wird deaktiviert"
            Step_BehaviorOff = "Verhaltensuberwachung wird deaktiviert"
            Step_IOAVOff = "Schutz fur heruntergeladene Dateien (IOAV) wird deaktiviert"
            Step_ScriptOff = "Skriptuberprufung wird deaktiviert"
            Step_CloudOff = "Cloudbasierter Schutz wird deaktiviert"
            Step_SamplesOff = "Ubermittlung von Beispielen wird deaktiviert"
            Step_TaskOff = "Geplante Uberprufung wird deaktiviert"
            Step_PolicySet = "Richtlinien-Registrierungsschlussel (DisableAntiSpyware) wird gesetzt"
            Step_WinDefendDisable = "WinDefend-Starttyp wird deaktiviert (wirkt nach Neustart)"
            Step_WdNisDisable = "WdNisSvc-Starttyp wird deaktiviert (wirkt nach Neustart)"
            Step_RealtimeOn = "Echtzeitschutz wird aktiviert"
            Step_BehaviorOn = "Verhaltensuberwachung wird aktiviert"
            Step_IOAVOn = "Schutz fur heruntergeladene Dateien (IOAV) wird aktiviert"
            Step_ScriptOn = "Skriptuberprufung wird aktiviert"
            Step_CloudOn = "Cloudbasierter Schutz wird aktiviert"
            Step_SamplesOn = "Ubermittlung von Beispielen wird zuruckgesetzt"
            Step_TaskOn = "Geplante Uberprufung wird wieder aktiviert"
            Step_PolicyRemoved = "Richtlinien-Registrierungsschlussel (DisableAntiSpyware) wird entfernt"
            Step_WinDefendManual = "WinDefend-Starttyp wird auf Manuell zuruckgesetzt"
            Step_WdNisManual = "WdNisSvc-Starttyp wird auf Manuell zuruckgesetzt"
            Step_WinDefendStart = "WinDefend-Dienst wird gestartet"
            Step_WdNisStart = "WdNisSvc-Dienst wird gestartet"
            Tamper_Title = "Manipulationsschutz ist aktiv"
            Tamper_Body = "Der Manipulationsschutz (Tamper Protection) ist AKTIV.`n`nSolange das der Fall ist, konnen Defender-Einstellungen nicht dauerhaft per Skript geandert werden - Windows setzt sie automatisch zuruck. Dies ist ein bewusstes Sicherheitsdesign von Microsoft und kann nicht per Skript, sondern nur manuell deaktiviert werden.`n`nSchritte:`n1. Windows-Sicherheit > Viren- und Bedrohungsschutz > Einstellungen verwalten`n2. Schalten Sie 'Manipulationsschutz' aus`n`nSoll ich diesen Bildschirm jetzt offnen?"
            Tamper_Opened = "Die Windows-Sicherheitseinstellungen wurden geoffnet. Schalten Sie den Manipulationsschutz aus und klicken Sie dann erneut auf Deaktivieren."
            Tamper_StayedOn = "Der Manipulationsschutz blieb aktiv - einige der folgenden Schritte werden fehlschlagen."
            About_Title = "Uber"
            About_Subtitle = "Ein persoenliches Tool, um Windows Defender mit Administratorrechten ein- oder auszuschalten."
            About_Tagline = "Persoenliches Projekt - gemeinsam entwickelt"
            About_Github = "GitHub-Repo"
            About_Issue = "Problem melden"
            About_Author = "Autor"
            About_Website = "Webseite"
            About_OK = "OK"
        }
        es = @{
            Banner_Checking = "Comprobando el estado..."
            Banner_On = "Windows Defender esta activado"
            Banner_Off = "Windows Defender esta desactivado"
            Banner_Unknown = "Estado desconocido"
            Tamper_On = "La proteccion contra alteraciones esta activada - algunos cambios pueden revertirse"
            Tamper_Unknown = "No se pudo leer el estado de la proteccion contra alteraciones"
            Btn_Disable = "Desactivar Windows Defender"
            Btn_Enable = "Activar Windows Defender"
            Btn_OpenSecurity = "Abrir el Centro de seguridad"
            Btn_LogShow = "Mostrar registro"
            Btn_LogHide = "Ocultar registro"
            Btn_Menu = "Menu"
            Menu_DefenderSettings = "Abrir la configuracion de Defender"
            Menu_Refresh = "Actualizar estado"
            Menu_Github = "Abrir el repositorio de GitHub"
            Menu_Language = "Idioma"
            Menu_About = "Acerca de"
            Log_AppStarted = "Herramienta iniciada. Si la proteccion contra alteraciones esta activada, algunos pasos pareceran fallar - esto es normal."
            Log_DisableStart = "Iniciando la desactivacion de Defender..."
            Log_EnableStart = "Iniciando la activacion de Defender..."
            Log_RefreshManual = "Estado actualizado manualmente."
            Log_OK = "OK"
            Log_FAILED = "ERROR"
            Log_DisableDone = "Desactivacion completada. Las lineas de ERROR anteriores estan bloqueadas por la proteccion contra alteraciones."
            Log_DisableRebootNote = "Los cambios de servicio solo surten efecto tras reiniciar. Reinicie el equipo y compruebe que Windows Security indique que esta administrado por su organizacion."
            Log_EnableDone = "Activacion completada. Puede que sea necesario reiniciar para que los cambios surtan efecto por completo."
            Step_RealtimeOff = "Desactivando la proteccion en tiempo real"
            Step_BehaviorOff = "Desactivando la supervision del comportamiento"
            Step_IOAVOff = "Desactivando la proteccion de archivos descargados (IOAV)"
            Step_ScriptOff = "Desactivando el analisis de scripts"
            Step_CloudOff = "Desactivando la proteccion basada en la nube"
            Step_SamplesOff = "Desactivando el envio de muestras"
            Step_TaskOff = "Deshabilitando la tarea de analisis programado"
            Step_PolicySet = "Estableciendo la clave de directiva del registro (DisableAntiSpyware)"
            Step_WinDefendDisable = "Deshabilitando el tipo de inicio de WinDefend (efectivo tras reiniciar)"
            Step_WdNisDisable = "Deshabilitando el tipo de inicio de WdNisSvc (efectivo tras reiniciar)"
            Step_RealtimeOn = "Activando la proteccion en tiempo real"
            Step_BehaviorOn = "Activando la supervision del comportamiento"
            Step_IOAVOn = "Activando la proteccion de archivos descargados (IOAV)"
            Step_ScriptOn = "Activando el analisis de scripts"
            Step_CloudOn = "Activando la proteccion basada en la nube"
            Step_SamplesOn = "Restableciendo el envio de muestras al valor predeterminado"
            Step_TaskOn = "Rehabilitando la tarea de analisis programado"
            Step_PolicyRemoved = "Eliminando la clave de directiva del registro (DisableAntiSpyware)"
            Step_WinDefendManual = "Volviendo a establecer el tipo de inicio de WinDefend en Manual"
            Step_WdNisManual = "Volviendo a establecer el tipo de inicio de WdNisSvc en Manual"
            Step_WinDefendStart = "Iniciando el servicio WinDefend"
            Step_WdNisStart = "Iniciando el servicio WdNisSvc"
            Tamper_Title = "La proteccion contra alteraciones esta activada"
            Tamper_Body = "La proteccion contra alteraciones (Tamper Protection) esta ACTIVADA.`n`nMientras este activada, los ajustes de Defender no se pueden cambiar de forma permanente mediante un script - Windows los revierte automaticamente. Este es un diseno de seguridad deliberado de Microsoft y no se puede desactivar mediante un script, solo manualmente.`n`nPasos:`n1. Seguridad de Windows > Proteccion contra virus y amenazas > Administrar configuracion`n2. Desactive 'Proteccion contra alteraciones'`n`nQuiere que abra esa pantalla ahora?"
            Tamper_Opened = "Se abrio la pantalla de configuracion de Seguridad de Windows. Despues de desactivar la proteccion contra alteraciones, haga clic en Desactivar de nuevo."
            Tamper_StayedOn = "La proteccion contra alteraciones sigue activada - algunos de los siguientes pasos fallaran."
            About_Title = "Acerca de"
            About_Subtitle = "Una herramienta personal para activar o desactivar Windows Defender con permisos de administrador."
            About_Tagline = "Proyecto personal - creado en conjunto"
            About_Github = "Repositorio de GitHub"
            About_Issue = "Reportar un problema"
            About_Author = "Autor"
            About_Website = "Sitio web"
            About_OK = "Aceptar"
        }
        fr = @{
            Banner_Checking = "Verification de l'etat..."
            Banner_On = "Windows Defender est active"
            Banner_Off = "Windows Defender est desactive"
            Banner_Unknown = "Etat inconnu"
            Tamper_On = "La protection contre les modifications est activee - certains changements peuvent etre annules"
            Tamper_Unknown = "Impossible de lire l'etat de la protection contre les modifications"
            Btn_Disable = "Desactiver Windows Defender"
            Btn_Enable = "Activer Windows Defender"
            Btn_OpenSecurity = "Ouvrir le Centre de securite"
            Btn_LogShow = "Afficher le journal"
            Btn_LogHide = "Masquer le journal"
            Btn_Menu = "Menu"
            Menu_DefenderSettings = "Ouvrir les parametres de Defender"
            Menu_Refresh = "Actualiser l'etat"
            Menu_Github = "Ouvrir le depot GitHub"
            Menu_Language = "Langue"
            Menu_About = "A propos"
            Log_AppStarted = "Outil demarre. Si la protection contre les modifications est activee, certaines etapes sembleront echouer - c'est normal."
            Log_DisableStart = "Desactivation de Defender en cours..."
            Log_EnableStart = "Activation de Defender en cours..."
            Log_RefreshManual = "Etat actualise manuellement."
            Log_OK = "OK"
            Log_FAILED = "ECHEC"
            Log_DisableDone = "Desactivation terminee. Les lignes ECHEC ci-dessus sont bloquees par la protection contre les modifications."
            Log_DisableRebootNote = "Les changements de service ne prennent effet qu'apres un redemarrage. Redemarrez l'ordinateur, puis verifiez que Windows Security indique qu'il est gere par votre organisation."
            Log_EnableDone = "Activation terminee. Un redemarrage peut etre necessaire pour que les changements s'appliquent completement."
            Step_RealtimeOff = "Desactivation de la protection en temps reel"
            Step_BehaviorOff = "Desactivation de la surveillance du comportement"
            Step_IOAVOff = "Desactivation de la protection des fichiers telecharges (IOAV)"
            Step_ScriptOff = "Desactivation de l'analyse des scripts"
            Step_CloudOff = "Desactivation de la protection fournie par le cloud"
            Step_SamplesOff = "Desactivation de l'envoi d'echantillons"
            Step_TaskOff = "Desactivation de la tache d'analyse planifiee"
            Step_PolicySet = "Definition de la cle de registre de strategie (DisableAntiSpyware)"
            Step_WinDefendDisable = "Desactivation du type de demarrage de WinDefend (effectif apres redemarrage)"
            Step_WdNisDisable = "Desactivation du type de demarrage de WdNisSvc (effectif apres redemarrage)"
            Step_RealtimeOn = "Activation de la protection en temps reel"
            Step_BehaviorOn = "Activation de la surveillance du comportement"
            Step_IOAVOn = "Activation de la protection des fichiers telecharges (IOAV)"
            Step_ScriptOn = "Activation de l'analyse des scripts"
            Step_CloudOn = "Activation de la protection fournie par le cloud"
            Step_SamplesOn = "Reinitialisation de l'envoi d'echantillons par defaut"
            Step_TaskOn = "Reactivation de la tache d'analyse planifiee"
            Step_PolicyRemoved = "Suppression de la cle de registre de strategie (DisableAntiSpyware)"
            Step_WinDefendManual = "Remise du type de demarrage de WinDefend sur Manuel"
            Step_WdNisManual = "Remise du type de demarrage de WdNisSvc sur Manuel"
            Step_WinDefendStart = "Demarrage du service WinDefend"
            Step_WdNisStart = "Demarrage du service WdNisSvc"
            Tamper_Title = "La protection contre les modifications est activee"
            Tamper_Body = "La protection contre les modifications (Tamper Protection) est ACTIVEE.`n`nTant qu'elle est activee, les parametres de Defender ne peuvent pas etre modifies durablement par un script - Windows les retablit automatiquement. Il s'agit d'une conception de securite deliberee de Microsoft, qui ne peut etre desactivee que manuellement, pas par un script.`n`nEtapes :`n1. Securite Windows > Protection contre les virus et menaces > Gerer les parametres`n2. Desactivez la Protection contre les modifications`n`nVoulez-vous que j'ouvre cet ecran maintenant ?"
            Tamper_Opened = "L'ecran des parametres de securite Windows a ete ouvert. Apres avoir desactive la protection contre les modifications, cliquez de nouveau sur Desactiver."
            Tamper_StayedOn = "La protection contre les modifications est restee activee - certaines des etapes suivantes echoueront."
            About_Title = "A propos"
            About_Subtitle = "Un outil personnel pour activer ou desactiver Windows Defender avec des droits d'administrateur."
            About_Tagline = "Projet personnel - cree ensemble"
            About_Github = "Depot GitHub"
            About_Issue = "Signaler un probleme"
            About_Author = "Auteur"
            About_Website = "Site web"
            About_OK = "OK"
        }
        ru = @{
            Banner_Checking = "Проверка состояния..."
            Banner_On = "Windows Defender включён"
            Banner_Off = "Windows Defender отключён"
            Banner_Unknown = "Состояние неизвестно"
            Tamper_On = "Защита от изменений включена - некоторые изменения могут откатиться"
            Tamper_Unknown = "Не удалось получить состояние защиты от изменений"
            Btn_Disable = "Отключить Windows Defender"
            Btn_Enable = "Включить Windows Defender"
            Btn_OpenSecurity = "Открыть Центр безопасности"
            Btn_LogShow = "Показать журнал"
            Btn_LogHide = "Скрыть журнал"
            Btn_Menu = "Меню"
            Menu_DefenderSettings = "Открыть параметры Defender"
            Menu_Refresh = "Обновить состояние"
            Menu_Github = "Открыть репозиторий GitHub"
            Menu_Language = "Язык"
            Menu_About = "О программе"
            Log_AppStarted = "Инструмент запущен. Если защита от изменений включена, некоторые шаги будут выглядеть неудачными - это ожидаемо."
            Log_DisableStart = "Начинается отключение Defender..."
            Log_EnableStart = "Начинается включение Defender..."
            Log_RefreshManual = "Состояние обновлено вручную."
            Log_OK = "OK"
            Log_FAILED = "ОШИБКА"
            Log_DisableDone = "Отключение завершено. Строки ОШИБКА выше заблокированы защитой от изменений."
            Log_DisableRebootNote = "Изменения службы вступят в силу только после перезагрузки. Перезагрузите компьютер и проверьте, что Windows Security показывает управление организацией."
            Log_EnableDone = "Включение завершено. Для полного применения изменений может потребоваться перезагрузка."
            Step_RealtimeOff = "Отключение защиты в реальном времени"
            Step_BehaviorOff = "Отключение отслеживания поведения"
            Step_IOAVOff = "Отключение проверки загружаемых файлов (IOAV)"
            Step_ScriptOff = "Отключение проверки скриптов"
            Step_CloudOff = "Отключение облачной защиты"
            Step_SamplesOff = "Отключение отправки образцов"
            Step_TaskOff = "Отключение задачи планового сканирования"
            Step_PolicySet = "Установка раздела реестра политики (DisableAntiSpyware)"
            Step_WinDefendDisable = "Отключение типа запуска WinDefend (вступит в силу после перезагрузки)"
            Step_WdNisDisable = "Отключение типа запуска WdNisSvc (вступит в силу после перезагрузки)"
            Step_RealtimeOn = "Включение защиты в реальном времени"
            Step_BehaviorOn = "Включение отслеживания поведения"
            Step_IOAVOn = "Включение проверки загружаемых файлов (IOAV)"
            Step_ScriptOn = "Включение проверки скриптов"
            Step_CloudOn = "Включение облачной защиты"
            Step_SamplesOn = "Сброс отправки образцов по умолчанию"
            Step_TaskOn = "Повторное включение задачи планового сканирования"
            Step_PolicyRemoved = "Удаление раздела реестра политики (DisableAntiSpyware)"
            Step_WinDefendManual = "Возврат типа запуска WinDefend в значение Вручную"
            Step_WdNisManual = "Возврат типа запуска WdNisSvc в значение Вручную"
            Step_WinDefendStart = "Запуск службы WinDefend"
            Step_WdNisStart = "Запуск службы WdNisSvc"
            Tamper_Title = "Защита от изменений включена"
            Tamper_Body = "Защита от несанкционированных изменений (Tamper Protection) ВКЛЮЧЕНА.`n`nПока она включена, параметры Defender нельзя изменить сценарием навсегда - Windows автоматически их откатывает. Это осознанное решение Microsoft в области безопасности, и его нельзя отключить сценарием, только вручную.`n`nШаги:`n1. Безопасность Windows > Защита от вирусов и угроз > Управление настройками`n2. Отключите Защиту от изменений`n`nОткрыть этот экран сейчас?"
            Tamper_Opened = "Экран параметров безопасности Windows открыт. После отключения защиты от изменений нажмите Отключить ещё раз."
            Tamper_StayedOn = "Защита от изменений осталась включённой - некоторые из следующих шагов завершатся ошибкой."
            About_Title = "О программе"
            About_Subtitle = "Личный инструмент для включения и отключения Windows Defender с правами администратора."
            About_Tagline = "Личный проект - создано вместе"
            About_Github = "Репозиторий GitHub"
            About_Issue = "Сообщить о проблеме"
            About_Author = "Автор"
            About_Website = "Сайт"
            About_OK = "ОК"
        }
    }
}

$script:Strings = Get-Strings

try {
    $savedLang = Get-ItemPropertyValue -Path "HKCU:\Software\DefenderController" -Name "Language" -ErrorAction Stop
} catch {
    $savedLang = "en"
}
if (-not $script:Strings.ContainsKey($savedLang)) { $savedLang = "en" }
$script:CurrentLang = $savedLang

function T {
    param([string]$Key)
    if ($script:Strings[$script:CurrentLang].ContainsKey($Key)) { return $script:Strings[$script:CurrentLang][$Key] }
    return $script:Strings["en"][$Key]
}

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Defender Controller" Width="440" SizeToContent="Height"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        FontFamily="Segoe UI" Background="#F4F4F4">
    <StackPanel>
        <Border x:Name="BannerBorder" Background="#C0392B" Padding="18,16,14,16">
            <Grid>
                <TextBlock x:Name="BannerText" Text="Checking status..." Foreground="White" FontSize="17" FontWeight="Bold"
                           VerticalAlignment="Center" Margin="0,0,70,0"/>
                <Button x:Name="MenuBtn" Content="Menu ▾" FontSize="12" Foreground="White"
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
                <Button x:Name="DisableBtn" Content="Disable Windows Defender" Height="34" Margin="0,0,0,8"
                        Background="White" BorderBrush="#CCCCCC" BorderThickness="1"/>
                <Button x:Name="EnableBtn" Content="Enable Windows Defender" Height="34" Margin="0,0,0,8"
                        Background="White" BorderBrush="#CCCCCC" BorderThickness="1"/>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="OpenSecurityBtn" Grid.Column="0" Content="Open Security Center" Height="30" FontSize="11" Margin="0,0,4,0"/>
                    <Button x:Name="LogToggleBtn" Grid.Column="1" Content="Show Log" Height="30" FontSize="11" Margin="4,0,0,0"/>
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
        # 5 = acik, 4 veya 0 = kapali (surume gore degisebilir, bu yuzden kesin degil)
        return ($val -eq 5)
    } catch {
        return $null # okunamadi, muhtemelen erisim kisitli
    }
}

function Update-Status {
    $resolved = $false
    try {
        $mp = Get-MpComputerStatus -ErrorAction Stop
        if ($mp.RealTimeProtectionEnabled) {
            $BannerBorder.Background = "#27AE60"
            $BannerText.Text = T "Banner_On"
            $ShieldPath.Fill = "#27AE60"
            $ShieldGlyph.Text = "✓"
        } else {
            $BannerBorder.Background = "#C0392B"
            $BannerText.Text = T "Banner_Off"
            $ShieldPath.Fill = "#C0392B"
            $ShieldGlyph.Text = "✕"
        }
        $resolved = $true
    } catch {
        # WMI saglayicisi (MsMpEng) cevap vermiyor olabilir - WinDefend servisi
        # devre disiysa bu normaldir, servis durumuna bakarak yine de anlamli bir
        # durum gosterebiliriz.
        try {
            $svc = Get-Service -Name WinDefend -ErrorAction Stop
            if ($svc.Status -ne 'Running') {
                $BannerBorder.Background = "#C0392B"
                $BannerText.Text = T "Banner_Off"
                $ShieldPath.Fill = "#C0392B"
                $ShieldGlyph.Text = "✕"
                $resolved = $true
            }
        } catch { }
    }

    if (-not $resolved) {
        $BannerBorder.Background = "#7F8C8D"
        $BannerText.Text = T "Banner_Unknown"
        $ShieldPath.Fill = "#7F8C8D"
        $ShieldGlyph.Text = "?"
    }

    $tamper = Get-TamperProtectionState
    if ($tamper -eq $true) {
        $TamperText.Text = T "Tamper_On"
    } elseif ($tamper -eq $false) {
        $TamperText.Text = ""
    } else {
        $TamperText.Text = T "Tamper_Unknown"
    }
}

function Set-Language {
    param([string]$Lang)
    if (-not $script:Strings.ContainsKey($Lang)) { $Lang = "en" }
    $script:CurrentLang = $Lang

    try {
        if (-not (Test-Path "HKCU:\Software\DefenderController")) {
            New-Item -Path "HKCU:\Software\DefenderController" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKCU:\Software\DefenderController" -Name "Language" -Value $Lang -Force -ErrorAction Stop
    } catch { }

    $DisableBtn.Content = T "Btn_Disable"
    $EnableBtn.Content = T "Btn_Enable"
    $OpenSecurityBtn.Content = T "Btn_OpenSecurity"
    $LogToggleBtn.Content = if ($LogPanel.Visibility -eq [System.Windows.Visibility]::Visible) { T "Btn_LogHide" } else { T "Btn_LogShow" }
    $MenuBtn.Content = "$(T 'Btn_Menu') ▾"

    if ($script:MiSettings) { $script:MiSettings.Header = T "Menu_DefenderSettings" }
    if ($script:MiRefresh)  { $script:MiRefresh.Header  = T "Menu_Refresh" }
    if ($script:MiGithub)   { $script:MiGithub.Header   = T "Menu_Github" }
    if ($script:MiLanguage) { $script:MiLanguage.Header = T "Menu_Language" }
    if ($script:MiAbout)    { $script:MiAbout.Header    = T "Menu_About" }

    if ($script:LangMenuItems) {
        foreach ($code in $script:LangMenuItems.Keys) {
            $script:LangMenuItems[$code].IsChecked = ($code -eq $script:CurrentLang)
        }
    }

    Update-Status
}

function Set-DefenderPreferenceSafe {
    param([string]$Description, [scriptblock]$Action)
    try {
        & $Action
        Write-Log "$(T 'Log_OK')  - $Description"
    } catch {
        Write-Log "$(T 'Log_FAILED') - $Description : $($_.Exception.Message)" "WARN"
    }
}

function Show-TamperWarning {
    $tamper = Get-TamperProtectionState
    if ($tamper -ne $true) { return }

    $result = [System.Windows.MessageBox]::Show(
        (T "Tamper_Body"),
        (T "Tamper_Title"),
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )

    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        Start-Process "windowsdefender://threatsettings"
        Write-Log (T "Tamper_Opened") "WARN"
    } else {
        Write-Log (T "Tamper_StayedOn") "WARN"
    }
}

function Disable-Defender {
    Write-Log (T "Log_DisableStart")
    Show-TamperWarning

    Set-DefenderPreferenceSafe (T "Step_RealtimeOff") { Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop }
    Set-DefenderPreferenceSafe (T "Step_BehaviorOff") { Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction Stop }
    Set-DefenderPreferenceSafe (T "Step_IOAVOff") { Set-MpPreference -DisableIOAVProtection $true -ErrorAction Stop }
    Set-DefenderPreferenceSafe (T "Step_ScriptOff") { Set-MpPreference -DisableScriptScanning $true -ErrorAction Stop }
    Set-DefenderPreferenceSafe (T "Step_CloudOff") { Set-MpPreference -MAPSReporting 0 -ErrorAction Stop }
    Set-DefenderPreferenceSafe (T "Step_SamplesOff") { Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction Stop }

    Set-DefenderPreferenceSafe (T "Step_TaskOff") {
        Get-ScheduledTask -TaskPath "\Microsoft\Windows\Windows Defender\" -ErrorAction Stop |
            Disable-ScheduledTask -ErrorAction Stop | Out-Null
    }

    Set-DefenderPreferenceSafe (T "Step_PolicySet") {
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        New-ItemProperty -Path $path -Name "DisableAntiSpyware" -PropertyType DWord -Value 1 -Force -ErrorAction Stop | Out-Null
    }

    # Security Center, WinDefend servisi calistigi surece Defender'i "aktif saglayici"
    # olarak gormeye devam eder. Servis "Protected Process Light" oldugu icin calisirken
    # Stop-Service/Set-Service ile durdurulamaz (Erisim Engellendi) - bu Tamper Protection'dan
    # bagimsiz, ayri bir OS korumasidir ve kasitli olarak asilamaz. Bunun yerine registry'deki
    # baslangic tipini dogrudan degistirip bir sonraki acilista baslamamasini sagliyoruz.
    Set-DefenderPreferenceSafe (T "Step_WinDefendDisable") {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name "Start" -Value 4 -Type DWord -ErrorAction Stop
    }
    Set-DefenderPreferenceSafe (T "Step_WdNisDisable") {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WdNisSvc" -Name "Start" -Value 4 -Type DWord -ErrorAction Stop
    }

    Write-Log (T "Log_DisableDone")
    Write-Log (T "Log_DisableRebootNote") "WARN"

    for ($i = 0; $i -lt 3; $i++) {
        Start-Sleep -Milliseconds 800
        Update-Status
    }
}

function Enable-Defender {
    Write-Log (T "Log_EnableStart")

    Set-DefenderPreferenceSafe (T "Step_RealtimeOn") { Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop }
    Set-DefenderPreferenceSafe (T "Step_BehaviorOn") { Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction Stop }
    Set-DefenderPreferenceSafe (T "Step_IOAVOn") { Set-MpPreference -DisableIOAVProtection $false -ErrorAction Stop }
    Set-DefenderPreferenceSafe (T "Step_ScriptOn") { Set-MpPreference -DisableScriptScanning $false -ErrorAction Stop }
    Set-DefenderPreferenceSafe (T "Step_CloudOn") { Set-MpPreference -MAPSReporting 2 -ErrorAction Stop }
    Set-DefenderPreferenceSafe (T "Step_SamplesOn") { Set-MpPreference -SubmitSamplesConsent 1 -ErrorAction Stop }

    Set-DefenderPreferenceSafe (T "Step_TaskOn") {
        Get-ScheduledTask -TaskPath "\Microsoft\Windows\Windows Defender\" -ErrorAction Stop |
            Enable-ScheduledTask -ErrorAction Stop | Out-Null
    }

    Set-DefenderPreferenceSafe (T "Step_PolicyRemoved") {
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        if (Test-Path $path) {
            Remove-ItemProperty -Path $path -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
        }
    }

    Set-DefenderPreferenceSafe (T "Step_WinDefendManual") {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name "Start" -Value 3 -Type DWord -ErrorAction Stop
    }
    Set-DefenderPreferenceSafe (T "Step_WdNisManual") {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WdNisSvc" -Name "Start" -Value 3 -Type DWord -ErrorAction Stop
    }
    Set-DefenderPreferenceSafe (T "Step_WinDefendStart") { Start-Service -Name WinDefend -ErrorAction Stop }
    Set-DefenderPreferenceSafe (T "Step_WdNisStart") { Start-Service -Name WdNisSvc -ErrorAction Stop }

    Write-Log (T "Log_EnableDone")

    # WinDefend yeni basladiginda MsMpEng motoru birkac saniye icinde ayaga kalkiyor;
    # hemen sorgulanirsa eski/bos durum donebiliyor. Kisa araliklarla birkac kez
    # tekrar sorgulayip arayuzu guncel tutuyoruz.
    for ($i = 0; $i -lt 5; $i++) {
        Start-Sleep -Milliseconds 800
        Update-Status
    }
}

function Show-AboutDialog {
    [xml]$aboutXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="About" Width="400" SizeToContent="Height"
        WindowStartupLocation="CenterOwner" ResizeMode="NoResize"
        FontFamily="Segoe UI" Background="#FFFFFF">
    <StackPanel Margin="0,0,0,18">
        <StackPanel Margin="22,20,22,10">
            <TextBlock Text="Defender Controller" FontSize="16" FontWeight="Bold"/>
            <TextBlock x:Name="AboutSubtitle" Text="" FontSize="12" Foreground="#555555" Margin="0,6,0,0" TextWrapping="Wrap"/>
            <TextBlock x:Name="AboutTagline" Text="" FontSize="11" FontStyle="Italic" Foreground="#999999" Margin="0,10,0,0"/>
        </StackPanel>

        <Border BorderBrush="#DDDDDD" BorderThickness="1" Margin="22,4,22,16" Padding="14">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="26"/>
                    <ColumnDefinition Width="118"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <TextBlock Grid.Row="0" Grid.Column="0" Text="🔗" FontSize="14"/>
                <TextBlock x:Name="LblGithub" Grid.Row="0" Grid.Column="1" Text="GitHub Repo" FontSize="12"/>
                <TextBlock x:Name="LinkGithub" Grid.Row="0" Grid.Column="2" Text="github.com/atlllas/windows-defender-controller"
                           FontSize="12" Foreground="#2E86DE" TextDecorations="Underline" Cursor="Hand" TextWrapping="Wrap"/>

                <TextBlock Grid.Row="1" Grid.Column="0" Text="🐞" FontSize="14" Margin="0,8,0,0"/>
                <TextBlock x:Name="LblIssue" Grid.Row="1" Grid.Column="1" Text="Report an Issue" FontSize="12" Margin="0,8,0,0"/>
                <TextBlock x:Name="LinkIssue" Grid.Row="1" Grid.Column="2" Text="github.com/atlllas/windows-defender-controller/issues"
                           FontSize="12" Foreground="#2E86DE" TextDecorations="Underline" Cursor="Hand" Margin="0,8,0,0" TextWrapping="Wrap"/>

                <TextBlock Grid.Row="2" Grid.Column="0" Text="👤" FontSize="14" Margin="0,8,0,0"/>
                <TextBlock x:Name="LblAuthor" Grid.Row="2" Grid.Column="1" Text="Author" FontSize="12" Margin="0,8,0,0"/>
                <TextBlock Grid.Row="2" Grid.Column="2" Text="atlllas" FontSize="12" Margin="0,8,0,0"/>

                <TextBlock Grid.Row="3" Grid.Column="0" Text="🌐" FontSize="14" Margin="0,8,0,0"/>
                <TextBlock x:Name="LblWebsite" Grid.Row="3" Grid.Column="1" Text="Website" FontSize="12" Margin="0,8,0,0"/>
                <TextBlock x:Name="LinkWebsite" Grid.Row="3" Grid.Column="2" Text="imatlas.dev"
                           FontSize="12" Foreground="#2E86DE" TextDecorations="Underline" Cursor="Hand" Margin="0,8,0,0"/>
            </Grid>
        </Border>

        <Button x:Name="AboutOkBtn" Content="OK" Width="100" Height="30" HorizontalAlignment="Center"/>
    </StackPanel>
</Window>
'@
    $aboutReader = New-Object System.Xml.XmlNodeReader $aboutXaml
    $aboutWindow = [Windows.Markup.XamlReader]::Load($aboutReader)
    $aboutWindow.Owner = $window
    $aboutWindow.Title = T "About_Title"

    $aboutWindow.FindName("AboutSubtitle").Text = T "About_Subtitle"
    $aboutWindow.FindName("AboutTagline").Text = T "About_Tagline"
    $aboutWindow.FindName("LblGithub").Text = T "About_Github"
    $aboutWindow.FindName("LblIssue").Text = T "About_Issue"
    $aboutWindow.FindName("LblAuthor").Text = T "About_Author"
    $aboutWindow.FindName("LblWebsite").Text = T "About_Website"

    $okBtn = $aboutWindow.FindName("AboutOkBtn")
    $okBtn.Content = T "About_OK"

    $linkGithub = $aboutWindow.FindName("LinkGithub")
    $linkIssue = $aboutWindow.FindName("LinkIssue")
    $linkWebsite = $aboutWindow.FindName("LinkWebsite")
    $linkGithub.Add_MouseLeftButtonUp({ Start-Process "https://github.com/atlllas/windows-defender-controller" })
    $linkWebsite.Add_MouseLeftButtonUp({ Start-Process "https://imatlas.dev" })
    $linkIssue.Add_MouseLeftButtonUp({ Start-Process "https://github.com/atlllas/windows-defender-controller/issues" })
    $okBtn.Add_Click({ $aboutWindow.Close() }.GetNewClosure())

    $aboutWindow.ShowDialog() | Out-Null
}

$DisableBtn.Add_Click({ Disable-Defender })
$EnableBtn.Add_Click({ Enable-Defender })
$OpenSecurityBtn.Add_Click({ Start-Process "windowsdefender://" })
$LogToggleBtn.Add_Click({
    if ($LogPanel.Visibility -eq [System.Windows.Visibility]::Visible) {
        $LogPanel.Visibility = [System.Windows.Visibility]::Collapsed
        $LogToggleBtn.Content = T "Btn_LogShow"
    } else {
        $LogPanel.Visibility = [System.Windows.Visibility]::Visible
        $LogToggleBtn.Content = T "Btn_LogHide"
    }
})

# ---- Ust seritteki menu ----
$AppMenu = New-Object System.Windows.Controls.ContextMenu
$AppMenu.PlacementTarget = $MenuBtn
$AppMenu.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom

function New-AppMenuItem {
    param([string]$Header, [scriptblock]$OnClick)
    $item = New-Object System.Windows.Controls.MenuItem
    $item.Header = $Header
    if ($OnClick) { $item.Add_Click($OnClick) }
    return $item
}

$script:MiSettings = New-AppMenuItem (T "Menu_DefenderSettings") { Start-Process "windowsdefender://threatsettings" }
$script:MiRefresh  = New-AppMenuItem (T "Menu_Refresh") { Update-Status; Write-Log (T "Log_RefreshManual") }
$script:MiGithub   = New-AppMenuItem (T "Menu_Github") { Start-Process "https://github.com/atlllas/windows-defender-controller" }
$script:MiLanguage = New-AppMenuItem (T "Menu_Language") $null
$script:MiAbout    = New-AppMenuItem (T "Menu_About") { Show-AboutDialog }

$script:LangMenuItems = @{}
$languageOrder = @(
    @{ Code = "en"; Name = "English" },
    @{ Code = "tr"; Name = "Türkçe" },
    @{ Code = "de"; Name = "Deutsch" },
    @{ Code = "es"; Name = "Español" },
    @{ Code = "fr"; Name = "Français" },
    @{ Code = "ru"; Name = "Русский" }
)
foreach ($lang in $languageOrder) {
    $code = $lang.Code
    $mi = New-Object System.Windows.Controls.MenuItem
    $mi.Header = $lang.Name
    $mi.IsCheckable = $true
    $mi.IsChecked = ($code -eq $script:CurrentLang)
    $mi.Add_Click({ Set-Language $code }.GetNewClosure())
    $script:MiLanguage.Items.Add($mi) | Out-Null
    $script:LangMenuItems[$code] = $mi
}

$AppMenu.Items.Add($script:MiSettings) | Out-Null
$AppMenu.Items.Add($script:MiRefresh) | Out-Null
$AppMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null
$AppMenu.Items.Add($script:MiLanguage) | Out-Null
$AppMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null
$AppMenu.Items.Add($script:MiGithub) | Out-Null
$AppMenu.Items.Add($script:MiAbout) | Out-Null

$MenuBtn.Add_Click({ $AppMenu.IsOpen = $true })

Set-Language $script:CurrentLang
Write-Log (T "Log_AppStarted")

$window.ShowDialog() | Out-Null
