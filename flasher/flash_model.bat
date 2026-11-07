@echo off
REM Motorola Moto G Play 2026 (nevada, XT2615-3) flasher for build W1WNS36.18-111-7-2-2
REM Reproduces Motorola's official flashfile.xml sequence (Rescue and Smart Assistant).
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "PARTLIST=PGPT gpt preloader preloader lk tee mcupm pi_img sspm dtbo logo spmfw scp vbmeta vbmeta_system md1img dpm gz mcf_ota vcp connsys_bt efuse init_boot boot vendor_boot super"
set "SLOT=a"
set "MODE=full"
for %%A in (%*) do (
  if /i "%%A"=="--slot-b"  set "SLOT=b"
  if /i "%%A"=="--root"    set "MODE=root"
  if /i "%%A"=="--restore" set "MODE=root-restore"
  if /i "%%A"=="--keep-data" set "KEEPDATA=1"
  if /i "%%A"=="--yes"     set "AUTOYES=1"
)

echo ==================================================================
echo  Moto G Play 2026 (XT2615-3, nevada)  build W1WNS36.18-111-7-2-2
echo  Mode: %MODE%    target slot: %SLOT%
echo ==================================================================
echo.

if "%MODE%"=="full" goto full

REM ---------- root / restore-slot mode: work directly in this folder ----------
set "ROM=%~dp0"
for %%F in (init_boot_stock_111-7-2-2.img boot_stock_111-7-2-2.img init_boot_patched_v31.1_W1WNS36.18-111-7-2-2.img) do (
  if not exist "!ROM!%%F" (
    echo MISSING: %%F   ^(copy it next to this script^)
    goto fail
  )
)
goto rootmode

:full
REM ---------- full firmware mode: find the ROM folder ----------
set "ROM="
if exist "rom\flashfile.xml" set "ROM=rom\"
if not defined ROM if exist "flashfile.xml" set "ROM=.\"
if not defined ROM for /d %%D in (.\..\*) do (
  if exist "%%D\flashfile.xml" if exist "%%D\super.img_sparsechunk.0" set "ROM=%%D\"
)
if not defined ROM (
  echo Put the RSA firmware folder here as "rom" ^(it must contain flashfile.xml,
  echo PGPT and super.img_sparsechunk.0..26^), then run again.
  goto fail
)
findstr /c:"W1WNS36.18-111-7-2-2" "%ROM%flashfile.xml" >nul || (
  echo Firmware in %ROM% is NOT W1WNS36.18-111-7-2-2 - refusing to flash.
  goto fail
)
if not exist "%ROM%super.img_sparsechunk.26" (
  echo MISSING super.img_sparsechunk.26 - the firmware folder is incomplete.
  goto fail
)
echo Firmware: %ROM%
echo.
echo Before continuing: enable "OEM unlocking" in Developer options
echo (fastboot must report Device is UNLOCKED). Flashing wipes all data.
echo Press Ctrl+C to abort.
if not defined AUTOYES pause
goto device

:rootmode
echo Images: %ROM%
echo Data is NOT wiped. Only init_boot_%SLOT% and boot_%SLOT% are written.
echo Press Ctrl+C to abort.
if not defined AUTOYES pause

:device
fastboot devices
if errorlevel 1 goto fail
for /f "tokens=1*" %%I in ('fastboot devices') do set "SN=%%I"
if not defined SN (
  echo No fastboot device. Boot the phone into bootloader ^(Vol-Down + Power^).
  goto fail
)
set "FB=fastboot -s !SN!"
for /f "tokens=1,2 delims=:" %%A in ('!FB! getvar product 2^>^&1 ^| findstr /c:"product:"') do set "PROD=%%B"
set "PROD=!PROD: =!"
if defined PROD if /i not "!PROD!"=="nevada_g_sys" if /i not "!PROD!"=="nevada" (
  echo Connected device reports product "!PROD!", expected nevada_g_sys. Aborting.
  goto fail
)
echo Using device !SN!.
echo.

if "%MODE%"=="root" goto do_root
if "%MODE%"=="root-restore" goto do_restore

REM ---------- full flash: exact flashfile.xml order ----------
echo [1/4] Partitioning + bootloader chain (do not unplug)...
!FB! flash gpt "%ROM%PGPT"                                    || goto fail
!FB! oem fb_mode_set                                          || goto fail
!FB! flash preloader "%ROM%preloader.img"                     || goto fail
for %%P in (lk tee mcupm pi_img sspm dtbo logo spmfw scp vbmeta vbmeta_system md1img dpm gz mcf_ota vcp connsys_bt) do (
  !FB! flash %%P_%SLOT% "%ROM%%%P.img"                        || goto fail
)
!FB! flush                                                    || goto fail
echo.
echo [2/4] Erasing user partitions...
!FB! erase nvdata                                             || goto fail
echo.
echo [3/4] Flashing boot images and system (super)...
!FB! flash init_boot_%SLOT%  "%ROM%init_boot.img"             || goto fail
!FB! flash boot_%SLOT%       "%ROM%boot.img"                  || goto fail
!FB! flash vendor_boot_%SLOT% "%ROM%vendor_boot.img"          || goto fail
for /l %%N in (0,1,26) do (
  !FB! flash super "%ROM%super.img_sparsechunk.%%N"           || goto fail
)
echo.
echo [4/4] Cleaning up and rebooting...
!FB! erase userdata                                           || goto fail
!FB! erase metadata                                           || goto fail
!FB! erase debug_token                                        || goto fail
!FB! oem fb_mode_clear                                        || goto fail
!FB! oem config unset console                                 || goto fail
!FB! oem config unset cmdl                                    || goto fail
!FB! reboot
echo.
echo DONE - stock W1WNS36.18-111-7-2-2 restored and device rebooting.
goto end

:do_root
set "INIT=init_boot_patched_v31.1_W1WNS36.18-111-7-2-2.img"
echo Flashing root ^(Magisk 31.1 patched init_boot^) to slot %SLOT%...
goto root_common

:do_restore
set "INIT=init_boot_stock_111-7-2-2.img"
echo Restoring stock init_boot to slot %SLOT% ^(unroot^)...
:root_common
!FB! reboot-bootloader
ping -n 9 127.0.0.1 >nul
!FB! flash init_boot_%SLOT% "%ROM%%INIT%"                     || goto fail
!FB! flash boot_%SLOT%      "%ROM%boot_stock_111-7-2-2.img"   || goto fail
!FB! reboot
echo.
if /i "%MODE%"=="root" (echo DONE. Install Magisk-v31.1.apk on the phone.) else (echo DONE. Slot %SLOT% is back to stock.)
goto end

:end
echo.
echo Bootloader notes: on error "No such file or directory", re-enter the
echo bootloader ^(Vol-Down + Power^) and run again - this is a known Motorola
echo fastboot quirk, not a missing file.
if not defined AUTOYES pause
exit /b 0

:fail
echo.
echo *** STOPPED. Nothing further was flashed. ***
echo Phone state: bootloader. Re-run to continue, or if it will not boot,
echo re-run with the full firmware folder present to restore stock.
if not defined AUTOYES pause
exit /b 1
