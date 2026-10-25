$script:ConfigDirectory = Join-Path $env:USERPROFILE '.config\yasb'
$script:YamlConfigPath = Join-Path $script:ConfigDirectory 'config.yaml'
$script:StylesheetPath = Join-Path $script:ConfigDirectory 'styles.css'
$script:NilesoftThemePath = Join-Path $env:ProgramFiles 'Nilesoft Shell\imports\theme.nss'
$script:BtopConfigPath = Join-Path $env:USERPROFILE 'scoop\persist\btop\btop.conf'
$script:BtopThemePath = Join-Path $env:USERPROFILE 'scoop\persist\btop\themes\Matugen.theme'
$script:CavaConfigPath = Join-Path $env:USERPROFILE '.config\cava\config'
$script:SuperfileConfigPath = Join-Path $env:LOCALAPPDATA 'superfile\config.toml'
$script:SuperfileThemePath = Join-Path $env:LOCALAPPDATA 'superfile\theme\matugen.toml'
$script:TerminalSettingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$script:VencordQuickCssPath = Join-Path $env:APPDATA 'Vencord\settings\quickCss.css'
$script:VSCodeSettingsPath = Join-Path $env:APPDATA 'Code\User\settings.json'
$script:PaletteCacheDirectory = Join-Path $env:USERPROFILE '.cache\matugen'
$script:LogPath = Join-Path $script:ConfigDirectory 'wallpaper-watcher.log'

function Write-ThemeLog {
    param([Parameter(Mandatory)][string]$Message)

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -LiteralPath $script:LogPath -Value "[$timestamp] $Message" -Encoding utf8
}

