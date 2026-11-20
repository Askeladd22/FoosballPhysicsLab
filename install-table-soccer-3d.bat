@echo off
setlocal
cd /d "%~dp0"
set "ARCHIVE=%~1"
if "%ARCHIVE%"=="" if exist "%~dp0Table_Soccer.zip" set "ARCHIVE=%~dp0Table_Soccer.zip"
if "%ARCHIVE%"=="" if exist "%USERPROFILE%\Downloads\Table_Soccer.zip" set "ARCHIVE=%USERPROFILE%\Downloads\Table_Soccer.zip"
if "%ARCHIVE%"=="" (
  echo Drag your own Table_Soccer.zip onto this BAT or put it into Downloads.
  pause
  exit /b 1
)
py -3 tools\import_table_soccer_3d.py "%ARCHIVE%"
if errorlevel 1 (
  echo 3D mesh import failed. Check original source archive.
  pause
  exit /b 1
)
echo 11 real 3D meshes imported locally. Start the game with love .
pause
