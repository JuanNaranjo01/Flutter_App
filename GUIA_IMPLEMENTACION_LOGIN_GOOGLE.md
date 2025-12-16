# 🔐 Implementación Completa del Login con Google

## ✅ Cambios Realizados en Flutter

### 1. Dependencias Actualizadas
- ✅ Agregado `google_sign_in: ^6.3.0` al `pubspec.yaml`
- ✅ Ejecutado `flutter pub get`

### 2. Archivos Creados/Modificados

#### Nuevos Archivos:
- ✅ `lib/services/auth_service.dart` - Servicio de autenticación con Google
- ✅ `backend_verify_teacher_endpoint.py` - Código del endpoint para el backend

#### Archivos Modificados:
- ✅ `lib/config/api_config.dart` - Agregado endpoint `verifyTeacherEndpoint`
- ✅ `lib/models/teacher.dart` - Actualizado con `fromJson()` y sin password
- ✅ `lib/screens/login_screen.dart` - Implementado Google Sign-In real
- ✅ `lib/providers/data_provider.dart` - Removidos datos simulados

---

## 🚀 Pasos Siguientes para Completar la Implementación

### Paso 1: Configurar Google Cloud Console

1. **Ir a Google Cloud Console**: https://console.cloud.google.com/

2. **Crear o Seleccionar Proyecto**:
   - Crear nuevo proyecto: "AsistenciaGuard UCEVA"
   - O seleccionar proyecto existente

3. **Habilitar APIs**:
   - Ir a "APIs y servicios" > "Biblioteca"
   - Buscar y habilitar "Google Sign-In API"

4. **Crear Credenciales OAuth 2.0**:
   - Ir a "APIs y servicios" > "Credenciales"
   - Clic en "Crear credenciales" > "ID de cliente de OAuth 2.0"

5. **Configurar Pantalla de Consentimiento**:
   - Tipo: Interno (solo usuarios de UCEVA)
   - Nombre de la aplicación: "AsistenciaGuard"
   - Correos autorizados: Agregar dominio @uceva.edu.co

#### Para Android:
1. Obtener SHA-1 de tu app:
   ```bash
   cd c:\FlutterProyecto\mi_app\android
   .\gradlew signingReport
   ```
   
2. Copiar el SHA-1 que aparece en "Variant: debug"

3. En Google Cloud Console:
   - Crear credencial tipo "Android"
   - Pegar SHA-1
   - Nombre del paquete: `com.uceva.asistencia_guard` (verificar en `android/app/build.gradle.kts`)

4. Descargar el archivo `google-services.json`

5. Copiar `google-services.json` a: `android/app/google-services.json`

#### Para iOS (si vas a usar):
1. Crear credencial tipo "iOS"
2. Bundle ID: verificar en `ios/Runner.xcodeproj`
3. Descargar `GoogleService-Info.plist`
4. Copiar a: `ios/Runner/GoogleService-Info.plist`

---

### Paso 2: Configurar el Backend Python

1. **Abrir el archivo del servidor Flask** (probablemente `app.py` o `main.py`)

2. **Copiar el código de** `backend_verify_teacher_endpoint.py` al servidor

3. **Ajustar la configuración de la base de datos**:
   ```python
   DB_CONFIG = {
       'host': 'tu_host_real',
       'database': 'tu_base_de_datos',
       'user': 'tu_usuario',
       'password': 'tu_password',
       'port': 5432
   }
   ```

4. **IMPORTANTE: Verificar la estructura de la tabla "docentes"**:
   - Confirmar que existe la columna `"Correo personal"`
   - Si la columna tiene otro nombre, ajustar la query:
   ```python
   query = """
       SELECT 
           id,
           codigo,
           nombre,
           "Correo personal" as email,  -- AJUSTAR AQUÍ
           departamento
       FROM docentes
       WHERE LOWER("Correo personal") = %s
       LIMIT 1
   """
   ```

5. **Instalar dependencia** (si no está instalada):
   ```bash
   pip install psycopg2
   ```

6. **Reiniciar el servidor Flask**

7. **Probar el endpoint**:
   ```bash
   curl -X POST http://192.168.100.99:5000/api/verify-teacher \
     -H "Content-Type: application/json" \
     -d '{"email": "docente@uceva.edu.co"}'
   ```

