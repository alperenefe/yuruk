# Kod push; isteğe bağlı Firebase APK dağıtımı (GitHub Actions UI gerekmez).
#
#   .\scripts\git-push.ps1           → sadece git push (APK yok)
#   .\scripts\git-push.ps1 -Deploy   → push + workflow tetikle
#
# Alternatif: commit mesajına [apk] veya [dagit] yaz → normal git push yeter.

param(
    [switch]$Deploy
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$branch = git branch --show-current
if (-not $branch) { throw "Git branch bulunamadi." }

Write-Host ">>> git push origin $branch"
git push origin $branch

if ($Deploy) {
    Write-Host ">>> Firebase: Android Firebase Distribute"
    gh workflow run "Android Firebase Distribute" --ref $branch
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "Workflow baslatildi. Son durum:"
    gh run list --workflow="Android Firebase Distribute" -L 1
} else {
    Write-Host ""
    Write-Host "Sadece kod push edildi (APK dagitimi YOK)."
    Write-Host "  APK icin:  .\scripts\git-push.ps1 -Deploy"
    Write-Host "  veya:      git commit -m 'aciklama [apk]'  sonra normal push"
}
