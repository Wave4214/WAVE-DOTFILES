param(
    [Parameter(Position = 0)]
    [ValidateSet('sync', 'watch', 'install')]
    [string]$Action = 'sync',

    [Parameter(Position = 1)]
    [ValidateRange(5, 3600)]
    [int]$IntervalSeconds = 5
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'theme-sync.psm1') -Force

function Get-CurrentWallpaperPath {
    $wallpaper = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
    if (-not $wallpaper -or -not (Test-Path -LiteralPath $wallpaper)) {
        throw 'The current Windows wallpaper file could not be found.'
    }

    return (Resolve-Path -LiteralPath $wallpaper).Path
}

function Get-WallpaperPalette {
    $wallpaper = Get-CurrentWallpaperPath
    $matugen = Get-Command 'matugen' -ErrorAction SilentlyContinue
    if (-not $matugen) {
        throw "Matugen was not found in PATH. Install Matugen or add its executable to PATH."
    }

    $templatePath = Join-Path $PSScriptRoot 'matugen-limusic.css'
    if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
        throw "LiMusic Matugen template was not found: $templatePath"
    }

    $configPath = Join-Path $PSScriptRoot 'matugen-limusic.toml'
    $limusicConfigDirectory = Join-Path $env:APPDATA 'limusic'
    if (-not (Test-Path -LiteralPath $limusicConfigDirectory)) {
        New-Item -ItemType Directory -Path $limusicConfigDirectory -Force | Out-Null
    }

    $tomlTemplatePath = '"' + $templatePath.Replace('\', '\\').Replace('"', '\"') + '"'
    $tomlOutputPath = '"' + (Join-Path $limusicConfigDirectory 'matugen.css').Replace('\', '\\').Replace('"', '\"') + '"'
    $config = @"
[config]
version_check = false

[templates.limusic]
input_path = $tomlTemplatePath
output_path = $tomlOutputPath
"@
    [System.IO.File]::WriteAllText($configPath, $config, [System.Text.UTF8Encoding]::new($false))

    $output = & $matugen.Source image $wallpaper --config $configPath --source-color-index 0 --type scheme-tonal-spot --mode dark --json hex 2>$null | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Matugen failed to generate colors for '$wallpaper' (exit code $LASTEXITCODE)."
    }

    try {
        $matugenPalette = $output | ConvertFrom-Json
    } catch {
        throw "Could not parse Matugen's JSON palette: $($_.Exception.Message)"
    }

    return ConvertFrom-MatugenPalette -MatugenPalette $matugenPalette
}

function Sync-WallpaperTheme {
    $wallpaper = Get-CurrentWallpaperPath
    $palette = Get-WallpaperPalette
    Sync-SystemTheme -Palette $palette -ThemeName "Wallpaper: $(Split-Path -Leaf $wallpaper)"
}

function Start-WallpaperWatcher {
    $mutex = [System.Threading.Mutex]::new($false, 'Local\YASB.WallpaperTheme.Watcher')
    $acquired = $false
    try {
        try {
            $acquired = $mutex.WaitOne(0)
        } catch [System.Threading.AbandonedMutexException] {
            $acquired = $true
        }
        if (-not $acquired) {
            Write-ThemeLog 'Watcher is already running; this instance is exiting.'
            return
        }

        $wallpaper = Get-CurrentWallpaperPath
        Sync-WallpaperTheme | Out-Null

        while ($true) {
            Start-Sleep -Seconds $IntervalSeconds
            try {
                $currentWallpaper = Get-CurrentWallpaperPath
                if ($currentWallpaper -ne $wallpaper) {
                    Sync-WallpaperTheme | Out-Null
                    $wallpaper = $currentWallpaper
                }
            } catch {
                Write-ThemeLog "Wallpaper sync failed; will retry: $($_.Exception.Message)"
            }
        }
    } finally {
        if ($acquired) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

function Install-WallpaperWatcherTask {
    $powerShellPath = Join-Path $PSHOME 'pwsh.exe'
    if (-not (Test-Path -LiteralPath $powerShellPath)) {
        throw "PowerShell executable not found: $powerShellPath"
    }

    $arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`" watch $IntervalSeconds"
    $taskAction = New-ScheduledTaskAction -Execute $powerShellPath -Argument $arguments
    $user = "$env:USERDOMAIN\$env:USERNAME"
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
    $recoveryTrigger = New-ScheduledTaskTrigger `
        -Once `
        -At (Get-Date).AddMinutes(1) `
        -RepetitionInterval (New-TimeSpan -Minutes 1) `
        -RepetitionDuration (New-TimeSpan -Days 3650)
    $settings = New-ScheduledTaskSettingsSet `
        -MultipleInstances IgnoreNew `
        -RestartCount 999 `
        -RestartInterval (New-TimeSpan -Minutes 1) `
        -ExecutionTimeLimit ([TimeSpan]::Zero) `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries

    Register-ScheduledTask `
        -TaskName 'YASB Wallpaper Theme Watcher' `
        -Description 'Uses Matugen to automatically adapt YASB, btop, Cava, Superfile, Windows Terminal, Vencord, VS Code, and Nilesoft Shell colors when the wallpaper changes.' `
        -Action $taskAction `
        -Trigger @($trigger, $recoveryTrigger) `
        -Settings $settings `
        -User $user `
        -RunLevel Limited `
        -Force | Out-Null

    Start-ScheduledTask -TaskName 'YASB Wallpaper Theme Watcher'
    Write-ThemeLog "Installed and started logon task for $user."
    Write-Output 'Installed and started YASB Wallpaper Theme Watcher.'
}

switch ($Action) {
    'sync' {
        Sync-WallpaperTheme
    }
    'watch' {
        Start-WallpaperWatcher
    }
    'install' {
        Install-WallpaperWatcherTask
    }
}
