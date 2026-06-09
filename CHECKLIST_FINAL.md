# ✅ CHECKLIST: COMPLETAR IMPLEMENTACIÓN DE GOOGLE SIGN IN

## Estado Actual: 90% COMPLETADO ✅

---

## ❗ LO QUE FALTA (Solo 1 cosa)

### 📌 PASO ÚNICO: Agregar Endpoint al Backend Flask

**Ubicación**: `http://192.168.14.25` (servidor Flask)

**Acción**:
1. Abre el archivo: `c:\FlutterProyecto\mi_app\ENDPOINT_VERIFY_STUDENT_EMAIL.py`
2. Copia **TODO** el contenido (desde el inicio hasta el final)
3. Ve a tu servidor Flask 
4. Pega el código junto con tus otros endpoints (`@app.route(...)`)
5. Si tus nombres de columnas son diferentes, ajusta la SQL (líneas ~93-99)
6. **Importante**: Asegúrate que tu función para conectar BD se llama `get_db_connection()`, si no, cámbialo en línea ~82
7. Reinicia el servidor Flask: `flask run` o lo que uses

**Verificación rápida** (en terminal/PowerShell):
```bash
# Verificar que el endpoint responde
curl -X POST http://192.168.14.25/api/student/verify-email `
  -H "Content-Type: application/json" `
  -d '{"email": "test@uceva.edu.co", "codigo_estudiante": "20221234567"}'

# Si responde con JSON, ¡está listo!
```

---

## ✅ YA COMPLETADO (No tocar)

- ✅ Flutter code refactorizado (`face_registration_screen.dart`)
- ✅ Cliente API actualizado (`api_services.dart`)
- ✅ Documentación creada (3 archivos .md)
- ✅ Imports de google_sign_in agregados
- ✅ Variables OTP eliminadas
- ✅ Métodos OTP eliminados
- ✅ UI actualizada a Google Sign In
- ✅ Dialog de verificación implementado

---

## 🚀 DESPUÉS DE AGREGAR EL ENDPOINT

1. Abre terminal en `c:\FlutterProyecto\mi_app`
2. Ejecuta:
```bash
flutter clean
flutter pub get
flutter run
```

3. **Prueba manual** (en la app):
   - Selector: "Estudiante"
   - Input: Código válido (ej: 20221234567)
   - Click: "Iniciar sesión con Google"
   - Selecciona: Tu cuenta Google
   - Result: Deberías ver ✓ "Verificación completada correctamente"
   - Click: "Continuar"
   - Resultado: Se abre la cámara para capturar facial

---

## 📊 CHECKLIST RÁPIDA

- [ ] Leí `ENDPOINT_VERIFY_STUDENT_EMAIL.py`
- [ ] Copié el contenido al servidor Flask
- [ ] Ajusté nombres de columnas si era necesario
- [ ] Reinicié el servidor Flask
- [ ] Probé el endpoint con curl/Postman
- [ ] Ejecuté `flutter clean && flutter pub get && flutter run`
- [ ] Probé el flujo completo en la app
- [ ] ¡Funciona! 🎉

---

## 🆘 SI ALGO FALLA

### Error "POST /api/student/verify-email 404"
→ El endpoint no está en el servidor Flask →  Verifica que lo copiaste correctamente

### Error "Email no encontrado"
→ El email que usaste en Google no existe en la tabla `estudiantes` → Usa otro email o verifica la BD

### Error "El email no coincide"
→ El email de Google es diferente al de la tabla → Usa la cuenta Google correcta

### Error "No provider for GoogleSignIn"
→ google_sign_in no está importado → Ejecuta `flutter pub get`

---

**Nota**: Ya todo el código de Flutter está listo. Solo necesitas el endpoint en el backend. 🎯
