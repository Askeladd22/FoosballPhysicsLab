@echo off
setlocal
cd /d "%~dp0"
set "GLB=%~1"
if "%GLB%"=="" if exist "assets\models\foosball_table.glb" set "GLB=assets\models\foosball_table.glb"
if "%GLB%"=="" if exist "%USERPROFILE%\Downloads\foosball_table (2).glb" set "GLB=%USERPROFILE%\Downloads\foosball_table (2).glb"
if "%GLB%"=="" (
 echo Foosball Table by 3D Content Online, CC BY 4.0.
 echo Save the user-supplied GLB to assets\models\foosball_table.glb
 echo or drag the GLB onto this .bat file.
 pause
 exit /b 1
)
py -3 -c "import trimesh, numpy" >nul 2>&1
if errorlevel 1 (
 echo Installing offline 3D conversion dependencies...
 py -3 -m pip install "trimesh>=4,<5" "numpy>=1.24"
 if errorlevel 1 (echo Python dependency installation failed.&pause&exit /b 1)
)
py -3 tools\import_foosball_glb_ccby.py "%GLB%" --output "local_assets\3d"
if errorlevel 1 (echo GLB conversion failed.&pause&exit /b 1)
echo CC BY Table Soccer mesh pack installed. Run love .
echo Do not remove assets\models\ATTRIBUTION.md when publishing.
pause
