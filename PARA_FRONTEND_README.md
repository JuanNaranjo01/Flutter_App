# 📱 PARA EL FRONTEND - LEE ESTO (2 MINUTOS)

> **Resumen:** 4 endpoints nuevos, rutas diferentes, sin conflicto, mejor documentados.

---

## 🎯 LO QUE NECESITAS SABER

### ¿Hay conflicto con endpoints anteriores?
**NO.** Las rutas son diferentes:
- Viejos: `/api/teacher/course/...` ✅ Siguen funcionando
- Nuevos: `/api/flutter/curso/...` ✅ Recomendados

### ¿Cuáles debo usar?
**Los nuevos** `/api/flutter/...` porque:
- ✅ Mejor documentados
- ✅ Respuestas más claras
- ✅ Incluyen tardanzas en las faltas (los viejos no)
- ✅ Fechas pre-formateadas

### ¿Tengo que cambiar mi código existente?
**NO.** Solo usa los nuevos para código nuevo.

---

## 🚀 LOS 4 ENDPOINTS (Copy-Paste Ready)

### 1️⃣ Listado (Pantalla Principal)
```http
POST http://servidor:5000/api/flutter/curso/{id_curso}/estudiantes

Body:
{
  "session_token": "tu-token",
  "año": 2026,          // Opcional
  "semestre": "1",      // Opcional
  "corte": 1           // Opcional
}

Respuesta:
{
  "estudiantes": [
    {
      "codigo_estudiante": "320252057",
      "nombre_completo": "JUAN PÉREZ",
      "estadisticas": {
        "total_faltas": 3,
        "porcentaje_asistencia": 93.33
      }
    }
  ]
}
```

---

### 2️⃣ Detalle (Perfil - Todo el Historial)
```http
POST http://servidor:5000/api/flutter/curso/{id_curso}/estudiante/{codigo}/detalle

Body:
{
  "session_token": "tu-token"
}

Respuesta:
{
  "asistencias": [
    {
      "fecha_formateada": "20/02/2026",
      "dia_semana": "Jueves",
      "estado": "presente",
      "descripcion_estado": "Presente"
    },
    {
      "fecha_formateada": "22/02/2026",
      "estado": "tardanza",
      "descripcion_estado": "Tardanza (20 minutos)"
    }
  ],
  "resumen": {
    "presentes": 12,
    "tardanzas": 2,
    "ausencias": 1
  }
}
```

---

### 3️⃣ Faltas (Perfil - Solo Tardanzas + Ausencias)
```http
POST http://servidor:5000/api/flutter/curso/{id_curso}/estudiante/{codigo}/faltas

Body:
{
  "session_token": "tu-token"
}

Respuesta:
{
  "faltas": [
    {
      "fecha_formateada": "22/02/2026",
      "tipo": "tardanza",
      "descripcion": "Llegó 20 minutos tarde",
      "horas_falta_equivalentes": 0.5
    }
  ],
  "resumen": {
    "total_tardanzas": 1,
    "total_ausencias": 1,
    "total_horas_falta_acumuladas": 3.5
  }
}
```

---

### 4️⃣ Diagnóstico (Debug)
```http
GET http://servidor:5000/api/flutter/diagnostico-bd

Sin autenticación

Respuesta:
{
  "success": true,
  "totales": {
    "estudiantes_activos": 45,
    "matriculas_activas": 120
  },
  "warnings": null  ← Debe ser null
}
```

---