function Write-AtomicText {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    if ((Test-Path -LiteralPath $Path) -and [System.IO.File]::ReadAllText($Path) -ceq $Content) {
        return $false
    }

    $temporaryPath = "$Path.tmp"
    try {
        [System.IO.File]::WriteAllText($temporaryPath, $Content, [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temporaryPath, $Path, $true)
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }

    return $true
}

function Get-PaletteColor {
    param(
        [Parameter(Mandatory)]$Palette,
        [Parameter(Mandatory)][string]$Group,
        [Parameter(Mandatory)][string]$Name
    )

    $color = [string]$Palette.$Group.$Name
    if ($color -notmatch '^#[0-9a-fA-F]{6}$') {
        throw "Palette color '$Group.$Name' is missing or invalid: $color"
    }

    return $color.ToLowerInvariant()
}

function ConvertFrom-MatugenPalette {
    param([Parameter(Mandatory)]$MatugenPalette)

    if ($MatugenPalette.is_dark_mode -isnot [bool]) {
        throw "Matugen's JSON palette is missing its is_dark_mode value."
    }

    $mode = if ($MatugenPalette.is_dark_mode) { 'dark' } else { 'light' }
    $roles = $MatugenPalette.colors
    $colors = [ordered]@{
        color0  = $roles.background.$mode.color
        color1  = $roles.error.$mode.color
        color2  = $roles.tertiary.$mode.color
        color3  = $roles.secondary.$mode.color
        color4  = $roles.primary.$mode.color
        color5  = $roles.tertiary_container.$mode.color
        color6  = $roles.secondary_container.$mode.color
        color7  = $roles.on_surface.$mode.color
        color8  = $roles.surface_container.$mode.color
        color9  = $roles.error.$mode.color
        color10 = $roles.tertiary.$mode.color
        color11 = $roles.secondary.$mode.color
        color12 = $roles.primary.$mode.color
        color13 = $roles.tertiary_container.$mode.color
        color14 = $roles.secondary_container.$mode.color
        color15 = $roles.on_surface.$mode.color
    }

    $special = [ordered]@{
        background      = $roles.background.$mode.color
        foreground      = $roles.on_surface.$mode.color
        cursor          = $roles.primary.$mode.color
        mantle          = $roles.surface_container_low.$mode.color
        crust           = $roles.surface_container_lowest.$mode.color
        surface         = $roles.surface_container.$mode.color
        surface_raised  = $roles.surface_container_high.$mode.color
        subtext         = $roles.on_surface_variant.$mode.color
    }

    return [pscustomobject]@{
        special = [pscustomobject]$special
        colors = [pscustomobject]$colors
    }
}

function ConvertTo-ColorPaletteJson {
    param([Parameter(Mandatory)]$Palette)

    $special = [ordered]@{
        background = Get-PaletteColor -Palette $Palette -Group 'special' -Name 'background'
        foreground = Get-PaletteColor -Palette $Palette -Group 'special' -Name 'foreground'
        cursor = Get-PaletteColor -Palette $Palette -Group 'special' -Name 'cursor'
    }
    $colors = [ordered]@{}
    foreach ($index in 0..15) {
        $name = "color$index"
        $colors[$name] = Get-PaletteColor -Palette $Palette -Group 'colors' -Name $name
    }

    return [pscustomobject]@{
        special = [pscustomobject]$special
        colors = [pscustomobject]$colors
    }
}

function Set-YasbPalette {
    param([Parameter(Mandatory)]$Palette)

    $paletteJson = ConvertTo-ColorPaletteJson -Palette $Palette
    $special = $Palette.special
    $cssLines = [System.Collections.Generic.List[string]]::new()
    $cssLines.Add('/* Generated by theme-sync.psm1. Do not edit. */')
    $cssLines.Add(':root {')
    $cssLines.Add("    --theme-background: $($special.background);")
    $cssLines.Add("    --theme-mantle: $(Get-PaletteColor -Palette $Palette -Group 'special' -Name 'mantle');")
    $cssLines.Add("    --theme-crust: $(Get-PaletteColor -Palette $Palette -Group 'special' -Name 'crust');")
    $cssLines.Add("    --theme-surface: $(Get-PaletteColor -Palette $Palette -Group 'special' -Name 'surface');")
    $cssLines.Add("    --theme-surface-raised: $(Get-PaletteColor -Palette $Palette -Group 'special' -Name 'surface_raised');")
    $cssLines.Add("    --theme-foreground: $($special.foreground);")
    $cssLines.Add("    --theme-subtext: $(Get-PaletteColor -Palette $Palette -Group 'special' -Name 'subtext');")
    $cssLines.Add("    --theme-accent: $(Get-PaletteColor -Palette $Palette -Group 'colors' -Name 'color4');")
    foreach ($index in 0..15) {
        $name = "color$index"
        $cssLines.Add("    --theme-$name`: $(Get-PaletteColor -Palette $Palette -Group 'colors' -Name $name);")
    }
    $cssLines.Add('    --base: var(--theme-background);')
    $cssLines.Add('    --mantle: var(--theme-mantle);')
    $cssLines.Add('    --crust: var(--theme-crust);')
    $cssLines.Add('    --text: var(--theme-foreground);')
    $cssLines.Add('    --subtext0: var(--theme-subtext);')
    $cssLines.Add('    --subtext1: var(--theme-subtext);')
    $cssLines.Add('    --surface0: var(--theme-surface);')
    $cssLines.Add('    --surface1: var(--theme-surface-raised);')
    $cssLines.Add('    --surface2: var(--theme-surface-raised);')
    $cssLines.Add('    --teal: var(--theme-accent);')
    $cssLines.Add('    --blue: var(--theme-color4);')
    $cssLines.Add('    --sapphire: var(--theme-color6);')
    $cssLines.Add('    --red: var(--theme-color1);')
    $cssLines.Add('    --green: var(--theme-color2);')
    $cssLines.Add('    --yellow: var(--theme-color3);')
    $cssLines.Add('    --peach: var(--theme-color3);')
    $cssLines.Add('    --pink: var(--theme-color5);')
    $cssLines.Add('    --sky: var(--theme-color6);')
    $cssLines.Add('    --overlay0: var(--theme-color8);')
    $cssLines.Add('    --overlay1: var(--theme-subtext);')
    $cssLines.Add('}')
    $css = [string]::Join("`r`n", $cssLines) + "`r`n"
    $cssChanged = Write-AtomicText -Path (Join-Path $script:ConfigDirectory 'matugen_colors.css') -Content $css
    $json = $paletteJson | ConvertTo-Json -Depth 8
    $jsonChanged = Write-AtomicText -Path (Join-Path $script:PaletteCacheDirectory 'colors.json') -Content ($json + "`r`n")

    if ($cssChanged -and (Test-Path -LiteralPath $script:StylesheetPath)) {
        [System.IO.File]::SetLastWriteTimeUtc($script:StylesheetPath, [DateTime]::UtcNow)
    }

    if (Test-Path -LiteralPath $script:YamlConfigPath) {
        $config = [System.IO.File]::ReadAllText($script:YamlConfigPath)
        $accent = $paletteJson.colors.color4
        foreach ($name in @('current_line_color', 'top_color', 'bottom_color')) {
            $pattern = '(?m)^(\s*' + [regex]::Escape($name) + ':\s*)"#?[0-9a-fA-F]{6}"(\s*(?:#.*)?)$'
            $regex = [regex]::new($pattern)
            if ($regex.Matches($config).Count -eq 1) {
                $config = $regex.Replace($config, [System.Text.RegularExpressions.MatchEvaluator]{
                    param($match)
                    return $match.Groups[1].Value + '"' + $accent + '"' + $match.Groups[2].Value
                })
            }
        }
        if (Write-AtomicText -Path $script:YamlConfigPath -Content $config) {
            [System.IO.File]::SetLastWriteTimeUtc($script:YamlConfigPath, [DateTime]::UtcNow)
        }
    }

    return ($cssChanged -or $jsonChanged)
}

function Set-BtopPalette {
    param([Parameter(Mandatory)]$Palette)

    if (-not (Test-Path -LiteralPath $script:BtopConfigPath -PathType Leaf)) {
        throw "btop config not found: $script:BtopConfigPath"
    }

    $special = $Palette.special
    $colors = $Palette.colors
    $themeValues = [ordered]@{
        main_bg       = $special.background
        main_fg       = $special.foreground
        title         = $special.foreground
        hi_fg         = $colors.color4
        selected_bg   = $special.surface_raised
        selected_fg   = $special.foreground
        inactive_fg   = $special.subtext
        proc_misc     = $colors.color4
        cpu_box       = $colors.color8
        mem_box       = $colors.color8
        net_box       = $colors.color8
        proc_box      = $colors.color8
        div_line      = $colors.color8
        temp_start    = $colors.color2
        temp_mid      = $colors.color3
        temp_end      = $colors.color1
        cpu_start     = $colors.color2
        cpu_mid       = $colors.color3
        cpu_end       = $colors.color1
        free_start    = $colors.color2
        free_mid      = $colors.color3
        free_end      = $colors.color1
        cached_start  = $colors.color5
        cached_mid    = $colors.color13
        cached_end    = $colors.color8
        available_start = $colors.color6
        available_mid = $colors.color14
        available_end = $colors.color8
        used_start    = $colors.color1
        used_mid      = $colors.color9
        used_end      = $colors.color8
        download_start = $colors.color4
        download_mid = $colors.color12
        download_end = $colors.color6
        upload_start  = $colors.color5
        upload_mid    = $colors.color13
        upload_end    = $colors.color4
    }

    $themeLines = [System.Collections.Generic.List[string]]::new()
    $themeLines.Add('# Generated from the current Matugen wallpaper palette.')
    foreach ($name in $themeValues.Keys) {
        $color = [string]$themeValues[$name]
        if ($color -notmatch '^#[0-9a-fA-F]{6}$') {
            throw "Matugen color for btop theme '$name' is missing or invalid: $color"
        }
        $themeLines.Add("theme[$name]`=`"$($color.ToLowerInvariant())`"")
    }
    Write-AtomicText -Path $script:BtopThemePath -Content ([string]::Join("`r`n", $themeLines) + "`r`n") | Out-Null

    $configLines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in [System.IO.File]::ReadAllLines($script:BtopConfigPath)) {
        $configLines.Add($line)
    }
    $themeConfigLines = @(
        for ($index = 0; $index -lt $configLines.Count; $index++) {
            if ($configLines[$index] -match '^\s*color_theme\s*=') {
                $index
            }
        }
    )
    if ($themeConfigLines.Count -ne 1) {
        throw "Expected exactly one color_theme setting in btop config; found $($themeConfigLines.Count)."
    }

    $configLines[$themeConfigLines[0]] = [regex]::Replace(
        $configLines[$themeConfigLines[0]],
        '^(\s*color_theme\s*=\s*).*$',
        '$1"Matugen"'
    )
    [System.IO.File]::WriteAllText(
        $script:BtopConfigPath,
        [string]::Join("`r`n", $configLines) + "`r`n",
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Set-CavaPalette {
    param([Parameter(Mandatory)][string]$Accent)

    if (-not (Test-Path -LiteralPath $script:CavaConfigPath)) {
        Write-ThemeLog "Cava config not found; skipped: $script:CavaConfigPath"
        return
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in [System.IO.File]::ReadAllLines($script:CavaConfigPath)) {
        $lines.Add($line)
    }

    $sectionStart = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^\s*\[color\]\s*(?:#.*)?$') {
            $sectionStart = $index
            break
        }
    }
    if ($sectionStart -lt 0) {
        throw "Cava config has no [color] section: $script:CavaConfigPath"
    }

    $sectionEnd = $lines.Count
    for ($index = $sectionStart + 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^\s*\[') {
            $sectionEnd = $index
            break
        }
    }

    $activeLines = @()
    $commentedLines = @()
    for ($index = $sectionStart + 1; $index -lt $sectionEnd; $index++) {
        if ($lines[$index] -match '^\s*foreground\s*=') {
            $activeLines += $index
        } elseif ($lines[$index] -match '^\s*;\s*foreground\s*=') {
            $commentedLines += $index
        }
    }
    if ($activeLines.Count -gt 1) {
        throw 'Cava [color] section has multiple active foreground values.'
    }
    if ($activeLines.Count -eq 1) {
        $lines[$activeLines[0]] = "foreground = '$Accent'"
    } elseif ($commentedLines.Count -gt 0) {
        $lines[$commentedLines[0]] = "foreground = '$Accent'"
    } else {
        $lines.Insert($sectionStart + 1, "foreground = '$Accent'")
    }

    $content = [string]::Join("`r`n", $lines) + "`r`n"
    if (-not (Write-AtomicText -Path $script:CavaConfigPath -Content $content)) {
        return
    }

    $processes = @(Get-Process -Name 'cava' -ErrorAction SilentlyContinue)
    foreach ($process in $processes) {
        $processPath = $process.Path
        if (-not $processPath) {
            throw "Cannot restart Cava process $($process.Id): executable path is unavailable."
        }

        $commandLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($process.Id)").CommandLine
        $arguments = ''
        if ($commandLine -match '^\s*"(?:[^"]+)"\s*(?<args>.*)$') {
            $arguments = $Matches.args
        } elseif ($commandLine -match '^\s*\S+\s*(?<args>.*)$') {
            $arguments = $Matches.args
        }

        Stop-Process -Id $process.Id -ErrorAction Stop
        if ($arguments) {
            Start-Process -FilePath $processPath -ArgumentList $arguments
        } else {
            Start-Process -FilePath $processPath
        }
        Write-ThemeLog "Restarted Cava after applying its palette."
    }
}

function Set-SuperfilePalette {
    param([Parameter(Mandatory)]$Palette)

    $special = $Palette.special
    $colors = $Palette.colors
    $themeValues = [ordered]@{
        code_syntax_highlight = 'catppuccin-mocha'
        full_screen_fg = $special.foreground
        full_screen_bg = $special.background
        gradient_color = @($colors.color4, $colors.color5)
        file_panel_fg = $special.foreground
        file_panel_bg = $special.background
        file_panel_border = $special.surface
        file_panel_border_active = $colors.color4
        file_panel_top_directory_icon = $colors.color2
        file_panel_top_path = $colors.color4
        file_panel_item_selected_fg = $special.background
        file_panel_item_selected_bg = $colors.color4
        footer_fg = $special.foreground
        footer_bg = $special.mantle
        footer_border = $special.surface
        footer_border_active = $colors.color4
        sidebar_fg = $special.foreground
        sidebar_bg = $special.mantle
        sidebar_title = $colors.color4
        sidebar_border = $special.mantle
        sidebar_border_active = $colors.color4
        sidebar_item_selected_fg = $special.background
        sidebar_item_selected_bg = $colors.color4
        sidebar_divider = $special.surface
        modal_fg = $special.foreground
        modal_bg = $special.surface
        modal_border_active = $colors.color4
        modal_cancel_fg = $special.background
        modal_cancel_bg = $colors.color1
        modal_confirm_fg = $special.background
        modal_confirm_bg = $colors.color4
        help_menu_hotkey = $colors.color4
        help_menu_title = $colors.color5
        cursor = $special.cursor
        correct = $colors.color2
        error = $colors.color1
        hint = $colors.color4
        cancel = $colors.color3
    }

    $themeLines = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $themeValues.Keys) {
        $value = $themeValues[$name]
        if ($name -eq 'gradient_color') {
            $value = '[' + (($value | ForEach-Object { '"' + $_ + '"' }) -join ', ') + ']'
        } else {
            $value = '"' + [string]$value + '"'
        }
        $themeLines.Add("$name = $value")
    }
    $themeContent = ($themeLines -join "`r`n") + "`r`n"

    $configLines = [System.Collections.Generic.List[string]]::new()
    if (Test-Path -LiteralPath $script:SuperfileConfigPath) {
        foreach ($line in [System.IO.File]::ReadAllLines($script:SuperfileConfigPath)) {
            $configLines.Add($line)
        }
    }

    $themeSettings = @(
        for ($index = 0; $index -lt $configLines.Count; $index++) {
            if ($configLines[$index] -match '^\s*theme\s*=') {
                $index
            }
        }
    )
    if ($themeSettings.Count -gt 1) {
        throw "Expected at most one theme setting in Superfile config; found $($themeSettings.Count)."
    } elseif ($themeSettings.Count -eq 1) {
        $configLines[$themeSettings[0]] = [regex]::Replace(
            $configLines[$themeSettings[0]],
            '^(\s*theme\s*=\s*).*$',
            '$1"matugen"'
        )
    } else {
        $configLines.Add('theme = "matugen"')
    }

    $configContent = ($configLines -join "`r`n") + "`r`n"
    Write-AtomicText -Path $script:SuperfileThemePath -Content $themeContent | Out-Null
    Write-AtomicText -Path $script:SuperfileConfigPath -Content $configContent | Out-Null
}

function Set-TerminalPalette {
    param([Parameter(Mandatory)]$Palette)

    if (-not (Test-Path -LiteralPath $script:TerminalSettingsPath)) {
        Write-ThemeLog "Windows Terminal settings not found; skipped: $script:TerminalSettingsPath"
        return
    }

    $settingsText = [System.IO.File]::ReadAllText($script:TerminalSettingsPath)
    try {
        $settings = $settingsText | ConvertFrom-Json
    } catch {
        throw "Could not parse Windows Terminal settings: $($_.Exception.Message)"
    }

    $colors = $Palette.colors
    $scheme = [ordered]@{
        name = 'Wallpaper Theme'
        background = $Palette.special.background
        foreground = $Palette.special.foreground
        cursorColor = $Palette.special.cursor
        selectionBackground = $colors.color8
        black = $colors.color0
        red = $colors.color1
        green = $colors.color2
        yellow = $colors.color3
        blue = $colors.color4
        purple = $colors.color5
        cyan = $colors.color6
        white = $colors.color7
        brightBlack = $colors.color8
        brightRed = $colors.color9
        brightGreen = $colors.color10
        brightYellow = $colors.color11
        brightBlue = $colors.color12
        brightPurple = $colors.color13
        brightCyan = $colors.color14
        brightWhite = $colors.color15
    }

    if (-not $settings.profiles.defaults) {
        throw 'Windows Terminal settings are missing profiles.defaults.'
    }
    if (-not $settings.profiles.list) {
        throw 'Windows Terminal settings are missing profiles.list.'
    }

    $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'colorScheme' -Value 'Wallpaper Theme' -Force
    $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'useAcrylic' -Value $true -Force
    $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'acrylicOpacity' -Value 0.85 -Force
    foreach ($profile in $settings.profiles.list) {
        $profile | Add-Member -MemberType NoteProperty -Name 'colorScheme' -Value 'Wallpaper Theme' -Force
        $profile | Add-Member -MemberType NoteProperty -Name 'useAcrylic' -Value $true -Force
        $profile | Add-Member -MemberType NoteProperty -Name 'acrylicOpacity' -Value 0.85 -Force
    }

    $settings.schemes = @(
        @($settings.schemes | Where-Object { $_.name -ne 'Wallpaper Theme' })
        [pscustomobject]$scheme
    )
    $updatedText = ($settings | ConvertTo-Json -Depth 100) + "`r`n"
    if ($settingsText -cne $updatedText -and
        -not (Test-Path -LiteralPath "$($script:TerminalSettingsPath).before-wallpaper-theme")) {
        [System.IO.File]::Copy($script:TerminalSettingsPath, "$($script:TerminalSettingsPath).before-wallpaper-theme")
    }

    Write-AtomicText -Path $script:TerminalSettingsPath -Content $updatedText | Out-Null
}

function Set-VencordPalette {
    param([Parameter(Mandatory)]$Palette)

    if (-not (Test-Path -LiteralPath $script:VencordQuickCssPath)) {
        Write-ThemeLog "Vencord QuickCSS not found; skipped: $script:VencordQuickCssPath"
        return
    }

    $colors = $Palette.colors
    $variables = [ordered]@{
        '--text-0' = $Palette.special.background
        '--text-1' = $Palette.special.foreground
        '--text-2' = $colors.color7
        '--text-3' = $colors.color7
        '--text-4' = $colors.color8
        '--text-5' = $colors.color8
        '--bg-1' = $Palette.special.surface_raised
        '--bg-2' = $Palette.special.surface
        '--bg-3' = $Palette.special.background
        '--bg-4' = $Palette.special.crust
        '--accent-1' = $colors.color4
        '--accent-2' = $colors.color12
        '--accent-3' = $colors.color6
        '--accent-4' = $colors.color4
        '--accent-5' = $colors.color5
        '--accent-new' = $colors.color4
        '--online' = $colors.color2
        '--dnd' = $colors.color1
        '--idle' = $colors.color3
        '--streaming' = $colors.color5
        '--offline' = $colors.color8
    }
    foreach ($group in @(
        @{ Name = 'red'; Color = $colors.color1 },
        @{ Name = 'green'; Color = $colors.color2 },
        @{ Name = 'blue'; Color = $colors.color4 },
        @{ Name = 'yellow'; Color = $colors.color3 },
        @{ Name = 'purple'; Color = $colors.color5 }
    )) {
        foreach ($index in 1..5) {
            $variables["--$($group.Name)-$index"] = $group.Color
        }
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('/* Managed palette: do not edit this block by hand. */')
    $lines.Add(':root {')
    foreach ($name in $variables.Keys) {
        $lines.Add("    ${name}: $($variables[$name]);")
    }
    $lines.Add('}')
    $block = [string]::Join("`r`n", $lines)
    $begin = '/* BEGIN wallpaper theme palette */'
    $end = '/* END wallpaper theme palette */'
    $block = "$begin`r`n$block`r`n$end"

    $content = [System.IO.File]::ReadAllText($script:VencordQuickCssPath)
    $pattern = '(?s)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end)
    if ([regex]::IsMatch($content, $pattern)) {
        $content = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{
            param($match)
            return $block
        })
    } else {
        $content = $content.TrimEnd() + "`r`n`r`n$block`r`n"
    }

    Write-AtomicText -Path $script:VencordQuickCssPath -Content $content | Out-Null
}

function Set-VSCodePalette {
    param([Parameter(Mandatory)]$Palette)

    if (-not (Test-Path -LiteralPath $script:VSCodeSettingsPath)) {
        Write-ThemeLog "VS Code settings not found; skipped: $script:VSCodeSettingsPath"
        return
    }

    $content = [System.IO.File]::ReadAllText($script:VSCodeSettingsPath)
    $colors = $Palette.colors
    $surfaceKeys = @(
        'sideBar.background', 'sideBarTitle.background', 'activityBar.background',
        'editor.background', 'tab.inactiveBackground', 'tab.unfocusedInactiveBackground',
        'editorStickyScroll.background', 'editorStickyScrollGutter.background',
        'sideBarStickyScroll.background', 'panelStickyScroll.background',
        'terminalStickyScroll.background'
    )
    $elevatedKeys = @(
        'inlineChat.background', 'editorWidget.background', 'editorHoverWidget.background',
        'editorSuggestWidget.background', 'notifications.background',
        'notificationCenterHeader.background', 'menu.background', 'quickInput.background'
    )
    $transparentKeys = @(
        'terminal.background', 'editorPane.background', 'editorGroupHeader.tabsBackground',
        'editorGroupHeader.noTabsBackground', 'breadcrumb.background',
        'editorGutter.background', 'panel.background', 'tab.activeBackground',
        'tab.unfocusedActiveBackground'
    )
    $colorMap = @{}
    foreach ($name in $surfaceKeys) { $colorMap[$name] = $Palette.special.surface }
    foreach ($name in $elevatedKeys) { $colorMap[$name] = $Palette.special.surface_raised }
    foreach ($name in $transparentKeys) { $colorMap[$name] = $Palette.special.background }
    $translucentKeys = @($surfaceKeys) + @($transparentKeys)

    foreach ($name in $colorMap.Keys) {
        $pattern = '(?<prefix>"' + [regex]::Escape($name) + '"\s*:\s*")(?<color>#[0-9a-fA-F]{6,8})(?<suffix>")'
        $regex = [regex]::new($pattern)
        $matches = $regex.Matches($content)
        if ($matches.Count -gt 1) {
            throw "VS Code setting '$name' occurs more than once; refusing to make an ambiguous edit."
        }

        if ($matches.Count -eq 1) {
            $existingColor = $matches[0].Groups['color'].Value
            $alpha = if ($name -in $translucentKeys) {
                'D9'
            } elseif ($existingColor.Length -eq 9) {
                $existingColor.Substring(7)
            } else {
                ''
            }
            $replacement = '$1' + [string]$colorMap[$name] + $alpha + '$3'
            $content = $regex.Replace($content, $replacement)
        }
    }

    Write-AtomicText -Path $script:VSCodeSettingsPath -Content $content | Out-Null
}

function Set-NilesoftThemeProperty {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string[]]$Lines,
        [Parameter(Mandatory)][string]$Scope,
        [Parameter(Mandatory)][string]$Property,
        [Parameter(Mandatory)][string]$Value
    )

    $scopeStack = [System.Collections.Generic.List[string]]::new()
    $matchingLineIndexes = [System.Collections.Generic.List[int]]::new()
    $pendingScope = $null
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        $trimmedLine = $Lines[$index].Trim()
        if (-not $trimmedLine -or $trimmedLine.StartsWith('//')) {
            continue
        }
        if ($trimmedLine -match '^(?<scope>[A-Za-z_][A-Za-z0-9_-]*)$') {
            $pendingScope = $Matches.scope
            continue
        }
        if ($trimmedLine -eq '{') {
            if (-not $pendingScope) {
                throw "Unexpected opening brace in Nilesoft theme: $script:NilesoftThemePath"
            }
            $scopeStack.Add($pendingScope)
            $pendingScope = $null
            continue
        }
        if ($trimmedLine -eq '}') {
            if ($scopeStack.Count -eq 0) {
                throw "Unexpected closing brace in Nilesoft theme: $script:NilesoftThemePath"
            }
            $scopeStack.RemoveAt($scopeStack.Count - 1)
            continue
        }

        $assignment = [regex]::Match($trimmedLine, '^(?<property>[A-Za-z_][A-Za-z0-9_-]*)\s*=')
        if ($assignment.Success -and
            ($scopeStack -join '.') -ceq $Scope -and
            $assignment.Groups['property'].Value -ceq $Property) {
            $matchingLineIndexes.Add($index)
        }
    }

    if ($scopeStack.Count -ne 0) {
        throw "Unbalanced braces in Nilesoft theme: $script:NilesoftThemePath"
    }
    if ($matchingLineIndexes.Count -ne 1) {
        throw "Expected one '$Property' property in Nilesoft theme scope '$Scope'; found $($matchingLineIndexes.Count): $script:NilesoftThemePath"
    }

    $lineIndex = $matchingLineIndexes[0]
    $linePattern = '^(?<prefix>\s*' + [regex]::Escape($Property) + '\s*=\s*)(?<value>.*?)(?<suffix>\s*(?://.*)?)$'
    $lineMatch = [regex]::Match($Lines[$lineIndex], $linePattern)
    if (-not $lineMatch.Success) {
        throw "Could not parse Nilesoft theme property '$Scope.$Property'."
    }

    $Lines[$lineIndex] = $lineMatch.Groups['prefix'].Value + $Value + $lineMatch.Groups['suffix'].Value
}

function Set-NilesoftPalette {
    param([Parameter(Mandatory)]$Palette)

    if (-not (Test-Path -LiteralPath $script:NilesoftThemePath -PathType Leaf)) {
        throw "Nilesoft Shell theme not found: $script:NilesoftThemePath"
    }

    $accent = Get-PaletteColor -Palette $Palette -Group 'colors' -Name 'color4'
    $foreground = Get-PaletteColor -Palette $Palette -Group 'special' -Name 'foreground'
    $subtext = Get-PaletteColor -Palette $Palette -Group 'special' -Name 'subtext'
    $settings = @(
        @{ Scope = 'theme.background'; Property = 'color'; Value = (Get-PaletteColor -Palette $Palette -Group 'special' -Name 'background') },
        @{ Scope = 'theme.item.text'; Property = 'normal'; Value = $foreground },
        @{ Scope = 'theme.item.text'; Property = 'select'; Value = $foreground },
        @{ Scope = 'theme.item.text'; Property = 'normal-disabled'; Value = "${subtext}7a" },
        @{ Scope = 'theme.item.text'; Property = 'select-disabled'; Value = "${foreground}7a" },
        @{ Scope = 'theme.item.back'; Property = 'select'; Value = "${accent}7a" },
        @{ Scope = 'theme.item.back'; Property = 'select-disabled'; Value = "${accent}2b" },
        @{ Scope = 'theme.border'; Property = 'color'; Value = "${accent}7a" },
        @{ Scope = 'theme.shadow'; Property = 'color'; Value = (Get-PaletteColor -Palette $Palette -Group 'special' -Name 'crust') },
        @{ Scope = 'theme.separator'; Property = 'color'; Value = (Get-PaletteColor -Palette $Palette -Group 'special' -Name 'surface') },
        @{ Scope = 'theme.symbol'; Property = 'normal'; Value = $accent },
        @{ Scope = 'theme.symbol'; Property = 'select'; Value = $foreground },
        @{ Scope = 'theme.symbol'; Property = 'normal-disabled'; Value = "${subtext}7a" },
        @{ Scope = 'theme.symbol'; Property = 'select-disabled'; Value = "${subtext}7a" },
        @{ Scope = 'theme.image'; Property = 'color'; Value = "[$accent, $accent, $accent]" }
    )
    $lines = [System.IO.File]::ReadAllLines($script:NilesoftThemePath)
    foreach ($setting in $settings) {
        Set-NilesoftThemeProperty -Lines $lines -Scope $setting.Scope -Property $setting.Property -Value $setting.Value
    }

    $content = [string]::Join("`r`n", $lines) + "`r`n"
    $originalContent = [System.IO.File]::ReadAllText($script:NilesoftThemePath)
    if ($content -ceq $originalContent) {
        return
    }

    try {
        [System.IO.File]::WriteAllText($script:NilesoftThemePath, $content, [System.Text.UTF8Encoding]::new($false))
    } catch {
        try {
            [System.IO.File]::WriteAllText(
                $script:NilesoftThemePath,
                $originalContent,
                [System.Text.UTF8Encoding]::new($false)
            )
        } catch {
            throw "Failed to update Nilesoft theme '$script:NilesoftThemePath' and could not restore its original contents: $($_.Exception.Message)"
        }
        throw
    }
}

function Sync-SystemTheme {
    param(
        [Parameter(Mandatory)]$Palette,
        [Parameter(Mandatory)][string]$ThemeName
    )

    $normalized = ConvertTo-ColorPaletteJson -Palette $Palette
    foreach ($name in @('mantle', 'crust', 'surface', 'surface_raised', 'subtext')) {
        Get-PaletteColor -Palette $Palette -Group 'special' -Name $name | Out-Null
    }

    Set-YasbPalette -Palette $Palette | Out-Null
    Set-BtopPalette -Palette $Palette
    Set-CavaPalette -Accent $normalized.colors.color4
    Set-SuperfilePalette -Palette $Palette
    Set-TerminalPalette -Palette $Palette
    Set-VencordPalette -Palette $Palette
    Set-VSCodePalette -Palette $Palette
    Set-NilesoftPalette -Palette $Palette
    Write-ThemeLog "Applied '$ThemeName' palette to YASB, btop, Cava, Superfile, Windows Terminal, Vencord, VS Code, and Nilesoft Shell."
    Write-Output "Applied theme: $ThemeName"
}

Export-ModuleMember -Function ConvertFrom-MatugenPalette, Sync-SystemTheme, Write-ThemeLog
