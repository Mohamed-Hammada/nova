@echo off
rem Regenerates the content bundle, then builds a release APK.
setlocal
call "%~dp0_common.bat" || exit /b 1
call "%~dp0regenerate_content_bundle.bat" || exit /b 1
pushd "%~dp0..\app"
call flutter pub get || (popd & exit /b 1)
call flutter build apk --release %*
set "RESULT=%ERRORLEVEL%"
popd
if "%RESULT%"=="0" (
  copy /y "%~dp0..\app\build\app\outputs\flutter-apk\app-release.apk" "%~dp0..\nova-release.apk" >nul
  echo.
  echo ========================================================
  echo  [SUCCESS] Release APK built successfully!
  echo ========================================================
  echo  Output: %~dp0..\nova-release.apk
  echo ========================================================
)
exit /b %RESULT%
