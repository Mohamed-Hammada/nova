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

@rem Auto-detect and configure Android SDK
@set "NOVA_ANDROID_SDK="
@if exist "%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe" (
  set "NOVA_ANDROID_SDK=%LOCALAPPDATA%\Android\sdk"
) else if defined ANDROID_HOME (
  if exist "%ANDROID_HOME%\platform-tools\adb.exe" set "NOVA_ANDROID_SDK=%ANDROID_HOME%"
) else if defined ANDROID_SDK_ROOT (
  if exist "%ANDROID_SDK_ROOT%\platform-tools\adb.exe" set "NOVA_ANDROID_SDK=%ANDROID_SDK_ROOT%"
)

@if defined NOVA_ANDROID_SDK (
  set "ANDROID_HOME=%NOVA_ANDROID_SDK%"
  set "ANDROID_SDK_ROOT=%NOVA_ANDROID_SDK%"
  set "PATH=%NOVA_ANDROID_SDK%\platform-tools;%PATH%"
)

@rem Auto-detect and configure JDK 17 or 21 (Gradle 8.14 fails with Java 8 or Java 26+)
@set "NOVA_JDK="
@if exist "%USERPROFILE%\scoop\apps\openjdk17\current\bin\javac.exe" (
  set "NOVA_JDK=%USERPROFILE%\scoop\apps\openjdk17\current"
) else if exist "%USERPROFILE%\scoop\apps\openjdk21\current\bin\javac.exe" (
  set "NOVA_JDK=%USERPROFILE%\scoop\apps\openjdk21\current"
) else if exist "C:\Program Files\Java\jdk-21.0.10\bin\javac.exe" (
  set "NOVA_JDK=C:\Program Files\Java\jdk-21.0.10"
) else if exist "C:\Program Files\Android\Android Studio\jbr\bin\javac.exe" (
  set "NOVA_JDK=C:\Program Files\Android\Android Studio\jbr"
)

@if defined NOVA_JDK (
  set "JAVA_HOME=%NOVA_JDK%"
  set "PATH=%NOVA_JDK%\bin;%PATH%"
)

@exit /b 0
