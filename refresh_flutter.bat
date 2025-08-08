@echo off
setlocal enabledelayedexpansion
title Flutter: clean -> get -> run

:: 1) 切到脚本所在目录（不管从哪儿双击，都能回到项目根）
cd /d %~dp0

:: 2) 可选：指定设备（windows / chrome / android 等）
set DEVICE=windows
if not "%1"=="" set DEVICE=%1

echo.
echo ================== KILL OLD APP ==================
:: 可选：把 cloud_disk.exe 换成你实际的可执行名
taskkill /IM cloud_disk.exe /F >nul 2>&1

echo.
echo ================== FLUTTER CLEAN ==================
flutter clean
if errorlevel 1 (
  echo [X] flutter clean 失败
  pause
  exit /b 1
)

echo.
echo ================== PUB GET ==================
flutter pub get
if errorlevel 1 (
  echo [X] flutter pub get 失败
  pause
  exit /b 1
)

echo.
echo ================== RUN (%DEVICE%) ==================
flutter run -d %DEVICE%
echo.
pause
