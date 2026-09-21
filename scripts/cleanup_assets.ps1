<#
Cleanup script for removing unreferenced assets and build artifacts.
Run from the repository root in PowerShell:
  cd c:\seelai_app
  .\scripts\cleanup_assets.ps1

This script deletes specific unreferenced files and common build folders.
It prompts for confirmation before deleting.
#>

Write-Host "This script will delete selected unreferenced assets and build folders." -ForegroundColor Yellow
$confirm = Read-Host "Type YES to proceed"
if ($confirm -ne 'YES') {
  Write-Host "Aborted by user." -ForegroundColor Cyan
  exit 0
}

$filesToDelete = @(
  "assets\seelai-icons\seelai1.png",
  "assets\seelai-icons\seelai_models.gif",
  "assets\seelai-icons\seelai_loader.gif"
)

foreach ($f in $filesToDelete) {
  if (Test-Path $f) {
    Write-Host "Deleting $f" -ForegroundColor Green
    Remove-Item -Path $f -Force -ErrorAction SilentlyContinue
  } else {
    Write-Host "Not found: $f" -ForegroundColor DarkYellow
  }
}

$dirsToDelete = @(
  "build",
  "android\build",
  "android\app\build"
)

foreach ($d in $dirsToDelete) {
  if (Test-Path $d) {
    Write-Host "Removing folder $d" -ForegroundColor Green
    Remove-Item -Path $d -Recurse -Force -ErrorAction SilentlyContinue
  } else {
    Write-Host "Folder not found: $d" -ForegroundColor DarkYellow
  }
}

Write-Host "Cleanup finished." -ForegroundColor Cyan
