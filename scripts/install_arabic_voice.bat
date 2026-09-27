@echo off
rem Installs a Windows Arabic voice so Nova can read Arabic questions aloud.
rem Accept the Windows administrator prompt, then restart your browser.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_arabic_voice.ps1"
