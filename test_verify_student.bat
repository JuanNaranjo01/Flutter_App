@echo off
REM Script para probar el endpoint verify_student en Windows
REM Uso: test_verify_student.bat [email]

if "%~1"=="" (
    set EMAIL=estudiante1@uceva.edu.co
) else (
    set EMAIL=%~1
)

set SERVER_URL=http://localhost:5000

echo 🧪 Probando endpoint verify_student
echo 📧 Email: %EMAIL%
echo 🌐 Server: %SERVER_URL%
echo ----------------------------------------

curl -X POST "%SERVER_URL%/api/verify_student" ^
  -H "Content-Type: application/json" ^
  -d "{\"email\": \"%EMAIL%\"}"

echo.
echo ----------------------------------------
echo 💡 Si obtienes 404, el estudiante no existe en la BD
echo 💡 Si obtienes 200, el estudiante fue encontrado
echo 💡 Si obtienes error de conexión, verifica que el servidor esté corriendo
pause