@rem Shared checks for the Nova Windows scripts. Not meant to be run directly.
@rem Sets NOVA_ROOT to the repository root and verifies the toolchain.
@set "NOVA_ROOT=%~dp0.."
@where flutter >nul 2>nul
@if errorlevel 1 (
  echo error: flutter was not found on PATH. Install Flutter and reopen the terminal. 1>&2
  exit /b 1
)
@if not exist "%NOVA_ROOT%\tools\validate\.venv\Scripts\python.exe" (
  echo error: no Python virtualenv at tools\validate\.venv. Create it first: 1>&2
  echo   python -m venv tools\validate\.venv 1>&2
  echo   tools\validate\.venv\Scripts\python.exe -m pip install -r tools\validate\requirements.txt 1>&2
  exit /b 1
)
@exit /b 0
