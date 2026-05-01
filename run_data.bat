@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Usage:
rem   run_data.bat
rem   run_data.bat "E:\path\to\source.jpg"
rem Optional environment variables:
rem   ROOP_PYTHON     Explicit Python executable, e.g. E:\Project\roop-main\.venv\Scripts\python.exe
rem   ROOP_EXTRA_ARGS Extra CLI args passed through to run.py

set "ROOT_DIR=%~dp0"
set "DATA_DIR=%ROOT_DIR%data"
set "OUTPUT_DIR=%DATA_DIR%\output"
set "PYTHON_CMD="
set "SOURCE_FILE=%~1"
set "TARGET_COUNT=0"

cd /d "%ROOT_DIR%"

if not exist "%ROOT_DIR%run.py" (
    echo [ERROR] run.py not found in "%ROOT_DIR%".
    exit /b 1
)

if not exist "%DATA_DIR%" (
    echo [ERROR] data directory not found: "%DATA_DIR%".
    exit /b 1
)

if not defined SOURCE_FILE (
    for %%F in ("%DATA_DIR%\*.jpg" "%DATA_DIR%\*.jpeg" "%DATA_DIR%\*.png" "%DATA_DIR%\*.webp") do (
        if not defined SOURCE_FILE if exist "%%~fF" set "SOURCE_FILE=%%~fF"
    )
)

if not defined SOURCE_FILE (
    echo [ERROR] No source image found in "%DATA_DIR%".
    exit /b 1
)

if not exist "%SOURCE_FILE%" (
    echo [ERROR] Source image not found: "%SOURCE_FILE%".
    exit /b 1
)

if defined ROOP_PYTHON (
    set "PYTHON_CMD=%ROOP_PYTHON%"
) else if exist "%ROOT_DIR%.venv\Scripts\python.exe" (
    set "PYTHON_CMD=%ROOT_DIR%.venv\Scripts\python.exe"
) else (
    where py >nul 2>nul
    if not errorlevel 1 (
        set "PYTHON_CMD=py"
    ) else (
        where python >nul 2>nul
        if not errorlevel 1 (
            set "PYTHON_CMD=python"
        )
    )
)

if not defined PYTHON_CMD (
    echo [ERROR] Python executable not found. Set ROOP_PYTHON or create .venv.
    exit /b 1
)

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ffmpeg not found in PATH.
    exit /b 1
)

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo [INFO] Source : "%SOURCE_FILE%"
echo [INFO] Output : "%OUTPUT_DIR%"
if defined ROOP_EXTRA_ARGS echo [INFO] Extra  : %ROOP_EXTRA_ARGS%

for %%F in ("%DATA_DIR%\*.mp4" "%DATA_DIR%\*.mov" "%DATA_DIR%\*.avi" "%DATA_DIR%\*.mkv" "%DATA_DIR%\*.webm") do (
    if exist "%%~fF" (
        set /a TARGET_COUNT+=1
        echo [INFO] Processing %%~nxF ...
        call "%PYTHON_CMD%" "%ROOT_DIR%run.py" -s "%SOURCE_FILE%" -t "%%~fF" -o "%OUTPUT_DIR%" --execution-provider cpu --keep-fps %ROOP_EXTRA_ARGS%
        if errorlevel 1 (
            echo [ERROR] Failed while processing "%%~fF".
            exit /b 1
        )
    )
)

if %TARGET_COUNT% EQU 0 (
    echo [ERROR] No target video found in "%DATA_DIR%".
    exit /b 1
)

echo [INFO] Completed. Generated files are in "%OUTPUT_DIR%".
exit /b 0
