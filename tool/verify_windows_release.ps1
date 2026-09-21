param(
  [string]$ReleaseDir = "build/windows/x64/runner/Release",
  [int]$StartupSeconds = 8
)

$ErrorActionPreference = "Stop"

$exe = Join-Path $ReleaseDir "personal_workbench.exe"
$assets = Join-Path $ReleaseDir "data/flutter_assets"

Write-Host "Personal Workbench Windows Release Smoke"
Write-Host "Release directory: $ReleaseDir"

if (-not (Test-Path $exe -PathType Leaf)) {
  throw "Missing release executable: $exe"
}

if (-not (Test-Path $assets -PathType Container)) {
  throw "Missing Flutter assets directory: $assets"
}

$process = $null
try {
  $process = Start-Process -FilePath $exe -WorkingDirectory $ReleaseDir -PassThru
  Write-Host "Started PID $($process.Id). Waiting $StartupSeconds seconds..."

  Start-Sleep -Seconds $StartupSeconds
  $process.Refresh()

  if ($process.HasExited) {
    throw "personal_workbench.exe exited during startup smoke. Exit code: $($process.ExitCode)"
  }

  Write-Host "RESULT: PASS"
  Write-Host "personal_workbench.exe remained running through startup smoke."
}
finally {
  if ($null -ne $process) {
    try {
      $process.Refresh()
      if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
        Write-Host "Stopped smoke-test process PID $($process.Id)."
      }
    }
    catch {
      Write-Warning "Could not stop smoke-test process cleanly: $($_.Exception.Message)"
    }
  }
}
