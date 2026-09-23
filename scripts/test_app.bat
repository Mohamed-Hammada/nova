@echo off
rem Regenerates the content bundle, then runs the Flutter app's test suite.
rem Extra arguments are passed to `flutter test` (e.g. a test file path).
setlocal
call "%~dp0regenerate_content_bundle.bat" || exit /b 1
pushd "%~dp0..\app"
call flutter pub get || (popd & exit /b 1)
call flutter test %*
set "RESULT=%ERRORLEVEL%"
popd
exit /b %RESULT%
