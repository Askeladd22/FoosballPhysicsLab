@echo off
cd /d "%~dp0"
love legacy\neon11
if errorlevel 1 ( echo Install LOVE 11.5 or add love.exe to PATH. & pause )
