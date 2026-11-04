param([string]$Godot = 'godot', [string]$OutputPath, [string]$AndroidSdk, [switch]$ValidateOnly)
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
    python tools/validate_mobile.py --godot $Godot
    if ($LASTEXITCODE -ne 0) { throw 'Mobil doğrulama başarısız; APK üretilmedi.' }
    if ($ValidateOnly) {
        Write-Output 'Mobil doğrulama geçti; ValidateOnly nedeniyle APK üretilmedi.'
        return
    }
    python tools/check_delivery.py
    if ($LASTEXITCODE -ne 0) { throw 'Kullanıcının tam sürüm teslim koşulları karşılanmadı; deneme APK yayımlanmaz.' }
    & $Godot --headless --path godot --export-debug Android $OutputPath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputPath)) { throw 'Android derlemesi tamamlanamadı.' }
    if (-not $AndroidSdk) { $AndroidSdk = $env:ANDROID_HOME }
    if (-not $AndroidSdk) { $AndroidSdk = $env:ANDROID_SDK_ROOT }
    if (-not $AndroidSdk) { throw 'APK bütünlük/imza kontrolü için -AndroidSdk yolu gerekli.' }
    python tools/verify_android_apk.py $OutputPath --sdk $AndroidSdk --package com.wolfrogue.blood --report ($OutputPath + '.validation.json')
    if ($LASTEXITCODE -ne 0) { throw 'APK bütünlük, kaynak, imza veya hizalama kontrolü başarısız; yayımlanmaz.' }
    Write-Output "APK hazır: $OutputPath"
} finally { Pop-Location }