---

### Paso 3: Actualizar Configuración de Android

Editar `android/app/build.gradle.kts` y agregar al final del archivo `plugins`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // AGREGAR ESTA LÍNEA
}
```

Editar `android/build.gradle.kts` y agregar en `dependencies`:

```kotlin
buildscript {
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        classpath("com.google.gms:google-services:4.4.0")  // AGREGAR ESTA LÍNEA
    }
}
```

---

### Paso 4: Verificar la Tabla "docentes" en la Base de Datos

Conectarse a la base de datos y ejecutar:

```sql
-- Ver la estructura de la tabla
\d docentes

-- Ver algunas filas de ejemplo
SELECT id, codigo, nombre, "Correo personal", departamento 
FROM docentes 
LIMIT 5;

-- Verificar que hay correos institucionales
SELECT COUNT(*) 
FROM docentes 
WHERE "Correo personal" LIKE '%@uceva.edu.co';
```

**Si la columna tiene otro nombre**, anota el nombre exacto y actualiza:
1. El endpoint en el backend Python
2. Si es necesario, ajusta el modelo `Teacher` en Flutter

---

### Paso 5: Probar la Aplicación

1. **Compilar y ejecutar**:
   ```bash
   cd c:\FlutterProyecto\mi_app
   flutter run
   ```

2. **Flujo de prueba**:
   - Tocar "Continuar con Google"
   - Seleccionar cuenta de Google con correo @uceva.edu.co
   - El sistema verificará contra la tabla "docentes"
   - Si existe: Login exitoso → Navega a /home
   - Si no existe: Muestra error "No estás registrado como docente"

3. **Casos de error esperados**:
   - Correo no institucional: "Debes usar tu correo institucional @uceva.edu.co"
   - Docente no en BD: "No estás registrado como docente en el sistema"
   - Error de red: "Error de conexión al servidor"

---

## 🔍 Troubleshooting

### Error: "PlatformException(sign_in_failed)"
- **Causa**: SHA-1 incorrecto o no configurado
- **Solución**: Regenerar SHA-1 y actualizar en Google Cloud Console

### Error: "Docente no encontrado" pero el correo existe
- **Causa**: Columna mal referenciada o nombre de tabla incorrecto
- **Solución**: Verificar query SQL en el endpoint del backend

### Error: "Error de conexión a la base de datos"
- **Causa**: Credenciales de BD incorrectas
- **Solución**: Verificar `DB_CONFIG` en el servidor Python

### La pantalla de Google no aparece
- **Causa**: google-services.json no está en el lugar correcto
- **Solución**: Verificar que esté en `android/app/google-services.json`

---

## 📊 Estructura de la Base de Datos Esperada

La tabla `docentes` debe tener al menos:

| Columna          | Tipo    | Descripción                      |
|------------------|---------|----------------------------------|
| id               | INTEGER | ID único del docente             |
| codigo           | VARCHAR | Código del docente (ej: DOC123)  |
| nombre           | VARCHAR | Nombre completo                  |
| Correo personal  | VARCHAR | Correo institucional @uceva.edu.co |
| departamento     | VARCHAR | Departamento/Facultad            |

---

## 🎯 Siguientes Mejoras Recomendadas

1. **Persistencia de sesión**: Guardar token en SharedPreferences
2. **Silent Sign-In**: Login automático si ya hay sesión activa
3. **Rate Limiting**: Limitar intentos de login en el backend
4. **Logs**: Registrar intentos de login para auditoría
5. **Refresh Token**: Implementar renovación automática de tokens

---

## 📝 Checklist Final

- [ ] Google Cloud Console configurado
- [ ] SHA-1 agregado para Android
- [ ] google-services.json descargado y copiado
- [ ] Endpoint `/api/verify-teacher` implementado en backend
- [ ] Base de datos conectada correctamente
- [ ] Query SQL ajustada a la estructura real
- [ ] App compilada sin errores
- [ ] Login con Google probado exitosamente
- [ ] Verificación de correos institucionales funcionando
- [ ] Navegación a /home después de login exitoso

---

## 🆘 Contacto

Si tienes problemas con algún paso, verifica:
1. Logs del servidor Flask
2. Logs de la app Flutter (`flutter run -v`)
3. Respuestas del endpoint `/api/verify-teacher`
