param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "stop", "restart")]
    [string]$Action
)

$ErrorActionPreference = "Stop"
$komorebiInstall = Join-Path $PSScriptRoot "komorebi-fork"
$daemon = Join-Path $komorebiInstall "komorebi.exe"
$cli = Join-Path $komorebiInstall "komorebic.exe"
$config = Join-Path $env:USERPROFILE "komorebi.json"

foreach ($path in @($daemon, $cli, $config)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required Komorebi file not found: $path"
    }
}

function Stop-Komorebi {
    $processes = @(Get-CimInstance Win32_Process -Filter "Name = 'komorebi.exe'")
    if ($processes.Count -gt 0) {
        & $cli stop
        if ($LASTEXITCODE -ne 0) {
            throw "Komorebi stop command failed with exit code $LASTEXITCODE"
        }

        $deadline = (Get-Date).AddSeconds(10)
        do {
            Start-Sleep -Milliseconds 200
            $processes = @(Get-CimInstance Win32_Process -Filter "Name = 'komorebi.exe'")
        } while ($processes.Count -gt 0 -and (Get-Date) -lt $deadline)

        if ($processes.Count -gt 0) {
            $remaining = ($processes | ForEach-Object { "$($_.ProcessId): $($_.ExecutablePath)" }) -join "; "
            throw "Komorebi processes did not stop: $remaining"
        }
    }
}

function Start-Komorebi {
    $existing = @(Get-CimInstance Win32_Process -Filter "Name = 'komorebi.exe'")
    if ($existing.Count -gt 0) {
        $running = ($existing | ForEach-Object { "$($_.ProcessId): $($_.ExecutablePath)" }) -join "; "
        throw "A Komorebi daemon is already running: $running"
    }

    $daemonPath = [System.IO.Path]::GetFullPath($daemon)
    $configPath = [System.IO.Path]::GetFullPath($config)
    $process = Start-Process -FilePath $daemonPath -ArgumentList "--config=`"$configPath`"" -WindowStyle Hidden -PassThru
    Start-Sleep -Seconds 3
    $running = Get-CimInstance Win32_Process -Filter "Name = 'komorebi.exe'" |
        Where-Object { $_.ExecutablePath -eq $daemonPath }
    if (-not $running) {
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id -ErrorAction SilentlyContinue
        }
        throw "Komorebi did not remain running; check its logs and configuration."
    }
}

switch ($Action) {
    "start" { Start-Komorebi }
    "stop" { Stop-Komorebi }
    "restart" {
        Stop-Komorebi
        Start-Komorebi
    }
}
