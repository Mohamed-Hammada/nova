@echo off
rem =========================================================================
rem Nova - Android APK Generator & Environment Setup
rem
rem Builds the Nova Android APK with automatic environment fixes:
rem   - Fixes Java version for Gradle (forces JDK 17/21 instead of Java 8/26)
rem   - Configures Android SDK path & Flutter settings
rem   - Regenerates curriculum content bundle from data/
rem   - Builds optimized Release APK (or Debug APK if --debug passed)
rem   - Copies APK to project root (nova-release.apk / nova.apk)
rem
rem Usage:
rem   build_apk.bat            (Builds optimized Release APK)
rem   build_apk.bat --debug    (Builds Debug APK)
rem =========================================================================
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo ===================================================
echo   Nova Android APK Generator
echo ===================================================
echo.

rem 1. Check Flutter
where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] flutter was not found on PATH.
  echo Please install Flutter or add it to PATH and reopen terminal.
  exit /b 1
)

rem 2. Auto-detect & configure Android SDK
set "FOUND_SDK="
if exist "%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe" (
  set "FOUND_SDK=%LOCALAPPDATA%\Android\sdk"
) else if defined ANDROID_HOME (
  if exist "%ANDROID_HOME%\platform-tools\adb.exe" set "FOUND_SDK=%ANDROID_HOME%"
) else if defined ANDROID_SDK_ROOT (
  if exist "%ANDROID_SDK_ROOT%\platform-tools\adb.exe" set "FOUND_SDK=%ANDROID_SDK_ROOT%"
)

if defined FOUND_SDK (
  set "ANDROID_HOME=%FOUND_SDK%"
  set "ANDROID_SDK_ROOT=%FOUND_SDK%"
  set "PATH=%FOUND_SDK%\platform-tools;!PATH!"
  echo [OK] Android SDK: !FOUND_SDK!
) else (
  echo [WARNING] Android SDK was not auto-detected. Build might rely on Flutter config.
)

rem 3. Auto-detect & configure JDK 17/21 (Gradle 8.14 is incompatible with Java 8 or Java 26+)
set "FOUND_JDK="
if exist "%USERPROFILE%\scoop\apps\openjdk17\current\bin\javac.exe" (
  set "FOUND_JDK=%USERPROFILE%\scoop\apps\openjdk17\current"
) else if exist "%USERPROFILE%\scoop\apps\openjdk21\current\bin\javac.exe" (
  set "FOUND_JDK=%USERPROFILE%\scoop\apps\openjdk21\current"
) else if exist "C:\Program Files\Java\jdk-21.0.10\bin\javac.exe" (
  set "FOUND_JDK=C:\Program Files\Java\jdk-21.0.10"
) else if exist "C:\Program Files\Android\Android Studio\jbr\bin\javac.exe" (
  set "FOUND_JDK=C:\Program Files\Android\Android Studio\jbr"
)

if defined FOUND_JDK (
  set "JAVA_HOME=%FOUND_JDK%"
  set "PATH=%FOUND_JDK%\bin;!PATH!"
  echo [OK] JDK 17/21:   !FOUND_JDK!
) else (
  echo [WARNING] Compatible JDK 17/21 not found in default paths. Using system JAVA_HOME: %JAVA_HOME%
)

rem 4. Ensure Flutter config has SDK & JDK set
if defined FOUND_SDK (
  call flutter config --android-sdk "%FOUND_SDK%" >nul 2>&1
)
if defined FOUND_JDK (
  call flutter config --jdk-dir "%FOUND_JDK%" >nul 2>&1
)

rem 5. Determine Build Mode
set "BUILD_MODE=release"
for %%A in (%*) do (
  if "%%A"=="--debug" set "BUILD_MODE=debug"
)

echo.
echo Mode: %BUILD_MODE%
echo.

rem 6. Run build via repository scripts
if "%BUILD_MODE%"=="debug" (
  call scripts\build_apk_debug.bat %*
  set "BUILD_RESULT=!ERRORLEVEL!"
  set "OUT_FILE=%~dp0nova.apk"
) else (
  call scripts\build_apk_release.bat %*
  set "BUILD_RESULT=!ERRORLEVEL!"
  set "OUT_FILE=%~dp0nova-release.apk"
)

if not "%BUILD_RESULT%"=="0" (
  echo.
  echo [ERROR] APK build failed with code %BUILD_RESULT%.
  exit /b %BUILD_RESULT%
)

echo.
echo ========================================================
echo  BUILD COMPLETE!
echo ========================================================
echo  Ready APK file:
echo    !OUT_FILE!
echo.
echo  To install via ADB on connected phone:
echo    adb install -r "!OUT_FILE!"
echo ========================================================
echo.

endlocal
exit /b 0
