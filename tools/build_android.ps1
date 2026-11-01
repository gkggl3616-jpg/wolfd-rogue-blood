param([string]$Godot = 'godot', [string]$OutputPath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (-not $OutputPath) { $OutputPath = Join-Path (Split-Path $projectRoot -Parent) 'WolfRogueBlood-debug.apk' }
$engineCommand = Get-Command $Godot -ErrorAction SilentlyContinue
if (-not $engineCommand) {
    $candidate = Join-Path $env:USERPROFILE 'Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
    if (Test-Path -LiteralPath $candidate) { $Godot = $candidate } else { throw 'Godot yolu gerekli: -Godot C:\...\godot.exe' }
}
Push-Location $projectRoot
try {
    python tools/check_android_ready.py
    if ($LASTEXITCODE -ne 0) { throw 'Karakter veya proje doğrulaması başarısız.' }
    & $Godot --headless --path godot --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot içe aktarma başarısız.' }
    & $Godot --headless --path godot --fixed-fps 60 --script res://tests/smoke.gd
    if ($LASTEXITCODE -ne 0) { throw 'Oyun testi başarısız; APK üretilmedi.' }
    & $Godot --headless --path godot --export-debug Android $OutputPath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputPath)) { throw 'Android derlemesi tamamlanamadı.' }
    Write-Output "APK hazır: $OutputPath"
} finally { Pop-Location }
