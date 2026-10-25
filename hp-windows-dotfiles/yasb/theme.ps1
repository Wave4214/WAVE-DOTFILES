param(
    [Parameter(Position = 0)]
    [string]$Name = 'wallpaper'
)

$ErrorActionPreference = 'Stop'

$themePalettes = [ordered]@{
    'Catppuccin Latte' = @('#eff1f5', '#ccd0da', '#7c7f93', '#4c4f69', '#eff1f5', '#bcc0cc', '#e6e9ef', '#ccd0da', '#d20f39', '#6c6f85')
    'Catppuccin Frappé' = @('#303446', '#414559', '#949cbb', '#c6d0f5', '#414559', '#51576d', '#292c3c', '#414559', '#e78284', '#a5adce')
    'Catppuccin Macchiato' = @('#24273a', '#363a4f', '#939ab7', '#cad3f5', '#363a4f', '#494d64', '#1e2030', '#363a4f', '#ed8796', '#a5adcb')
    'Catppuccin Mocha' = @('#1e1e2e', '#313244', '#9399b2', '#cdd6f4', '#313244', '#45475a', '#181825', '#313244', '#f38ba8', '#a6adc8')
    'Gruvbox Material Dark Soft' = @('#32302F', '#45403D', '#DDC7A1', '#DDC7A1', '#32302F', '#5A524C', '#252423', '#3C3836', '#ea6962', '#928374')
    'Your Lie In April' = @('#223343', '#314d6b', '#657c9f', '#b7c2e9', '#b7c2e9', '#657c9f', '#a9abc0', '#314d6b', '#7b7193', '#a5adcb')
    'Sousou no Frieren' = @('#d4ddd0', '#A1B99C', '#6d9471', '#1d2837', '#e3eadf', '#6d9471', '#e3eadf', '#A1B99C', '#6B8276', '#2B4E55')
    'Everforest Dark Soft' = @('#48584E', '#5D6B66', '#D3C6AA', '#D3C6AA', '#48584E', '#7A8478', '#5D6B66', '#5D6B66', '#E59875', '#9AA79D')
    'Monochrome' = @('#18181b', '#3f3f42', '#b2b2b2', '#e5e7eb', '#18181b', '#7a7c7d', '#3f3f42', '#3f3f42', '#e5e7eb', '#b2b2b2')
    'Tokyo Night' = @('#1a1b26', '#414868', '#9aa5ce', '#c0caf5', '#1a1b26', '#565f89', '#414868', '#414868', '#f7768e', '#9aa5ce')
    'Monochrome Light' = @('#e5e7eb', '#a4a4a4', '#2f2f36', '#18181b', '#e5e7eb', '#919090', '#a4a4a4', '#a4a4a4', '#18181b', '#4B565C')
    'Monochrome Accent Dark' = @('#18181b', '#3f3f42', '@yasb-accent', '#e5e7eb', '#18181b', '@yasb-accent', '#3f3f42', '#3f3f42', '#e5e7eb', '#E5E7EB')
    'Onyx' = @('#0A0A0B', '#141416', '@yasb-accent-light2', '#F2F2F3', '#0A0A0B', '@yasb-accent', '#1C1C1F', '#29292D', '#F2F2F3', '#A6A6AA')
    'Onyx OLED' = @('#000000', '#0A0A0A', '@yasb-accent-light2', '#F5F5F5', '#000000', '@yasb-accent', '#111111', '#1D1D1D', '#F5F5F5', '#8C8C8C')
    'MonochromeAccentLight' = @('#e5e7eb', '#a4a4a4', '@yasb-accent-dark2', '#18181b', '#e5e7eb', '@yasb-accent-light1', '#a4a4a4', '#a4a4a4', '#18181b', '#4B565C')
    'Everforest Dark' = @('#2E383C', '#374145', '#D3C6AA', '#D3C6AA', '#2E383C', '#414B50', '#272E33', '#374145', '#E59875', '#859289')
    'Nord' = @('#2e3440', '#434c5e', '#ebcb8b', '#d8dee9', '#2e3440', '#4c566a', '#3b4252', '#434c5e', '#bf616a', '#bdc2cd')
    'Kanagawa' = @('#1F1F28', '#727169', '#C8C093', '#DCD7BA', '#1F1F28', '#76946A', '#090618', '#C0A36E', '#C34043', '#C8C093')
    'Katsushika Hokusai x Miku' = @('#F0E4cc', '#c0c0a8', '#486C90', '#182430', '#F0E4cc', '#818f9a', '#b49c84', '#182430', '#603c48', '#4B565C')
}

