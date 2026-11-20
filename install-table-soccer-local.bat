@echo off
setlocal
cd /d "%~dp0"
set "ARCHIVE=%~1"
if "%ARCHIVE%"=="" if exist "Table_Soccer.zip" set "ARCHIVE=%~dp0Table_Soccer.zip"
if "%ARCHIVE%"=="" if exist "%USERPROFILE%\Downloads\Table_Soccer.zip" set "ARCHIVE=%USERPROFILE%\Downloads\Table_Soccer.zip"
if "%ARCHIVE%"=="" (
  echo Pass the path to your own Table_Soccer.zip, or place it in Downloads.
  pause
  exit /b 1
)
py -3 -c "from PIL import Image" >nul 2>&1
if errorlevel 1 (
  echo Pillow is required. Install it with: py -3 -m pip install Pillow
  pause
  exit /b 1
)
py -3 tools\bake_table_soccer.py "%ARCHIVE%"
if errorlevel 1 (
  echo Could not bake Table Soccer model sprites.
  pause
  exit /b 1
)
echo Private sprite conversion complete. The game now uses Table Soccer locally.
pause
