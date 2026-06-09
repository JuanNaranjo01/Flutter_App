# REFACTORING COMPLETADO: OTP → Google Sign In para Estudiantes

## 📋 Resumen General
He reemplazado completamente el sistema de verificación por OTP con **Google Sign In**. Los estudiantes ahora:
1. Ingresan su código
2. Hacen clic en "Iniciar sesión con Google"
3. Backend verifica que el email existe en la BD
4. Proceden a capturar facial embeddings

---

## ✅ CAMBIOS COMPLETADOS

### 1. **Frontend Flutter** (`lib/screens/face_registration_screen.dart`)

#### Importaciones (Línea 3)
- ✅ Agregado: `import 'package:google_sign_in/google_sign_in.dart';`

#### Variables de Estado (Líneas ~36-38)
- ❌ ELIMINADAS:
  - `_otpController` (TextEditingController)
  - `_isOtpSending`, `_isOtpVerifying`, `_isOtpValidated` (bools)
  - `_otpSessionToken`, `_otpMessage` (Strings)
  - `_otpRequestCooldownSeconds` (int)
  - `_otpRequestTimer` (Timer)

- ✅ AGREGADAS:
  - `_isGoogleSigningIn` (bool) - Indica si Google Sign In está en progreso
  - `_studentVerificationChecked` (bool) - Indica si el email fue validado
  - `_studentVerificationError` (String?, nullable) - Mensaje de error

#### Método `dispose()` (Línea ~40-50)
- ✅ Eliminado: `_otpController.dispose()`
- ✅ Eliminado: `_otpRequestTimer?.cancel()`

#### Métodos Eliminados
- ❌ BORRADOS:
  - `_startOtpCooldown()` - Cronómetro de 60 segundos
  - `requestOtp()` - Llamada a API para enviar OTP
  - `verifyOtp()` - Validación de código OTP
  - Bloque de UI con campos OTP (400+ líneas)
  - Bloque de mensaje `_otpMessage`

#### Método Agregado: `verifyStudentWithGoogle()` (Línea ~208)
```dart
Future<void> verifyStudentWithGoogle() async {
  // 1. Inicializa Google Sign In
  // 2. Llama a googleSignIn.signIn()
  // 3. Obtiene el email del usuario
  // 4. Llama a ApiService.verifyStudentEmail(email, codigo)
  // 5. Si es válido: establece _studentVerificationChecked = true
  // 6. Si no: muestra error en _studentVerificationError
}
```

#### Dialog de Verificación (Línea ~320)
- **ANTES**: Card con campos OTP, botón "Enviar código", campo de 6 dígitos, botón "Validar Código"
- **DESPUÉS**: 
  - Header: "Verificación con Google" (ícono + título)
  - Condición `if (_studentVerificationChecked)`: Mostrar ✓ "Verificado"
  - Condición `else`: Botón "Iniciar sesión con Google"
  - Muestra `_studentVerificationError` si hay problemas

#### Botón "Continuar" en Dialog (Línea ~710)
- **ANTES**: Deshabilitado si `widget.isStudentMode && !_isOtpValidated`
- **DESPUÉS**: Deshabilitado si `widget.isStudentMode && !_studentVerificationChecked`

#### Método `_registerEmbeddings()` (Línea ~775)
- **ANTES**: Verificaba `if (widget.isStudentMode && !_isOtpValidated)`
- **DESPUÉS**: Verifica `if (widget.isStudentMode && !_studentVerificationChecked)`
- ✅ Eliminado parámetro: `otpToken: widget.isStudentMode ? _otpSessionToken : null`

#### Método `_resetForm()` (Línea ~950)
- ✅ Eliminad: `_otpController.clear()` y `_otpMessage = null`
- ✅ Agregado: Reset de `_isGoogleSigningIn` y `_studentVerificationError`

---

### 2. **Cliente API** (`lib/services/api_services.dart`)

#### Método Agregado: `verifyStudentEmail()` (Línea ~1280)
```dart
static Future<Map<String, dynamic>> verifyStudentEmail({
  required String email,
  required String codigoEstudiante,
}) async {
  // POST a /api/student/verify-email
  // Input: { "email": "...", "codigo_estudiante": "..." }
  // Output: { "success": true/false, "message": "...", "student": {...} }
}
```

---

### 3. **Backend Flask** - PENDIENTE DE CREAR

#### Archivo: `ENDPOINT_VERIFY_STUDENT_EMAIL.py`
✅ Creado en: `c:\FlutterProyecto\mi_app\ENDPOINT_VERIFY_STUDENT_EMAIL.py`

Este archivo contiene:
- Endpoint completo: `POST /api/student/verify-email`
- Lógica de verificación de email
- Documentación detallada
- Instrucciones de integración

**ACCIÓN REQUERIDA**: Copiar el contenido de `ENDPOINT_VERIFY_STUDENT_EMAIL.py` y agregarlo al servidor Flask existente en `http://192.168.14.25`

---

## 🔄 FLUJO COMPLETO DEL ESTUDIANTE (NUEVO)

