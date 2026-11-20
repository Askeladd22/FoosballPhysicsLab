@echo off
cd /d "%~dp0"
love .
if errorlevel 1 ( echo Install LÖVE 11.5 or add love.exe to PATH. & pause )
