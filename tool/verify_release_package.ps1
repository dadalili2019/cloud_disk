param(
  [string]$ReleaseDir = "build/windows/x64/runner/Release",
  [switch]$WriteManifest = $true
)

$ErrorActionPreference = "Stop"

$requiredFiles = @(
  "personal_workbench.exe",
  "flutter_windows.dll",
  "data/icudtl.dat"
)

$requiredDirectories = @(
  "data/flutter_assets"
)

Write-Host "Personal Workbench Windows Release Package Verification"
Write-Host "Release directory: $ReleaseDir"

if (-not (Test-Path $ReleaseDir -PathType Container)) {
  throw "Missing release directory: $ReleaseDir"
}

foreach ($relativePath in $requiredFiles) {
  $fullPath = Join-Path $ReleaseDir $relativePath
  if (-not (Test-Path $fullPath -PathType Leaf)) {
    throw "Missing required release file: $relativePath"
  }
}

foreach ($relativePath in $requiredDirectories) {
  $fullPath = Join-Path $ReleaseDir $relativePath
  if (-not (Test-Path $fullPath -PathType Container)) {
    throw "Missing required release directory: $relativePath"
  }

  $child = Get-ChildItem -Path $fullPath -File -Recurse | Select-Object -First 1
  if ($null -eq $child) {
    throw "Required release directory is empty: $relativePath"
  }
}

$releaseFiles = Get-ChildItem -Path $ReleaseDir -File -Recurse |
  Where-Object { $_.Name -ne "release_manifest.sha256.txt" } |
  Sort-Object FullName

if ($releaseFiles.Count -eq 0) {
  throw "Release package contains no files."
}

$totalBytes = ($releaseFiles | Measure-Object -Property Length -Sum).Sum
Write-Host "Files: $($releaseFiles.Count)"
Write-Host "Total bytes: $totalBytes"

if ($WriteManifest) {
  $root = (Resolve-Path $ReleaseDir).Path
  $manifestPath = Join-Path $ReleaseDir "release_manifest.sha256.txt"

  $lines = foreach ($file in $releaseFiles) {
    $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $relative = $file.FullName.Substring($root.Length).TrimStart('\', '/').Replace('\', '/')
    "$hash  $relative"
  }

  $lines | Set-Content -Path $manifestPath -Encoding UTF8
  Write-Host "Manifest: $manifestPath"
}

Write-Host "RESULT: PASS"
