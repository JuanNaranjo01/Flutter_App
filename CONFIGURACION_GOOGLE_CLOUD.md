# 🎯 Guía Paso a Paso: Configurar Google Cloud Console

## 📋 Preparación (5 minutos)

### ✅ Lo que ya está listo:
- ✅ Código Flutter implementado
- ✅ Archivos Gradle configurados
- ✅ Backend Python actualizado
- ✅ Package name: `com.uceva.asistencia_guard`

---

## 🔑 Paso 1: Obtener SHA-1 (2 minutos)

### Opción A: Windows
```bash
# Ejecutar desde la raíz del proyecto:
.\obtener_sha1.bat
```

### Opción B: Manual
```bash
cd android
.\gradlew signingReport
```

Busca en el output la sección **"Variant: debug"** y copia el **SHA-1** (algo como `A1:B2:C3:...`).

📋 **Guárdalo en un lugar accesible** - lo necesitarás en el siguiente paso.

---

## ☁️ Paso 2: Configurar Google Cloud Console (15 minutos)

### 2.1 Crear/Seleccionar Proyecto

1. **Ir a:** https://console.cloud.google.com/

2. **Click en el selector de proyectos** (arriba a la izquierda)

3. **Opciones:**
   - Si ya tienes un proyecto: Selecciónalo
   - Si no: Click "NUEVO PROYECTO"
     - Nombre: `AsistenciaGuard UCEVA`
     - Click "CREAR"

4. **Espera** a que se cree el proyecto (30 segundos)

---

### 2.2 Habilitar Google Sign-In API

1. **En el menú lateral:** Click en "APIs y servicios" > "Biblioteca"

2. **En el buscador:** Escribe `Google Sign-In`

3. **Click en:** "Google Sign-In API"

4. **Click en:** "HABILITAR"

5. **Espera** la confirmación (puede tardar unos segundos)

---

### 2.3 Configurar Pantalla de Consentimiento OAuth

1. **En el menú lateral:** "APIs y servicios" > "Pantalla de consentimiento de OAuth"

2. **Selecciona:** 
   - ⚠️ **INTERNO** (solo para usuarios de tu organización @uceva.edu.co)
   - Click "CREAR"

3. **Información de la aplicación:**
   - Nombre de la aplicación: `AsistenciaGuard UCEVA`
   - Correo de asistencia: Tu correo @uceva.edu.co
   - Logo: (Opcional)

4. **Dominio de la aplicación:** (Opcional, puedes dejar en blanco)

5. **Información de contacto del desarrollador:**
   - Email: Tu correo @uceva.edu.co

6. **Click:** "GUARDAR Y CONTINUAR"

7. **En "Permisos":** 
   - Click "GUARDAR Y CONTINUAR" (sin agregar permisos adicionales)

8. **En "Usuarios de prueba":**
   - Click "GUARDAR Y CONTINUAR"

9. **Resumen:**
   - Click "VOLVER AL PANEL"

---

### 2.4 Crear Credenciales OAuth para Android

1. **En el menú lateral:** "APIs y servicios" > "Credenciales"

2. **Click en:** "+ CREAR CREDENCIALES" (arriba)

3. **Selecciona:** "ID de cliente de OAuth 2.0"

4. **Tipo de aplicación:** Selecciona `Android`

5. **Nombre:** `AsistenciaGuard Android Debug`

6. **Certificado de firma SHA-1:**
   - Pega el SHA-1 que obtuviste en el Paso 1
   - Ejemplo: `A1:B2:C3:D4:E5:F6:07:08:09:0A:1B:2C:3D:4E:5F:6G:7H:8I:9J:0K`

7. **Nombre del paquete:**
   ```
   com.uceva.asistencia_guard
   ```

8. **Click:** "CREAR"

9. **Aparecerá un popup** "Se creó el cliente OAuth"
   - Click "ACEPTAR"

---

### 2.5 Descargar google-services.json

1. **Aún en la página de Credenciales**

