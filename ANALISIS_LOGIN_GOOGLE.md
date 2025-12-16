# Análisis del Proyecto y Plan de Implementación - Login con Google OAuth

## 📋 Estado Actual del Proyecto

### Estructura General
- **Framework**: Flutter + Provider (State Management)
- **Autenticación**: Simulada con credenciales hardcodeadas
- **API Backend**: Server en `http://192.168.100.99:5000`
- **Pantalla de Login**: Solo valida contra lista local de docentes

### Componentes de Login Actuales
1. **LoginScreen** (`lib/screens/login_screen.dart`)
   - UI con formulario de email
   - Botón "Continuar con Google" que NO está conectado a Google
   - Valida email contra lista hardcodeada de docentes

2. **DataProvider** (`lib/providers/data_provider.dart`)
   - `_teachers`: Lista simulada con 2 docentes
   - `loginWithEmail()`: Busca en lista local
   - `_currentTeacher`: Almacena docente autenticado

3. **Teacher Model** (`lib/models/teacher.dart`)
   - id, codigo, nombre, email, departamento, password (vulnerable)

4. **ApiService** (`lib/services/api_services.dart`)
   - Métodos de API para estudiantes/asistencia
   - NO tiene métodos de autenticación OAuth

### Dependencias Actuales
```yaml
provider: ^6.1.1
http: ^1.1.0
google_fonts: ^6.1.0
```

---

## 🎯 Plan de Implementación - Login Google OAuth

### Fase 1: Investigación y Configuración
- [ ] Verificar tabla "docentes" en backend (estructura, columnas, API endpoint)
- [ ] Confirmar columna "Correo personal" contiene correos @uceva.edu.co
- [ ] Crear endpoint en backend: GET `/api/teachers` o `/api/docentes`
- [ ] Configurar Google OAuth:
  - Crear proyecto en Google Cloud Console
  - Configurar OAuth 2.0 credentials (Android + iOS)
  - Agregar URIs de redirección autorizadas

### Fase 2: Agregar Dependencias Flutter
```yaml
google_sign_in: ^6.1.0
google_auth_googleapis: ^3.0.0
```

### Fase 3: Crear Servicios de Autenticación
- [ ] `AuthenticationService`: Manejar Google OAuth
  - `signInWithGoogle()`: Obtener token de Google
  - `validateGoogleEmailWithBackend()`: Verificar correo en tabla docentes
  - `logout()`: Cerrar sesión

### Fase 4: Actualizar Backend (si es necesario)
- [ ] Endpoint: `POST /api/verify-teacher-email`
  - Input: email de Google
  - Output: datos del docente o error si no existe

### Fase 5: Modificar DataProvider
- [ ] Reemplazar validación local con Google OAuth
- [ ] Cargar docentes desde backend (en lugar de hardcodeado)
- [ ] Manejar casos de error

### Fase 6: Actualizar LoginScreen
- [ ] Conectar botón "Continuar con Google" con función real
- [ ] Mostrar indicador de carga durante OAuth
- [ ] Validar que correo sea institucional
- [ ] Mostrar errores específicos

---

## 🔐 Flujo de Autenticación Propuesto

```
Usuario toca "Continuar con Google"
    ↓
GoogleSignIn.signIn() → Usuario elige cuenta Google
    ↓
Obtener correo de la cuenta Google
    ↓
¿Es correo @uceva.edu.co?
    ├─ NO → Mostrar error "Usa correo institucional"
    └─ SÍ → Llamar backend: POST /api/verify-teacher-email
           ↓
           ¿Existe en tabla docentes?
           ├─ SÍ → Guardar en DataProvider → Navegar a /home
           └─ NO → Mostrar error "No eres docente registrado"
```

---

## 📊 Datos Esperados del Backend

La tabla "docentes" debe tener:
```json
{
  "id": 1,
  "codigo": "DOC12345",
  "nombre": "Dr. Juan Carlos Pérez",
  "correo_personal": "juan.perez@uceva.edu.co",
  "departamento": "Ingeniería de Sistemas",
  ...
}
```

---

## 🛠️ Cambios Principales a Realizar

### 1. Nuevo archivo: `lib/services/authentication_service.dart`
- Manejar Google Sign In
- Validar con backend
- Gestionar tokens

### 2. Modificar: `lib/providers/data_provider.dart`
- Reemplazar lista local con datos del backend
- Agregar método: `googleLogin(String googleEmail)`
- Cargar docentes al iniciar app

### 3. Modificar: `lib/screens/login_screen.dart`
- Conectar botón Google a función real
- Mejorar UX con mensajes claros

### 4. Modificar: `lib/models/teacher.dart`
- Agregar campos si es necesario
- Remover campo `password` (sensible)

### 5. Modificar: `lib/config/api_config.dart`
- Agregar endpoint: `/verify-teacher-email`
- Agregar endpoint: `/teachers` o `/docentes`

### 6. Modificar: `pubspec.yaml`
- Agregar: `google_sign_in: ^6.1.0`

---

## ✅ Próximos Pasos Recomendados

1. **Confirma conmigo:**
   - ¿Estructura exacta de tabla docentes en backend?
   - ¿Ya existe endpoint para obtener docentes?
   - ¿Configuración Google Cloud ya lista?

2. **Luego implementamos:**
   - Servicio de Google OAuth
   - Validación de email institucional
   - Integración backend
   - Testing completo