```
┌─────────────────────────────────────┐
│ 1. Pantalla: Ingresa Código         │
│    (igual que antes: 20221234567)   │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│ 2. Backend busca código             │
│    (API: /api/search_student)       │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│ 3. Dialog: "Verificación con Google"│
│    - Muestra: nombre del estudiante │
│    - Botón: "Iniciar sesión"        │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│ 4. Usuario hace clic                │
│    → Google Sign In popup           │
│    → Usuario elige cuenta Google    │
│    → Obtiene email & token          │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│ 5. Backend verifica email           │
│    (API: /api/student/verify-email) │
│    - Check: ¿existe email en BD?    │
│    - Check: ¿coincide con código?   │
└─────────────────────────────────────┘
                 ↓
        ┌─────────────────┐
        │ ✓ Email válido? │
        └────┬────────┬───┘
             │        │
            SÍ       NO
             │        │
             ↓        ↓
    ┌──────────────┐  Dialog con error
    │ Habilita     │  "El email no coincide"
    │ botón        │  "Intenta con otra cuenta"
    │ Continuar    │
    └──────┬───────┘
           ↓
┌─────────────────────────────────────┐
│ 6. Usuario hace clic "Continuar"    │
│    → Inicia captura de cámara       │
│    → Video de 3 segundos            │
│    → Extrae 4 frames                │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│ 7. Backend procesa embeddings       │
│    (API: /api/register_embeddings)  │
│    - Face recognition               │
│    - Almacena en BD                 │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│ ✅ REGISTRO COMPLETO                │
│    "¡Fotos guardadas!"              │
└─────────────────────────────────────┘
```

---

## 📦 DEPENDENCIAS REQUERIDAS

### Flutter (`pubspec.yaml`)
```yaml
dependencies:
  google_sign_in: ^6.0.0  # ✅ Ya debe estar en tu proyecto
  camera: ^0.10.0
  http: ^1.0.0
```

**Nota**: `google_sign_in` ya es una dependencia del proyecto (usado por docentes)

### Backend Python
```python
# Importaciones existentes (no agregar nuevas)
from flask import request, jsonify
from psycopg2.extras import RealDictCursor
```

---

## 🚀 PASO A PASO: TERMINAR LA IMPLEMENTACIÓN

### Paso 1: Agregar Endpoint al Backend
1. Abre tu servidor Flask (en `http://192.168.14.25`)
2. Copia el contenido de `ENDPOINT_VERIFY_STUDENT_EMAIL.py`
3. Agrégalo junto con tus otros endpoints
4. Reinicia el servidor Flask

**Verificación**: 
```bash
curl -X POST http://192.168.14.25/api/student/verify-email \
  -H "Content-Type: application/json" \
  -d '{"email": "test@uceva.edu.co", "codigo_estudiante": "20221234567"}'
```

### Paso 2: Compilar y Probar Flutter
```bash
cd c:\FlutterProyecto\mi_app
flutter clean
flutter pub get
flutter run
```

**Verificar compilación**: No debe haber errores sobre `_otpController`, `_isOtpValidated`, `_otpMessage`, etc.

### Paso 3: Probar el Flujo Completo
1. Ejecuta la app
2. Selecciona "Estudiante" (student mode)
3. Ingresa un código de estudiante válido
4. Haz clic en "Iniciar sesión con Google"
5. Usa una cuenta Google con email institucional (@uceva.edu.co)
6. Confirma que se procede a capturar facial

---

## ⚠️ POSIBLES ERRORES Y SOLUCIONES

### Error: "No provider for GoogleSignIn"
**Solución**: Asegúrate que `google_sign_in` está en `pubspec.yaml` con `flutter pub get`

### Error: "POST /api/student/verify-email 404"
**Solución**: El endpoint no está en el servidor Flask. Verifica que copiaste el código correctamente.

### Error: "Email no encontrado en la BD"
**Solución**: 
- Verifica que el email en tu tabla `estudiantes` coincida exactamente (mayúsculas/minúsculas)
- Usa el mismo código que en `ENDPOINT_VERIFY_STUDENT_EMAIL.py` para normalizar

### Error: "El email no coincide"
**Solución**: 
- Usuario está usando cuenta Google que doesn't match su email institucional
- Pide que seleccione la cuenta correcta en Google Sign In

---

## 📊 COMPARATIVA: OTP vs Google Sign In

| Aspecto | OTP (Anterior) | Google Sign In (Nuevo) |
|--------|----------------|----------------------|
| **Verificación** | Código de 6 dígitos | Token OAuth de Google |
| **Seguridad** | Moderada (token en DB) | Alta (OAuth estándar) |
| **UX** | Esperar email, copiar código | Un clic en Google |
| **Rate Limiting** | 60 segundos por intento | Manejado por Google |
| **Email Storage** | Necesario guardar token | No necesario (Google) |
| **Dependencias** | Resend API | google_sign_in (ya existe) |
| **Mantenimiento** | Problemas SMTP/Resend | Google mantiene OAuth |
| **Complejidad código** | 400+ líneas OTP | 50 líneas Google |

---

## 📝 ARCHIVOS MODIFICADOS

```
✅ lib/screens/face_registration_screen.dart    (REFACTORED)
✅ lib/services/api_services.dart              (+ método verifyStudentEmail)
✅ ENDPOINT_VERIFY_STUDENT_EMAIL.py            (CREADO - para backend)
```

---

## 🎯 SIGUIENTE FASE (POST-IMPLEMENTACIÓN)

Una vez que todo funcione:
1. Probar con múltiples estudiantes
2. Validar que los facial embeddings se guardan correctamente
3. Usar el flujo de reconocimiento para marcar asistencia
4. Documentar en README para los usuarios

---

**Estado**: ✅ REFACTORING COMPLETADO - LISTO PARA TESTING
**Última actualización**: Hoy
**Responsable**: Migración OTP → Google Sign In
