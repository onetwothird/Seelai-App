<#
Installs the repository Git hooks from `.githooks/` into `.git/hooks/`.
Run from repo root in PowerShell:
  .\scripts\install_git_hooks.ps1
#>
Write-Host "Installing Git hooks..."
$src = Join-Path (Get-Location) '.githooks\pre-commit'
$destDir = Join-Path (Get-Location) '.git\hooks'
if (-not (Test-Path $destDir)) { Write-Host ".git/hooks not found. Are you in a Git repo?"; exit 1 }
$dest = Join-Path $destDir 'pre-commit'
Copy-Item -Path $src -Destination $dest -Force
Write-Host "Installed pre-commit hook to $dest" -ForegroundColor Green
exit 0
