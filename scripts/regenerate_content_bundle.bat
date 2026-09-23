@echo off
rem Regenerates app\assets\content\content_bundle.json from data\ through the
rem content compiler, which validates the data first and refuses to produce a
rem bundle from invalid data. Windows counterpart of regenerate_content_bundle.sh.
setlocal
call "%~dp0_common.bat" || exit /b 1
pushd "%NOVA_ROOT%"
"tools\validate\.venv\Scripts\python.exe" tools\content_compiler\compile.py
set "RESULT=%ERRORLEVEL%"
popd
if not "%RESULT%"=="0" (
  echo error: the content bundle could not be generated (see the validator output above^). 1>&2
  exit /b %RESULT%
)
endlocal
