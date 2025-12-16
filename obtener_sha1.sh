#!/bin/bash
# Script para obtener el SHA-1 de debug para Google OAuth
# AsistenciaGuard UCEVA

echo "============================================================"
echo " Obteniendo SHA-1 para Google Cloud Console"
echo "============================================================"
echo ""

cd android

echo "[1/2] Ejecutando gradlew signingReport..."
echo ""

./gradlew signingReport

echo ""
echo "============================================================"
echo " INSTRUCCIONES:"
echo "============================================================"
echo ""
echo "1. Busca en el output de arriba la sección 'Variant: debug'"
echo "2. Copia el valor de SHA-1 (es una cadena larga con : )"
echo "   Ejemplo: A1:B2:C3:D4:E5:F6:07:08:09:0A:1B:2C:3D:4E:5F:6G:7H:8I:9J:0K"
echo ""
echo "3. Ve a: https://console.cloud.google.com/"
echo "4. Selecciona tu proyecto 'AsistenciaGuard'"
echo "5. Ve a: APIs y servicios > Credenciales"
echo "6. Crea OAuth 2.0 Client ID (Android)"
echo "7. Pega el SHA-1 que copiaste"
echo "8. Package name: com.uceva.asistencia_guard"
echo ""
echo "============================================================"

read -p "Presiona Enter para continuar..."