2. **En la sección "IDs de cliente de OAuth 2.0":**
   - Busca tu cliente recién creado
   - Click en el ícono de **descarga** (flecha hacia abajo) a la derecha

3. **Se descargará:** `google-services.json`

4. **IMPORTANTE:** Copia este archivo a:
   ```
   c:\FlutterProyecto\mi_app\android\app\google-services.json
   ```

---

## 🔧 Paso 3: Configurar Backend (10 minutos)

### 3.1 Actualizar Credenciales de Base de Datos

1. **Abrir:** `verify_teacher_email.py`

2. **Buscar la sección `DB_CONFIG`:**

```python
DB_CONFIG = {
    'host': 'tu_host_real_aqui',        # ⬅️ CAMBIAR
    'database': 'tu_base_datos_aqui',   # ⬅️ CAMBIAR
    'user': 'tu_usuario_aqui',          # ⬅️ CAMBIAR
    'password': 'tu_password_aqui',     # ⬅️ CAMBIAR
    'port': 5432
}
```

3. **Ejemplo completo:**

```python
DB_CONFIG = {
    'host': '192.168.100.99',
    'database': 'uceva_asistencias',
    'user': 'postgres',
    'password': 'MiPasswordSeguro123',
    'port': 5432
}
```

---

### 3.2 Verificar Nombre de Columnas

1. **Conectarse a tu base de datos**

2. **Ejecutar:**
```sql
\d docentes
-- O en pgAdmin: Ver estructura de la tabla
```

3. **Verificar que existe:**
   - Tabla: `docentes`
   - Columna: `"Correo personal"` (o el nombre que tenga)

4. **Si la columna tiene otro nombre:**
   - Editar `verify_teacher_email.py`
   - Buscar: `"Correo personal"`
   - Reemplazar por el nombre correcto

---

### 3.3 Instalar Dependencias y Ejecutar

```bash
# Instalar dependencias
pip install flask flask-cors psycopg2-binary

# Ejecutar el servidor
python verify_teacher_email.py
```

**Deberías ver:**
```
============================================================
🚀 Servidor AsistenciaGuard UCEVA
============================================================
📍 Host: 0.0.0.0
🔌 Puerto: 5000
🔗 Endpoint: POST /api/verify-teacher
❤️  Health check: GET /api/health
============================================================
```

---

### 3.4 Probar el Endpoint

**En otra terminal:**

```bash
# Probar health check
curl http://192.168.100.99:5000/api/health

# Probar verificación de docente
curl -X POST http://192.168.100.99:5000/api/verify-teacher \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"tucorreo@uceva.edu.co\"}"
```

**Respuesta esperada (si existe):**
```json
{
  "success": true,
  "teacher": {
    "id": 1,
    "codigo": "DOC12345",
    "nombre": "Tu Nombre",
    "email": "tucorreo@uceva.edu.co",
    "departamento": "Tu Departamento"
  }
}
```

---

## 📱 Paso 4: Probar en la App (5 minutos)

### 4.1 Compilar y Ejecutar

```bash
cd c:\FlutterProyecto\mi_app

# Limpiar build anterior
flutter clean

# Obtener dependencias
flutter pub get

# Ejecutar en dispositivo/emulador
flutter run
```

---

### 4.2 Flujo de Prueba

**Caso 1: Login Exitoso ✅**
1. Click en "Continuar con Google"
2. Seleccionar cuenta @uceva.edu.co registrada en BD
3. **Resultado:** Debe entrar al Dashboard

**Caso 2: Correo No Institucional ❌**
1. Click en "Continuar con Google"
2. Seleccionar cuenta Gmail personal (no @uceva.edu.co)
3. **Resultado:** Error "Debes usar tu correo institucional"

**Caso 3: Docente No Registrado ❌**
1. Click en "Continuar con Google"
2. Seleccionar cuenta @uceva.edu.co NO registrada en BD
3. **Resultado:** Error "No estás registrado como docente"

---

## 🐛 Troubleshooting

