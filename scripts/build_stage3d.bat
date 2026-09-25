@echo off
setlocal
cd /d "%~dp0\..\app\stage3d"
echo Building stage3d Vite bundle...
call npm run build
if %errorlevel% neq 0 (
  echo Error: stage3d build failed.
  exit /b %errorlevel%
)

echo Copying public models into assets/stage3d/models...
if not exist "..\assets\stage3d\models" mkdir "..\assets\stage3d\models"
xcopy /y /e /i "public\models" "..\assets\stage3d\models"

echo Stage3D build complete!
endlocal
