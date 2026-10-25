$Host.UI.RawUI.WindowTitle = ""

function matrix {

Push-Location "$HOME\Projects\rs-matrix"

cargo run --release

Pop-Location

}

function matrixjp {

matrix-rain -c green -k katakana

}

function y {

$tmp = (New-TemporaryFile).FullName

yazi.exe @args --cwd-file="$tmp"

$cwd = Get-Content -Path $tmp -Encoding UTF8

if ($cwd -and $cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {

    Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path

}

Remove-Item -Path $tmp

}

Set-Location $HOME

function spf {

& (Get-Command spf.exe -ErrorAction Stop).Source @args

}

function dc {

& "$env:LOCALAPPDATA\Discord\Update.exe" --processStart Discord.exe

}

function theme {

& "$HOME\.config\yasb\theme.ps1" @args

}

function ani-cli {

$git = Get-Command git.exe -CommandType Application -ErrorAction Stop
$gitRoot = Split-Path (Split-Path $git.Source)
$bash = Join-Path $gitRoot "bin\bash.exe"
$script = Join-Path $HOME "scoop\apps\ani-cli\current\ani-cli"

if (-not (Test-Path -LiteralPath $bash -PathType Leaf)) {
    throw "Git Bash was not found at '$bash'."
}

if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
    throw "ani-cli was not found at '$script'."
}

& $bash $script @args

}

Set-Alias -Name yz -Value y
Set-Alias -Name ff -Value fastfetch
Set-Alias -Name wf -Value winfetch
Set-Alias -Name ca -Value cava
Set-Alias -Name sf -Value spf
Set-Alias -Name ani -Value ani-cli

oh-my-posh init pwsh --config "$HOME\.config\ohmyposh.json" | Invoke-Expression
