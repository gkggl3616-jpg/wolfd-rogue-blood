param([int]$Port = 8765)
$ErrorActionPreference = 'Stop'
$pythonCommand = (Get-Command python -ErrorAction Stop).Source
$projectDir = $PSScriptRoot
$listen = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if (-not $listen) {
    $serverScript = Join-Path $projectDir 'server.py'
    Start-Process -FilePath $pythonCommand -ArgumentList @('"' + $serverScript + '"', '--port', $Port) -WorkingDirectory $projectDir -WindowStyle Hidden
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        Start-Sleep -Milliseconds 200
        try { $state = Invoke-RestMethod -Uri "http://localhost:$Port/api/state"; if ($state.mode -eq 'local-development') { break } } catch { }
    }
}
try {
    $state = Invoke-RestMethod -Uri "http://localhost:$Port/api/state"
    if ($state.mode -ne 'local-development') { throw 'Port başka bir uygulama tarafından kullanılıyor.' }
} catch { throw 'Panel başlatılamadı. Başka bir port deneyin: .\start.ps1 -Port 8766' }
$chromePaths = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe")
$chromePath = $chromePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($chromePath) { Start-Process -FilePath $chromePath -ArgumentList "http://localhost:$Port" -WindowStyle Normal }
else { Start-Process "http://localhost:$Port" }
Write-Output "Wolf Rogue Blood açıldı: http://localhost:$Port"
