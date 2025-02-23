@echo off
setlocal enabledelayedexpansion

title Xiaomi TV Box S Firmware Update and Reset

:: Set variables for version and paths
set "FIRMWARE_VERSION=RTT0.211222.001.773"
set "DEVICE_ID=06-00-00-10-00-00-00-00"
set "TOOL_PATH=%~dp0bin\adnl"
set "IMAGE_PATH=%~dp0images"

:: Display header
echo ===============================================
echo Xiaomi TV Box S 2nd Gen Firmware Update Tool
echo Firmware Version: %FIRMWARE_VERSION%
echo ===============================================
echo.

:: Check device connection
echo Checking device connection...
"%TOOL_PATH%" devices >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Device not found
    echo Please ensure device is properly connected
    goto :error
)

:: Wait for device and verify identity
echo Please power on the device...
echo Waiting for device response...
"%TOOL_PATH%" getvar identify 2>&1 | find "%DEVICE_ID%" >nul
if %errorlevel% neq 0 (
    echo Error: Device identification failed
    goto :error
)

echo Device successfully identified
echo.

:: Initialize disk
echo Initializing device storage...
"%TOOL_PATH%" oem disk_initial
if %errorlevel% neq 0 goto :error

:: Automatically detect image files with partial matching
echo Searching for firmware images in %IMAGE_PATH%...
for %%F in ("%IMAGE_PATH%\*.img") do (
    set "FNAME=%%~nF"
    if "!FNAME:dtbo=!" neq "!FNAME!" set "DTBO_IMG=%%F"
    if "!FNAME:oem=!" neq "!FNAME!" set "OEM_IMG=%%F"
    if "!FNAME:odm_ext=!" neq "!FNAME!" set "ODM_EXT_IMG=%%F"
    if "!FNAME:vbmeta=!" neq "!FNAME!" if "!FNAME:vbmeta_system=!" equ "!FNAME!" set "VBMETA_IMG=%%F"
    if "!FNAME:vbmeta_system=!" neq "!FNAME!" set "VBMETA_SYSTEM_IMG=%%F"
    if "!FNAME:vendor_boot=!" neq "!FNAME!" set "VENDOR_BOOT_IMG=%%F"
    if "!FNAME:boot=!" neq "!FNAME!" set "BOOT_IMG=%%F"
    if "!FNAME:super=!" neq "!FNAME!" set "SUPER_IMG=%%F"
)

:: Verify required images were found
if not defined DTBO_IMG (echo Error: dtbo image not found & goto :error)
if not defined OEM_IMG (echo Error: oem image not found & goto :error)
if not defined ODM_EXT_IMG (echo Error: odm_ext image not found & goto :error)
if not defined VBMETA_IMG (echo Error: vbmeta image not found & goto :error)
if not defined VBMETA_SYSTEM_IMG (echo Error: vbmeta_system image not found & goto :error)
if not defined VENDOR_BOOT_IMG (echo Error: vendor_boot image not found & goto :error)
if not defined BOOT_IMG (echo Error: boot image not found & goto :error)
if not defined SUPER_IMG (echo Error: super image not found & goto :error)

echo Found all required images:
echo DTBO: %DTBO_IMG%
echo OEM: %OEM_IMG%
echo ODM_EXT: %ODM_EXT_IMG%
echo VBMETA: %VBMETA_IMG%
echo VBMETA_SYSTEM: %VBMETA_SYSTEM_IMG%
echo VENDOR_BOOT: %VENDOR_BOOT_IMG%
echo BOOT: %BOOT_IMG%
echo SUPER: %SUPER_IMG%
echo.

:: Flash firmware partitions
echo Flashing dtbo partitions...
"%TOOL_PATH%" partition -p dtbo_a -f "%DTBO_IMG%"
if %errorlevel% neq 0 goto :error
"%TOOL_PATH%" partition -p dtbo_b -f "%DTBO_IMG%"
if %errorlevel% neq 0 goto :error

echo Flashing oem partitions...
"%TOOL_PATH%" partition -p oem_a -f "%OEM_IMG%"
if %errorlevel% neq 0 goto :error
"%TOOL_PATH%" partition -p oem_b -f "%OEM_IMG%"
if %errorlevel% neq 0 goto :error

echo Flashing odm_ext partitions...
"%TOOL_PATH%" partition -p odm_ext_a -f "%ODM_EXT_IMG%"
if %errorlevel% neq 0 goto :error
"%TOOL_PATH%" partition -p odm_ext_b -f "%ODM_EXT_IMG%"
if %errorlevel% neq 0 goto :error

echo Flashing vbmeta partitions...
"%TOOL_PATH%" partition -p vbmeta_a -f "%VBMETA_IMG%"
if %errorlevel% neq 0 goto :error
"%TOOL_PATH%" partition -p vbmeta_b -f "%VBMETA_IMG%"
if %errorlevel% neq 0 goto :error

echo Flashing vbmeta_system partitions...
"%TOOL_PATH%" partition -p vbmeta_system_a -f "%VBMETA_SYSTEM_IMG%"
if %errorlevel% neq 0 goto :error
"%TOOL_PATH%" partition -p vbmeta_system_b -f "%VBMETA_SYSTEM_IMG%"
if %errorlevel% neq 0 goto :error

echo Flashing vendor_boot partitions...
"%TOOL_PATH%" partition -p vendor_boot_a -f "%VENDOR_BOOT_IMG%"
if %errorlevel% neq 0 goto :error
"%TOOL_PATH%" partition -p vendor_boot_b -f "%VENDOR_BOOT_IMG%"
if %errorlevel% neq 0 goto :error

echo Flashing boot partitions...
"%TOOL_PATH%" partition -p boot_a -f "%BOOT_IMG%"
if %errorlevel% neq 0 goto :error
"%TOOL_PATH%" partition -p boot_b -f "%BOOT_IMG%"
if %errorlevel% neq 0 goto :error

echo Flashing super partition...
"%TOOL_PATH%" partition -p super -f "%SUPER_IMG%" -t sparse
if %errorlevel% neq 0 goto :error

:: Clear metadata partition (at the end)
echo Clearing metadata partition...
if not exist "%IMAGE_PATH%\zeroes.img" (
    echo Error: zeroes.img not found in %IMAGE_PATH%
    goto :error
)
"%TOOL_PATH%" partition -p metadata -f "%IMAGE_PATH%\zeroes.img"
if %errorlevel% neq 0 goto :error

echo.
echo All operations completed successfully!
goto :end

:error
echo.
echo An error occurred during the process
echo Please check the device connection and try again

:end
echo.
echo Press any key to exit...
pause >nul
exit /b