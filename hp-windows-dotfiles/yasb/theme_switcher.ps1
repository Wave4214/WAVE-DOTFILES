param(
    [Parameter(Position = 0)]
    [ValidateSet('get', 'set', 'next', 'watch-accent')]
    [string]$Action = 'get',

    [Parameter(Position = 1)]
    [string]$Theme,

    [Parameter(Position = 2)]
    [int]$IntervalSeconds = 30
)

$ErrorActionPreference = 'Stop'

$configDirectory = Join-Path $env:USERPROFILE '.config\yasb'
$stylesheetPath = Join-Path $configDirectory 'styles.css'
$accentPath = Join-Path $configDirectory 'yasb_colors.css'

$themeNames = @(
    'Catppuccin Latte',
    'Catppuccin Frappe',
    'Catppuccin Macchiato',
    'Catppuccin Mocha',
    'Gruvbox Material Dark Soft',
    'Your Lie In April',
    'Sousou no Frieren',
    'Everforest Dark Soft',
    'Monochrome',
    'Tokyo Night',
    'Monochrome Light',
    'Monochrome Accent Dark',
    'Monochrome Accent Light',
    'Everforest Dark',
    'Nord',
    'Onyx',
    'Onyx OLED',
    'Kanagawa Wave',
    'Matugen'
)

$themeMarkers = @{
    'Catppuccin Latte' = 'Catppuccin Latte'
    'Catppuccin Frappe' = 'Catppuccin Frappé'
    'Catppuccin Macchiato' = 'Catppuccin Macchiato'
    'Catppuccin Mocha' = 'Catppuccin Mocha'
    'Gruvbox Material Dark Soft' = 'Gruvbox Material Dark Soft'
    'Your Lie In April' = 'Your Lie In April'
    'Sousou no Frieren' = 'Sousou no Frieren'
    'Everforest Dark Soft' = 'Everforest Dark Soft'
    'Monochrome' = 'Monochrome'
    'Tokyo Night' = 'Tokyo Night'
    'Monochrome Light' = 'Monochrome Light'
    'Monochrome Accent Dark' = 'Monochrome Accent Dark'
    'Monochrome Accent Light' = 'MonochromeAccentLight'
    'Everforest Dark' = 'Everforest Dark'
    'Nord' = 'Nord'
    'Onyx' = 'Onyx'
    'Onyx OLED' = 'Onyx OLED'
    'Kanagawa Wave' = 'Kanagawa'
    'Matugen' = 'Matugen'
}

function Get-ThemeSection {
    param(
        [string[]]$Lines,
        [string]$Name
    )

    $markerName = $themeMarkers[$Name]
    $start = -1
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^\s*/\*\s*(?<name>[^*]+?)\s*\*/\s*$' -and
            $Matches.name.Trim() -eq $markerName) {
            $start = $index + 1
            break
        }
    }

    if ($start -lt 0) {
        throw "Theme marker not found in styles.css: $markerName"
    }

    $end = $Lines.Count
    for ($index = $start; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^\s*/\*\s*(?<name>[^*]+?)\s*\*/\s*$' -and
            $themeMarkers.Values -contains $Matches.name.Trim()) {
            $end = $index
            break
        }
        if ($Lines[$index] -match '^\s*}\s*$') {
            $end = $index
            break
        }
    }

    $backgroundIndex = -1
    $subtextIndex = -1
    for ($index = $start; $index -lt $end; $index++) {
        if ($Lines[$index] -match '--background:') { $backgroundIndex = $index }
        if ($Lines[$index] -match '--subtext:') { $subtextIndex = $index }
    }

    if ($backgroundIndex -lt 0 -or $subtextIndex -lt 0) {
        throw "Theme variable block is incomplete in styles.css: $markerName"
    }

    return [pscustomobject]@{
        BackgroundIndex = $backgroundIndex
        SubtextIndex = $subtextIndex
    }
}

function Get-ActiveTheme {
    param([string[]]$Lines)

    foreach ($name in $themeNames) {
        $section = Get-ThemeSection -Lines $Lines -Name $name
        if ($Lines[$section.BackgroundIndex] -notmatch '^\s*/\*') {
            return $name
        }
    }

    throw 'No active theme block was found in styles.css.'
}

function Get-CurrentWallpaperPath {
    $wallpaper = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
    if (-not $wallpaper -or -not (Test-Path -LiteralPath $wallpaper)) {
        throw 'The current Windows wallpaper file could not be found.'
    }
    return (Resolve-Path -LiteralPath $wallpaper).Path
}

