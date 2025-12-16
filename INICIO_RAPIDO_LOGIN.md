# ⚡ INICIO RÁPIDO - Login con Google

## 🎯 ¿Qué se implementó?

Login real con Google OAuth que verifica docentes en la base de datos.

---

## ⚠️ CONFIGURACIÓN REQUERIDA (30 min)

### 1️⃣ Google Cloud Console (10 min)

```bash
# 1. Obtener SHA-1
cd c:\FlutterProyecto\mi_app\android
.\gradlew signingReport

# Copiar el SHA-1 que dice "Variant: debug"
```

**Luego**:
1. Ir a: https://console.cloud.google.com/
2. Crear proyecto "AsistenciaGuard"
3. APIs y servicios → Credenciales
4. Crear OAuth 2.0 → Android
5. Pegar SHA-1 y package name: `com.uceva.asistencia_guard`
6. Descargar `google-services.json`
7. Copiar a: `android/app/google-services.json`

---

### 2️⃣ Backend Python (15 min)

**Archivo**: Abrir tu servidor Flask (probablemente `app.py`)

**Agregar este código**:

```python
from flask import request, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor

# Configurar según tu BD
DB_CONFIG = {
    'host': 'tu_host',
    'database': 'tu_database',
    'user': 'tu_user',
    'password': 'tu_password',
}

@app.route('/api/verify-teacher', methods=['POST'])
def verify_teacher():
    try:
        data = request.get_json()
        email = data['email'].lower()
        
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # ⚠️ AJUSTAR columna si no se llama "Correo personal"
        cursor.execute("""
            SELECT id, codigo, nombre, 
                   "Correo personal" as email, 
                   departamento
            FROM docentes
            WHERE LOWER("Correo personal") = %s
            LIMIT 1
        """, (email,))
        
        teacher = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if teacher:
            return jsonify({
                'success': True,
                'teacher': dict(teacher)
            }), 200
        else:
            return jsonify({
                'success': False,
                'message': 'Docente no encontrado'
            }), 404
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500
```

**Instalar**:
```bash
pip install psycopg2
```

**Reiniciar el servidor Flask**

---

### 3️⃣ Android Config (5 min)

**Archivo**: `android/build.gradle.kts`

Buscar `dependencies` dentro de `buildscript` y agregar:
```kotlin
classpath("com.google.gms:google-services:4.4.0")
```

**Archivo**: `android/app/build.gradle.kts`

Al final de `plugins` agregar:
```kotlin
id("com.google.gms.google-services")
```

---

## 🧪 PROBAR

```bash
cd c:\FlutterProyecto\mi_app
flutter run
```

**Flujo**:
1. Tocar "Continuar con Google"
2. Seleccionar cuenta @uceva.edu.co
3. ✅ Si está en tabla "docentes" → Entra al Dashboard
4. ❌ Si no está → Muestra error

---

## 🐛 Problemas Comunes

### "sign_in_failed"
→ SHA-1 incorrecto. Regenerar y actualizar en Google Cloud Console

### "Docente no encontrado" pero existe
→ Verificar nombre de columna en query SQL

### "Error de conexión"
→ Verificar que el servidor Flask esté corriendo en `192.168.100.99:5000`

### Pantalla de Google no aparece
→ Verificar que `google-services.json` esté en `android/app/`

---

## 📚 Documentación Completa

- Ver: `GUIA_IMPLEMENTACION_LOGIN_GOOGLE.md`
- Ver: `RESUMEN_LOGIN_IMPLEMENTADO.md`
- Código backend: `backend_verify_teacher_endpoint.py`

---

## ✅ Checklist

- [ ] Obtener SHA-1
- [ ] Configurar Google Cloud Console
- [ ] Descargar google-services.json
- [ ] Copiar a android/app/
- [ ] Agregar endpoint /api/verify-teacher al backend
- [ ] Configurar DB_CONFIG
- [ ] Instalar psycopg2
- [ ] Actualizar android/build.gradle.kts
- [ ] Actualizar android/app/build.gradle.kts
- [ ] flutter run
- [ ] Probar login

---

**Tiempo total**: ~30 minutos
**Dificultad**: Media
**Prerequisitos**: Cuenta Google Cloud, Servidor Flask corriendo
