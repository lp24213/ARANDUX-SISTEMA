@echo off
chcp 65001 >nul
set ROOT=%~dp0
cd /d "%ROOT%"

echo.
echo ========================================
echo   ARANDUX - DEPLOY CLOUDFLARE
echo ========================================
echo.

echo [1/4] npm install - aguarde (pode levar 5-15 min)...
call npm install --legacy-peer-deps
if errorlevel 1 (echo ERRO no npm install. & pause & exit /b 1)

echo.
echo [2/4] Build frontend...
cd "%ROOT%frontend"
call npm run build
if errorlevel 1 (echo ERRO no build frontend. & cd "%ROOT%" & pause & exit /b 1)

echo.
echo [3/4] Deploy Frontend (Pages)...
call npx wrangler pages deploy dist --project-name=arandux-frontend
if errorlevel 1 (echo ERRO no deploy Pages. & cd "%ROOT%" & pause & exit /b 1)

echo.
echo [4/4] Build e Deploy Backend (Worker)...
cd "%ROOT%backend"
call npm run build:worker
if errorlevel 1 (echo ERRO no build worker. & cd "%ROOT%" & pause & exit /b 1)
call npx wrangler deploy --env production
if errorlevel 1 (echo ERRO no deploy Worker. & cd "%ROOT%" & pause & exit /b 1)

cd "%ROOT%"
echo.
echo ========================================
echo   DEPLOY CONCLUIDO
echo ========================================
echo   Frontend: https://arandux.com ou URL do Pages
echo   Backend:  https://api.arandux.com
echo ========================================
pause