$availableThemes = @($themePalettes.Keys) + @('Matugen')
$selectedName = $Name.Trim()

if ($selectedName -ieq 'list') {
    $availableThemes
    return
}

if ($selectedName -ieq 'wallpaper' -or $selectedName -ieq 'matugen' -or $selectedName -ieq 'pywal') {
    if ($selectedName -ieq 'pywal') {
        Write-Warning 'Pywal theme selection is deprecated; using Matugen instead.'
    }
    & (Join-Path $PSScriptRoot 'wallpaper-watcher.ps1') sync
    return
}

if ($selectedName -ieq 'catppuccin-mocha') {
    $selectedName = 'Catppuccin Mocha'
} elseif ($selectedName -ieq 'gruvbox-dark') {
    $selectedName = 'Gruvbox Material Dark Soft'
} elseif ($selectedName -ieq 'catppuccin frappe') {
    $selectedName = 'Catppuccin Frappé'
} elseif ($selectedName -ieq 'monochrome accent light') {
    $selectedName = 'MonochromeAccentLight'
} elseif ($selectedName -ieq 'kanagawa wave') {
    $selectedName = 'Kanagawa'
}

$themeName = $themePalettes.Keys | Where-Object { $_ -ieq $selectedName } | Select-Object -First 1
if (-not $themeName) {
    throw "Unknown theme '$Name'. Available themes: $($availableThemes -join ', '), wallpaper"
}

function Resolve-ThemeColor {
    param([Parameter(Mandatory)][string]$Color)

    if ($Color -notmatch '^@yasb-(?<name>accent(?:-dark2|-light1|-light2)?)$') {
        return $Color
    }

    $accentPath = Join-Path $PSScriptRoot 'yasb_colors.css'
    if (-not (Test-Path -LiteralPath $accentPath)) {
        throw "YASB accent colors were not found: $accentPath"
    }

    $accentName = $Matches.name
    $accentCssName = "--yasb-$accentName"
    $content = [System.IO.File]::ReadAllText($accentPath)
    $match = [regex]::Match($content, [regex]::Escape($accentCssName) + ':\s*rgb\(\s*(?<red>\d+)\s*,\s*(?<green>\d+)\s*,\s*(?<blue>\d+)\s*\)')
    if (-not $match.Success) {
        throw "Could not find a valid $accentCssName color in $accentPath"
    }

    $channels = @($match.Groups['red'].Value, $match.Groups['green'].Value, $match.Groups['blue'].Value)
    foreach ($channel in $channels) {
        if ([int]$channel -gt 255) {
            throw "Invalid $accentCssName color channel: $channel"
        }
    }

    return '#{0:X2}{1:X2}{2:X2}' -f [int]$channels[0], [int]$channels[1], [int]$channels[2]
}

$values = @($themePalettes[$themeName] | ForEach-Object { Resolve-ThemeColor -Color $_ })
$roles = [ordered]@{
    background = $values[0]
    background2 = $values[1]
    accent = $values[2]
    text = $values[3]
    accentText = $values[4]
    hover = $values[5]
    mutedBG = $values[6]
    border = $values[7]
    redFlash = $values[8]
    subtext = $values[9]
}

$special = [pscustomobject][ordered]@{
    background = $roles.background
    foreground = $roles.text
    cursor = $roles.accent
    mantle = $roles.background2
    crust = $roles.mutedBG
    surface = $roles.background2
    surface_raised = $roles.hover
    subtext = $roles.subtext
}
$colors = [pscustomobject][ordered]@{
    color0 = $roles.background
    color1 = $roles.redFlash
    color2 = $roles.accent
    color3 = $roles.hover
    color4 = $roles.accent
    color5 = $roles.accentText
    color6 = $roles.subtext
    color7 = $roles.text
    color8 = $roles.background2
    color9 = $roles.redFlash
    color10 = $roles.accent
    color11 = $roles.hover
    color12 = $roles.accent
    color13 = $roles.accentText
    color14 = $roles.subtext
    color15 = $roles.text
}

Import-Module (Join-Path $PSScriptRoot 'theme-sync.psm1') -Force
Sync-SystemTheme -Palette ([pscustomobject]@{ special = $special; colors = $colors }) -ThemeName $themeName
