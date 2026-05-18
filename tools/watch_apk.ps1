$yurukRoot = Split-Path $PSScriptRoot -Parent
$outDir = Join-Path $yurukRoot "build\app\outputs\flutter-apk"
$names = @(
  "app-arm64-v8a-release.apk",
  "app-release.apk",
  "app-armeabi-v7a-release.apk"
)

Write-Host "Her 30 sn APK kontrolu. Cikis: Ctrl+C"
Write-Host "Klasor: $outDir"
Write-Host ""

while ($true) {
  $t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  if (-not (Test-Path $outDir)) {
    Write-Host "[$t] flutter-apk klasoru yok (derleme baslamamis/basarisiz olabilir)."
    Start-Sleep -Seconds 30
    continue
  }
  $found = $false
  foreach ($n in $names) {
    $p = Join-Path $outDir $n
    if (Test-Path $p) {
      $len = (Get-Item $p).Length
      Write-Host "[$t] TAMAM: $n ($([math]::Round($len/1MB, 2)) MB)"
      Write-Host "  $p"
      $found = $true
    }
  }
  if ($found) { break }
  Write-Host "[$t] APK yok, 30 sn sonra tekrar..."
  Start-Sleep -Seconds 30
}
