@echo off
rem Regenerates the content bundle, then builds a debug APK.
setlocal
call "%~dp0regenerate_content_bundle.bat" || exit /b 1
pushd "%~dp0..\app"
call flutter pub get || (popd & exit /b 1)
call flutter build apk --debug %*
set "RESULT=%ERRORLEVEL%"
popd
exit /b %RESULT%
