@echo off
setlocal

rem ============================================================================
rem FORXA - Cotizador -- subir portadas y fichas (Windows)
rem
rem Uso: haz doble clic en este archivo, o corre en cmd:
rem   scripts\subir_fotos.bat
rem
rem Este script:
rem   1. Revisa que tengas Node.js instalado.
rem   2. Instala la unica dependencia que hace falta (@supabase/supabase-js).
rem   3. Te pide tu service_role key UNA VEZ.
rem   4. Sube las 4 portadas y las ~80 fichas a Supabase Storage.
rem No guarda tu clave en ningun archivo -- solo vive en esta ventana mientras corre.
rem ============================================================================

cd /d "%~dp0.."

echo FORXA - Cotizador -- subida de fotos
echo ------------------------------------

where node >nul 2>nul
if errorlevel 1 (
  echo No encuentro Node.js instalado.
  echo Instalalo desde https://nodejs.org ^(version LTS^), abre una ventana nueva
  echo de cmd y vuelve a correr este archivo.
  pause
  exit /b 1
)
for /f "delims=" %%v in ('node -v') do echo Node.js encontrado: %%v

if not exist "node_modules\@supabase" (
  echo Instalando dependencia ^(@supabase/supabase-js^)...
  call npm install @supabase/supabase-js
)
echo Dependencias listas

echo.
echo Pega tu service_role key de Supabase ^(Project Settings -^> API -^> service_role^)
echo y presiona Enter:
set /p SUPABASE_SERVICE_ROLE_KEY="service_role key: "

if "%SUPABASE_SERVICE_ROLE_KEY%"=="" (
  echo No ingresaste ninguna clave. Cancelado.
  pause
  exit /b 1
)

node scripts\bulk_upload_fotos.mjs

echo.
echo Listo. Recarga el cotizador en el navegador ^(Ctrl+F5^) para ver las fotos.
pause
