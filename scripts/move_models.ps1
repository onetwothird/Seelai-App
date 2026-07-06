<#
Moves model binaries into `assets/models/` and removes the old folders.
Run from repository root in PowerShell.
This only moves files; it will not change code (code references were already updated).
#>

Write-Host "Preparing to move model files to assets/models/" -ForegroundColor Yellow
$confirm = Read-Host "Type YES to proceed"
if ($confirm -ne 'YES') { Write-Host "Aborted by user."; exit 0 }

$dest = "assets\models"
if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }

$items = @(
  @{src="assets\object_model\object_detection.tflite"; dest="object_detection.tflite"},
  @{src="assets\object_model\labels.txt"; dest="object_labels.txt"},
  @{src="assets\face_model\face_detection.tflite"; dest="face_detection.tflite"},
  @{src="assets\face_model\labels.txt"; dest="face_labels.txt"}
)

foreach ($it in $items) {
  if (Test-Path $it.src) {
    $target = Join-Path $dest $it.dest
    Write-Host "Moving $($it.src) -> $target" -ForegroundColor Green
    Move-Item $it.src $target -Force
  } else {
    Write-Host "Source not found: $($it.src)" -ForegroundColor DarkYellow
  }
}

# Remove empty source directories if empty
foreach ($d in @('assets\object_model','assets\face_model')) {
  if (Test-Path $d) {
    $children = Get-ChildItem -Path $d -Force -ErrorAction SilentlyContinue
    if ($children.Count -eq 0) {
      Write-Host "Removing empty folder $d" -ForegroundColor Green
      Remove-Item -Path $d -Force -Recurse
    } else {
      Write-Host "Folder not empty (skipping removal): $d" -ForegroundColor DarkYellow
    }
  }
}

Write-Host "Model move complete." -ForegroundColor Cyan
