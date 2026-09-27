@echo off
rem Alias for build_apk.bat
call "%~dp0build_apk.bat" %*
exit /b %ERRORLEVEL%
