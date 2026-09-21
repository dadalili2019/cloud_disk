param(
  [switch]$IncludeScale,
  [switch]$IncludeAi,
  [int]$ScaleWorkspaces = 10,
  [int]$ScaleTasksPerWorkspace = 1000,
  [int]$ScaleNotesPerWorkspace = 200,
  [int]$ScaleNoteBodyBytes = 4096
)

$ErrorActionPreference = "Stop"

function Invoke-Step {
  param(
    [string]$Name,
    [scriptblock]$Action
  )

  Write-Host ""
  Write-Host "=== $Name ==="
  & $Action
  if ($LASTEXITCODE -ne 0) {
    throw "$Name failed with exit code $LASTEXITCODE."
  }
}

Write-Host "Personal Workbench Stable V1 Candidate Verification"
Write-Host "==================================================="

Invoke-Step "Flutter version" {
  flutter --version
}

Invoke-Step "Get dependencies" {
  flutter pub get
}

Invoke-Step "Analyze" {
  flutter analyze
}

Invoke-Step "Test" {
  flutter test
}

Invoke-Step "Scale verification smoke" {
  flutter test test/manual/workbench_scale_verification_test.dart --dart-define=WORKBENCH_SCALE_VERIFY=true --dart-define=WORKBENCH_SCALE_WORKSPACES=1 --dart-define=WORKBENCH_SCALE_TASKS_PER_WORKSPACE=10 --dart-define=WORKBENCH_SCALE_NOTES_PER_WORKSPACE=3 --dart-define=WORKBENCH_SCALE_NOTE_BODY_BYTES=512
}

if ($IncludeScale) {
  Invoke-Step "Scale verification" {
    flutter test test/manual/workbench_scale_verification_test.dart --dart-define=WORKBENCH_SCALE_VERIFY=true --dart-define=WORKBENCH_SCALE_WORKSPACES=$ScaleWorkspaces --dart-define=WORKBENCH_SCALE_TASKS_PER_WORKSPACE=$ScaleTasksPerWorkspace --dart-define=WORKBENCH_SCALE_NOTES_PER_WORKSPACE=$ScaleNotesPerWorkspace --dart-define=WORKBENCH_SCALE_NOTE_BODY_BYTES=$ScaleNoteBodyBytes
  }
}

Invoke-Step "Enable Windows desktop" {
  flutter config --enable-windows-desktop
}

Invoke-Step "Build Windows release" {
  flutter build windows --release
}

Invoke-Step "Windows release startup smoke" {
  powershell -ExecutionPolicy Bypass -File ./tool/verify_windows_release.ps1
}

if ($IncludeAi) {
  if ([string]::IsNullOrWhiteSpace($env:WORKBENCH_AI_BASE_URL) -or
      [string]::IsNullOrWhiteSpace($env:WORKBENCH_AI_MODEL)) {
    throw "AI verification requested, but WORKBENCH_AI_BASE_URL / WORKBENCH_AI_MODEL are not configured."
  }

  Invoke-Step "AI real-environment verification" {
    dart run tool/verify_ai_provider.dart --strict-ok
  }
}

Write-Host ""
Write-Host "RESULT: PASS"
Write-Host "Automated Stable V1 candidate verification passed."

if (-not $IncludeAi) {
  Write-Host "AI real-environment verification was not requested."
}

if (-not $IncludeScale) {
  Write-Host "Large synthetic scale verification was not requested."
}

Write-Host "Manual business-flow / upgrade smoke is still required before marking Desktop Stable V1."
