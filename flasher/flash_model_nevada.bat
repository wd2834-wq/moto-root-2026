@echo off
REM Minimal file loader: auto-detects platform-tools (fastboot.exe + AdbWinApi.dll) and runs flash_model.bat.
setlocal
cd /d "%~dp0"
set "HERE=%~dp0"

if exist "%HERE%fastboot.exe" goto run
if exist "%HERE%platform-tools\fastboot.exe" (
  set "PATH=%HERE%platform-tools;%PATH%"
  goto run
)
if defined ANDROID_HOME if exist "%ANDROID_HOME%\platform-tools\fastboot.exe" (
  set "PATH=%ANDROID_HOME%\platform-tools;%PATH%"
  goto run
)
if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\fastboot.exe" (
  set "PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools;%PATH%"
  goto run
)
echo fastboot.exe not found.
echo Unzip the official platform-tools into a "platform-tools" folder next to this script:
echo   https://dl.google.com/android/repository/platform-tools-latest-windows.zip
pause
exit /b 1

:run
call "%HERE%flash_model.bat" %*