## 💻 CÓDIGO FLUTTER (Copy-Paste)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AsistenciasService {
  final String baseUrl = 'http://TU_SERVIDOR:5000/api/flutter';
  
  Future<List<dynamic>> getEstudiantes(int idCurso, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/curso/$idCurso/estudiantes'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'session_token': token}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['estudiantes'];
    } else {
      throw Exception('Error ${response.statusCode}');
    }
  }
  
  Future<Map<String, dynamic>> getDetalle(
    int idCurso, 
    String codigo, 
    String token
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/curso/$idCurso/estudiante/$codigo/detalle'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'session_token': token}),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}');
    }
  }
}
```

---

## 🎨 FLUJO DE PANTALLAS

```
┌─────────────────────────────────────┐
│  📋 PANTALLA: Listado Asistencias  │
│                                     │
│  GET /flutter/curso/5/estudiantes   │
│                                     │
│  • JUAN PÉREZ      3 faltas         │
│  • MARÍA GÓMEZ     1 falta          │
│  • CARLOS RUIZ     0 faltas         │
│                                     │
│  [Filtros: Periodo, Corte, Fecha]   │
└─────────────────────────────────────┘
            │
            │ Usuario hace click
            ↓
┌─────────────────────────────────────┐
│  👤 PANTALLA: Perfil Estudiante     │
│                                     │
│  JUAN PÉREZ - 320252057             │
│                                     │
│  GET /flutter/.../detalle           │
│                                     │
│  📅 20/02/2026 - Presente           │
│  📅 22/02/2026 - Tardanza (20 min)  │
│  📅 25/02/2026 - Ausente            │
│                                     │
│  Resumen: 12 presentes, 3 faltas    │
└─────────────────────────────────────┘
```

---

## ⚡ QUICKSTART (5 Pasos)

1. **Copia el código Flutter** de arriba
2. **Cambia** `TU_SERVIDOR` por tu IP/dominio
3. **Llama** a `getEstudiantes(idCurso, token)`
4. **Muestra** la lista de estudiantes
5. **Al click**, llama a `getDetalle(idCurso, codigo, token)`

---

## 🔑 AUTENTICACIÓN

El `session_token` va en el **BODY** (no en headers):

```dart
// ✅ CORRECTO
body: json.encode({
  'session_token': miToken,
  'año': 2026
})

// ❌ INCORRECTO
headers: {'Authorization': 'Bearer $token'}
```

---

## 🎯 FILTROS

```dart
// Sin filtros (muestra periodo actual)
{'session_token': token}

// Con filtro de corte
{
  'session_token': token,
  'año': 2026,
  'semestre': '1',
  'corte': 1
}

// Con filtro de fecha
{
  'session_token': token,
  'fecha': '2026-02-27'
}
```

---

## ⚠️ ERRORES

```dart
200 → Todo OK
401 → Token expirado → Volver a login
403 → Sin acceso → Mostrar error
404 → No encontrado → Verificar IDs
500 → Error servidor → Reintentar
```

---

## 🧪 PRUEBA RÁPIDA

Antes de implementar, prueba esto en tu navegador:

```
http://IP_DEL_SERVIDOR_LINUX:5000/api/flutter/diagnostico-bd
```

> **Nota:** Reemplaza `IP_DEL_SERVIDOR_LINUX` con la IP real de tu servidor (ej: `192.168.1.100` o `servidor.dominio.com`)

Debe responder con `"success": true` y sin warnings.

---

## 📚 MÁS INFORMACIÓN

Si necesitas más detalles:
- **Guía rápida completa:** `GUIA_RAPIDA_FRONTEND.md`
- **Comparación endpoints:** `COMPARACION_ENDPOINTS.md`
- **Documentación técnica:** `DOCUMENTACION_FLUTTER_ASISTENCIAS.md`

---

## ✅ CHECKLIST

- [ ] Copié el código de `AsistenciasService`
- [ ] Cambié la URL base por la de mi servidor
- [ ] Implementé la pantalla de listado
- [ ] Implementé la pantalla de perfil
- [ ] Probé con el token de un docente real
- [ ] Los filtros funcionan correctamente
- [ ] Manejo los errores 401, 403, 404

---

## 🎉 ¡LISTO!

Con esto ya puedes implementar el sistema completo de asistencias.

**¿Dudas?** Pregunta o lee la documentación completa.

---

**Resumen en 3 líneas:**
1. Usa `/api/flutter/...` (nuevos endpoints)
2. Token en el body, no en headers
3. Copia el código de arriba y ajusta la URL

🚀 **¡A implementar!**