function Get-MatugenColor {
    param(
        $Palette,
        [string]$Name,
        [string]$Mode
    )

    return $Palette.colors.PSObject.Properties[$Name].Value.PSObject.Properties[$Mode].Value.color
}

function Invoke-MatugenTheme {
    $wallpaper = Get-CurrentWallpaperPath
    $matugenCommand = Get-Command matugen -ErrorAction Stop
    $matugenOutput = & $matugenCommand.Source image $wallpaper --source-color-index 0 --type scheme-tonal-spot --mode dark --json hex --dry-run 2>$null | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Matugen failed to generate colors for: $wallpaper"
    }

    $palette = $matugenOutput | ConvertFrom-Json
    $mode = if ($palette.is_dark_mode) { 'dark' } else { 'light' }
    $variables = [ordered]@{
        '--matugen-background' = Get-MatugenColor -Palette $palette -Name 'background' -Mode $mode
        '--matugen-background2' = Get-MatugenColor -Palette $palette -Name 'surface_container' -Mode $mode
        '--matugen-accent' = Get-MatugenColor -Palette $palette -Name 'primary' -Mode $mode
        '--matugen-text' = Get-MatugenColor -Palette $palette -Name 'on_surface' -Mode $mode
        '--matugen-accent-text' = Get-MatugenColor -Palette $palette -Name 'on_primary' -Mode $mode
        '--matugen-hover' = Get-MatugenColor -Palette $palette -Name 'secondary_container' -Mode $mode
        '--matugen-muted' = Get-MatugenColor -Palette $palette -Name 'surface_container_high' -Mode $mode
        '--matugen-border' = Get-MatugenColor -Palette $palette -Name 'outline_variant' -Mode $mode
        '--matugen-error' = Get-MatugenColor -Palette $palette -Name 'error' -Mode $mode
        '--matugen-subtext' = Get-MatugenColor -Palette $palette -Name 'on_surface_variant' -Mode $mode
    }

    $cssLines = [System.Collections.Generic.List[string]]::new()
    $cssLines.Add('/* Generated by Matugen. Do not edit. */')
    $cssLines.Add(':root {')
    foreach ($name in $variables.Keys) {
        $cssLines.Add("    ${name}: $($variables[$name]);")
    }
    $cssLines.Add('}')
    $updatedContent = [string]::Join("`r`n", $cssLines) + "`r`n"
    $matugenCssPath = Join-Path $configDirectory 'matugen_colors.css'
    if ((Test-Path -LiteralPath $matugenCssPath) -and
        [System.IO.File]::ReadAllText($matugenCssPath) -eq $updatedContent) {
        return
    }

    $temporaryPath = "$matugenCssPath.tmp"
    try {
        [System.IO.File]::WriteAllText($temporaryPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temporaryPath, $matugenCssPath, $true)
        [System.IO.File]::SetLastWriteTimeUtc($stylesheetPath, [DateTime]::UtcNow)
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Set-ActiveTheme {
    param([string]$Name)

    if ($Name -eq 'Matugen') {
        Invoke-MatugenTheme
    }

    if (-not (Test-Path -LiteralPath $stylesheetPath)) {
        throw "Stylesheet not found: $stylesheetPath"
    }

    $content = [System.IO.File]::ReadAllText($stylesheetPath)
    $newline = if ($content.Contains("`r`n")) { "`r`n" } else { "`n" }
    $endsWithNewline = $content.EndsWith("`n")
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in [regex]::Split($content, "`r?`n")) {
        $lines.Add($line)
    }

    foreach ($themeName in $themeNames) {
        $section = Get-ThemeSection -Lines $lines.ToArray() -Name $themeName
        $backgroundLine = $lines[$section.BackgroundIndex]
        $subtextLine = $lines[$section.SubtextIndex]
        $isActive = $backgroundLine -notmatch '^\s*/\*'

        if ($themeName -eq $Name) {
            if (-not $isActive) {
                $lines[$section.BackgroundIndex] = $backgroundLine -replace '^(\s*)/\*\s*(--background:)', '$1$2'
                $lines[$section.SubtextIndex] = $subtextLine -replace ';\s*\*/\s*$', ';'
            }
        } elseif ($isActive) {
            $lines[$section.BackgroundIndex] = $backgroundLine -replace '^(\s*)(--background:)', '$1/* $2'
            $lines[$section.SubtextIndex] = $subtextLine -replace ';\s*$', '; */'
        }
    }

    $updatedContent = [string]::Join($newline, $lines)
    if ($endsWithNewline) { $updatedContent += $newline }
    $encoding = [System.Text.UTF8Encoding]::new($false)
    $temporaryPath = "$stylesheetPath.tmp"
    try {
        [System.IO.File]::WriteAllText($temporaryPath, $updatedContent, $encoding)
        [System.IO.File]::Move($temporaryPath, $stylesheetPath, $true)
        [System.IO.File]::SetLastWriteTimeUtc($stylesheetPath, [DateTime]::UtcNow)
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Start-WallpaperWatcher {
    param([int]$IntervalSeconds)

    $watcherMutex = [System.Threading.Mutex]::new($false, 'Local\YASB.ThemeSwitcher.WallpaperWatcher')
    $mutexAcquired = $false
    try {
        try {
            $mutexAcquired = $watcherMutex.WaitOne(0)
        } catch [System.Threading.AbandonedMutexException] {
            $mutexAcquired = $true
        }
        if (-not $mutexAcquired) { return }

        if (-not (Test-Path -LiteralPath $accentPath)) {
            throw "YASB accent file not found: $accentPath"
        }
        $lastWrite = (Get-Item -LiteralPath $accentPath).LastWriteTimeUtc
        $lastWallpaper = Get-CurrentWallpaperPath
        $lastWallpaperWrite = (Get-Item -LiteralPath $lastWallpaper).LastWriteTimeUtc
        $pollSeconds = [Math]::Max(5, $IntervalSeconds)
        if ((Get-ActiveTheme -Lines ([System.IO.File]::ReadAllLines($stylesheetPath))) -eq 'Matugen') {
            Invoke-MatugenTheme
        }
        while ($true) {
            Start-Sleep -Seconds $pollSeconds
            $currentWrite = (Get-Item -LiteralPath $accentPath).LastWriteTimeUtc
            $currentWallpaper = Get-CurrentWallpaperPath
            $currentWallpaperWrite = (Get-Item -LiteralPath $currentWallpaper).LastWriteTimeUtc
            $wallpaperChanged = $currentWallpaper -ne $lastWallpaper -or $currentWallpaperWrite -ne $lastWallpaperWrite
            $accentChanged = $currentWrite -ne $lastWrite
            $activeTheme = Get-ActiveTheme -Lines ([System.IO.File]::ReadAllLines($stylesheetPath))

            if ($wallpaperChanged) {
                Set-ActiveTheme -Name 'Matugen'
            } elseif ($activeTheme -eq 'Matugen' -and $accentChanged) {
                Invoke-MatugenTheme
                [System.IO.File]::SetLastWriteTimeUtc($stylesheetPath, [DateTime]::UtcNow)
            } elseif ($accentChanged) {
                [System.IO.File]::SetLastWriteTimeUtc($stylesheetPath, [DateTime]::UtcNow)
            }

            $lastWrite = $currentWrite
            $lastWallpaper = $currentWallpaper
            $lastWallpaperWrite = $currentWallpaperWrite
        }
    } finally {
        if ($mutexAcquired) { $watcherMutex.ReleaseMutex() }
        $watcherMutex.Dispose()
    }
}

switch ($Action) {
    'get' {
        if (-not (Test-Path -LiteralPath $stylesheetPath)) {
            throw "Stylesheet not found: $stylesheetPath"
        }
        $lines = [System.IO.File]::ReadAllLines($stylesheetPath)
        Get-ActiveTheme -Lines $lines
    }
    'set' {
        $selectedTheme = $themeNames | Where-Object { $_ -ieq $Theme } | Select-Object -First 1
        if (-not $selectedTheme) {
            throw "Unknown theme '$Theme'. Available themes: $($themeNames -join ', ')"
        }
        Set-ActiveTheme -Name $selectedTheme
        $selectedTheme
    }
    'next' {
        $lines = [System.IO.File]::ReadAllLines($stylesheetPath)
        $activeTheme = Get-ActiveTheme -Lines $lines
        $activeIndex = [array]::IndexOf($themeNames, $activeTheme)
        $nextIndex = ($activeIndex + 1) % $themeNames.Count
        Set-ActiveTheme -Name $themeNames[$nextIndex]
        $themeNames[$nextIndex]
    }
    'watch-accent' {
        Start-WallpaperWatcher -IntervalSeconds $IntervalSeconds
    }
}