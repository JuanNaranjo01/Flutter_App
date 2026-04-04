#!/bin/bash

# Script para probar el endpoint verify_student
# Uso: ./test_verify_student.sh [email]

EMAIL=${1:-"estudiante1@uceva.edu.co"}
SERVER_URL="http://localhost:5000"

echo "🧪 Probando endpoint verify_student"
echo "📧 Email: $EMAIL"
echo "🌐 Server: $SERVER_URL"
echo "----------------------------------------"

curl -X POST "$SERVER_URL/api/verify_student" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\"}" \
  -w "\n📊 HTTP Status: %{http_code}\n⏱️  Tiempo total: %{time_total}s\n"

echo "----------------------------------------"
echo "💡 Si obtienes 404, el estudiante no existe en la BD"
echo "💡 Si obtienes 200, el estudiante fue encontrado"
echo "💡 Si obtienes error de conexión, verifica que el servidor esté corriendo"