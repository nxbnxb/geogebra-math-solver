@echo off
REM ==============================================
REM  geogebra-math-solver 安装脚本
REM  支持多种 AI 工具（WorkBuddy / Codex / Cursor 等）
REM ==============================================
setlocal enabledelayedexpansion

set SKILL_NAME=geogebra-math-solver
set SCRIPT_DIR=%~dp0

echo 📐 GeoGebra Math Solver
echo =======================
echo.

REM 检测平台
set DETECTED=
if exist "%USERPROFILE%\.workbuddy\skills\" (
  set DETECTED=workbuddy
) else if exist "%USERPROFILE%\.codex\" (
  set DETECTED=codex
) else if exist "%USERPROFILE%\.cursor\" (
  set DETECTED=cursor
)

echo 检测到平台: %DETECTED%
echo.
echo 请选择安装目标:
echo   1^) WorkBuddy  (%%USERPROFILE%%\.workbuddy\skills\)
echo   2^) Codex      (当前目录生成 .codex.md)
echo   3^) Cursor     (当前目录生成 .cursorrules)
echo   4^) 通用       (当前目录复制 SKILL.md)
echo   0^) 退出
echo.
set /p CHOICE="请输入数字 [1-4]: "

if "%CHOICE%"=="1" (
  set TARGET=%USERPROFILE%\.workbuddy\skills\%SKILL_NAME%
  if not exist "!TARGET!" mkdir "!TARGET!"
  copy /Y "%SCRIPT_DIR%SKILL.md" "!TARGET!\SKILL.md" >nul
  echo ✅ 已安装到 !TARGET!\SKILL.md
  echo    上传数学题目截图即可自动触发。
) else if "%CHOICE%"=="2" (
  copy /Y "%SCRIPT_DIR%adapters\codex.md" "%CD%\.codex.md" >nul
  echo ✅ 已生成 .codex.md
) else if "%CHOICE%"=="3" (
  copy /Y "%SCRIPT_DIR%adapters\generic.md" "%CD%\.cursorrules" >nul
  echo ✅ 已生成 .cursorrules
) else if "%CHOICE%"=="4" (
  copy /Y "%SCRIPT_DIR%SKILL.md" "%CD%\SKILL.md" >nul
  echo ✅ 已复制 SKILL.md 到当前目录
) else if "%CHOICE%"=="0" (
  echo 已取消。
  exit /b 0
) else (
  echo 无效选择，退出。
  exit /b 1
)

echo.
echo 🚀 使用方式：上传数学题目截图，说「帮我生成 GeoGebra 交互演示」。
pause
endlocal