### Error: "PlatformException(sign_in_failed)"

**Causa:** SHA-1 incorrecto o no configurado

**Solución:**
1. Regenerar SHA-1: `.\obtener_sha1.bat`
2. Verificar que coincida en Google Cloud Console
3. Esperar 5 minutos para que se propague
4. Limpiar build: `flutter clean`
5. Reinstalar: `flutter run`

---

### Error: "google-services.json not found"

**Causa:** Archivo no copiado correctamente

**Solución:**
1. Verificar ruta: `android\app\google-services.json`
2. El archivo debe estar dentro de la carpeta `app`
3. No debe estar en `android\google-services.json`

---

### Error: "Error de conexión a la base de datos"

**Causa:** Credenciales incorrectas en `DB_CONFIG`

**Solución:**
1. Verificar host, database, user, password
2. Probar conexión manual con pgAdmin
3. Verificar que el puerto sea 5432 (o el correcto)
4. Verificar firewall si el servidor está remoto

---

### Error: "Docente no encontrado" pero el correo existe

**Causa:** Columna mal referenciada

**Solución:**
1. Verificar estructura: `\d docentes`
2. Confirmar nombre exacto de la columna
3. Actualizar query en `verify_teacher_email.py`
4. Reiniciar servidor Flask

---

### La pantalla de Google no aparece

**Causa:** Plugin no configurado correctamente

**Solución:**
1. Verificar `android/app/build.gradle.kts` tiene:
   ```kotlin
   id("com.google.gms.google-services")
   ```
2. Verificar `android/settings.gradle.kts` tiene:
   ```kotlin
   id("com.google.gms.google-services") version "4.4.2" apply false
   ```
3. Ejecutar: `flutter clean && flutter pub get`
4. Rebuild completo

---

## 📊 Checklist Final

### Flutter & Android
- [x] Dependencia `google_sign_in` agregada
- [x] Archivos Gradle actualizados
- [ ] `google-services.json` descargado
- [ ] `google-services.json` copiado a `android/app/`
- [ ] SHA-1 obtenido
- [ ] SHA-1 configurado en Google Cloud Console

### Backend
- [ ] Credenciales de BD actualizadas en `DB_CONFIG`
- [ ] Dependencias instaladas (`pip install`)
- [ ] Servidor Flask ejecutándose
- [ ] Endpoint probado con curl

### Google Cloud Console
- [ ] Proyecto creado/seleccionado
- [ ] Google Sign-In API habilitada
- [ ] Pantalla de consentimiento configurada (INTERNO)
- [ ] Credenciales OAuth Android creadas
- [ ] SHA-1 agregado
- [ ] Package name correcto: `com.uceva.asistencia_guard`

### Base de Datos
- [ ] Tabla `docentes` existe
- [ ] Columna con correos existe
- [ ] Al menos un correo @uceva.edu.co registrado
- [ ] Estructura verificada

### Pruebas
- [ ] Login exitoso con cuenta registrada
- [ ] Rechazo de correo no institucional
- [ ] Rechazo de docente no registrado
- [ ] Logout funciona correctamente

---

## 🎉 ¡Listo!

Si completaste todos los pasos del checklist, tu sistema de login con Google está **100% funcional**.

---

**Tiempo estimado total:** 30-35 minutos

**Documentos relacionados:**
- [RESUMEN_LOGIN_IMPLEMENTADO.md](RESUMEN_LOGIN_IMPLEMENTADO.md) - Resumen técnico
- [INICIO_RAPIDO_LOGIN.md](INICIO_RAPIDO_LOGIN.md) - Guía rápida
- [GUIA_IMPLEMENTACION_LOGIN_GOOGLE.md](GUIA_IMPLEMENTACION_LOGIN_GOOGLE.md) - Guía detallada

**Scripts útiles:**
- `obtener_sha1.bat` (Windows) - Obtener SHA-1
- `obtener_sha1.sh` (Linux/Mac) - Obtener SHA-1
- `verify_teacher_email.py` - Servidor backend
