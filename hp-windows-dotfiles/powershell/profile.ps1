$komorebiUpdates = Join-Path $HOME 'scoop\persist\komorebi-fork\Scoop-KomorebiUpdates.ps1'
if (Test-Path -LiteralPath $komorebiUpdates -PathType Leaf) {
    . $komorebiUpdates
}
