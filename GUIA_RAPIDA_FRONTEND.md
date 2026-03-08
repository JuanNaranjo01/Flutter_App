# 🚀 GUÍA RÁPIDA PARA FRONTEND - 5 MINUTOS

**Para:** Desarrollador Frontend (Flutter)  
**De:** Desarrollador Backend  
**Fecha:** 27 de Febrero 2026

---

## 📌 TL;DR (Resumen Ultra Rápido)

Hay **4 endpoints nuevos** bajo la ruta `/api/flutter/` que debes usar para el sistema de asistencias:

1. **Diagnóstico** → Verificar BD (solo debug)
2. **Listado** → Pantalla principal con estudiantes
3. **Detalle** → Perfil del estudiante (todo el historial)
4. **Faltas** → Perfil del estudiante (solo tardanzas y ausencias)

**Todos soportan filtros:** año, semestre, corte, fecha

---

## 🎯 LOS 4 ENDPOINTS QUE NECESITAS

### 1️⃣ **DIAGNÓSTICO** (Opcional - Solo Debug)
```http
GET http://servidor:5000/api/flutter/diagnostico-bd
```
**Úsalo cuando:** Quieras verificar si la BD está bien configurada  
**Autenticación:** NO requiere  
**Respuesta:** Estado de la BD, totales de registros, warnings

---

### 2️⃣ **LISTADO DE ESTUDIANTES** ⭐ (PRINCIPAL)
```http
POST http://servidor:5000/api/flutter/curso/{id_curso}/estudiantes
```

**Body:**
```json
{
  "session_token": "tu-token-aqui",
  
  // FILTROS OPCIONALES (puedes enviar uno, varios o ninguno)
  "año": 2026,
  "semestre": "1",
  "corte": 1,
  "fecha": "2026-02-27"
}
```

**Respuesta:**
```json
{
  "success": true,
  "estudiantes": [
    {
      "codigo_estudiante": "320252057",
      "nombre_completo": "JUAN PÉREZ",
      "programa_academico": "ADMIN EMPRESAS",
      "estadisticas": {
        "total_clases": 15,
        "presentes": 12,
        "tardanzas": 2,
        "ausencias": 1,
        "total_faltas": 3,
        "porcentaje_asistencia": 93.33
      }
    }
  ],
  "total_estudiantes": 35
}
```

**Úsalo para:** Pantalla principal del listado de asistencias

---

### 3️⃣ **DETALLE DEL ESTUDIANTE** (Todo el Historial)
```http
POST http://servidor:5000/api/flutter/curso/{id_curso}/estudiante/{codigo}/detalle
```

**Body:**
```json
{
  "session_token": "tu-token-aqui",
  // Los mismos filtros opcionales del listado
  "año": 2026,
  "semestre": "1",
  "corte": 1
}
```

**Respuesta:**
```json
{
  "success": true,
  "estudiante": {
    "codigo_estudiante": "320252057",
    "nombre_completo": "JUAN PÉREZ"
  },
  "asistencias": [
    {
      "fecha_formateada": "20/02/2026",
      "hora_formateada": "10:45",
      "dia_semana": "Jueves",
      "estado": "presente",
      "descripcion_estado": "Presente"
    },
    {
      "fecha_formateada": "22/02/2026",
      "hora_formateada": "11:00",
      "dia_semana": "Sábado",
      "estado": "tardanza",
      "minutos_tardanza": 20,
      "descripcion_estado": "Tardanza (20 minutos)"
    }
  ],
  "resumen": {
    "presentes": 12,
    "tardanzas": 2,
    "ausencias": 1,
    "porcentaje_asistencia": 93.33
  }
}
```

**Úsalo para:** Mostrar TODO el historial en el perfil (presentes + tardanzas + ausencias)

---

### 4️⃣ **SOLO FALTAS DEL ESTUDIANTE**
```http
POST http://servidor:5000/api/flutter/curso/{id_curso}/estudiante/{codigo}/faltas
```

**Body:**
```json
{
  "session_token": "tu-token-aqui",
  // Los mismos filtros opcionales
}
```

**Respuesta:**
```json
{
  "success": true,
  "faltas": [
    {
      "fecha_formateada": "22/02/2026",
      "dia_semana": "Sábado",
      "tipo": "tardanza",
      "minutos_tardanza": 20,
      "descripcion": "Llegó 20 minutos tarde",
      "horas_falta_equivalentes": 0.5
    },
    {
      "fecha_formateada": "25/02/2026",
      "dia_semana": "Martes",
      "tipo": "ausente",
      "descripcion": "Ausente toda la clase (100 minutos)",
      "horas_falta_equivalentes": 3.0
    }
  ],
  "total_faltas": 2,
  "resumen": {
    "total_tardanzas": 1,
    "total_ausencias": 1,
    "total_horas_falta_acumuladas": 3.5
  }
}
```

**Úsalo para:** Mostrar SOLO las faltas en el perfil (sin presentes)

---

## 🎨 FLUJO DE LA APLICACIÓN

```
📱 Usuario abre "Asistencias"
    ↓
📋 Llamas: POST /flutter/curso/{id}/estudiantes
    (Sin filtros → muestra periodo actual)
    ↓
    Muestras lista de estudiantes
    ↓
👤 Usuario hace click en un estudiante
    ↓
📄 Llamas: POST /flutter/curso/{id}/estudiante/{codigo}/detalle
    (Con los mismos filtros del listado)
    ↓
    Muestras perfil con historial completo
    
    OPCIONAL: También puedes llamar
    ❌ POST /flutter/curso/{id}/estudiante/{codigo}/faltas
       Para mostrar SOLO las faltas en una sección separada
```

---

## 🔍 FILTROS

**Reglas:**
- **Sin filtros** → Muestra el periodo actual automáticamente
- **año + semestre** → Filtra estudiantes de ese periodo
- **corte** → DEBES enviar también año y semestre
- **fecha** → Muestra solo asistencias de esa fecha exacta

**Ejemplos:**

```dart
// Sin filtros (periodo actual)
{
  "session_token": token
}

// Filtrar por periodo y corte
{
  "session_token": token,
  "año": 2026,
  "semestre": "1",
  "corte": 1
}

// Filtrar por fecha específica
{
  "session_token": token,
  "fecha": "2026-02-27"
}
```

---

## 📊 REGLA DE CÁLCULO DE FALTAS

```
Llegada          | Faltas
-----------------|--------
0-15 min         | 0 horas (Presente)
16-40 min        | 1 hora (Tardanza)
41-80 min        | 2 horas (Tardanza)
Cada 40 min      | +1 hora
Ausente completo | Todas las horas de la clase
```

**Fórmula:** `horas_falta = minutos_tardanza / 40`

---

## ⚠️ MANEJO DE ERRORES

```dart
// Códigos de estado
200 → Éxito
401 → Token inválido/expirado → Volver a login
403 → Sin acceso al curso → Mostrar mensaje
404 → Recurso no encontrado → Verificar IDs
500 → Error del servidor → Mostrar mensaje genérico

// Ejemplo
try {
  final response = await http.post(...);
  if (response.statusCode == 200) {
    // Procesar datos
  } else if (response.statusCode == 401) {
    // Sesión expirada → Volver a login
  } else if (response.statusCode == 403) {
    // No tiene acceso
  }
} catch (e) {
  // Error de conexión
}
```

---

## 🔑 AUTENTICACIÓN

**IMPORTANTE:** El `session_token` se envía en el **BODY**, NO en headers.

```dart
// ✅ CORRECTO
final body = {
  'session_token': miToken,
  'año': 2026
};

await http.post(
  url,
  headers: {'Content-Type': 'application/json'},
  body: json.encode(body)
);

// ❌ INCORRECTO
headers: {'Authorization': 'Bearer $token'}  // NO hagas esto
```

---

## 💻 CÓDIGO DE EJEMPLO FLUTTER

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AsistenciasService {
  final String baseUrl = 'http://TU_SERVIDOR:5000/api/flutter';
  
  // Listado de estudiantes
  Future<Map<String, dynamic>> getEstudiantes({
    required int idCurso,
    required String token,
    int? año,
    String? semestre,
    int? corte,
  }) async {
    final body = {'session_token': token};
    if (año != null) body['año'] = año;
    if (semestre != null) body['semestre'] = semestre;
    if (corte != null) body['corte'] = corte;
    
    final response = await http.post(
      Uri.parse('$baseUrl/curso/$idCurso/estudiantes'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Sesión expirada');
    } else {
      throw Exception('Error: ${response.statusCode}');
    }
  }
  
  // Detalle de estudiante
  Future<Map<String, dynamic>> getDetalle({
    required int idCurso,
    required String codigo,
    required String token,
    int? año,
    String? semestre,
    int? corte,
  }) async {
    final body = {'session_token': token};
    if (año != null) body['año'] = año;
    if (semestre != null) body['semestre'] = semestre;
    if (corte != null) body['corte'] = corte;
    
    final response = await http.post(
      Uri.parse('$baseUrl/curso/$idCurso/estudiante/$codigo/detalle'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode}');
    }
  }
}

// Uso:
final service = AsistenciasService();

// Obtener listado
final datos = await service.getEstudiantes(
  idCurso: 5,
  token: miToken,
  año: 2026,
  semestre: '1',
  corte: 1,
);

List<dynamic> estudiantes = datos['estudiantes'];
```

---

## 🧪 PRUEBA RÁPIDA (1 minuto)

Antes de implementar, prueba el diagnóstico:

```bash
# En tu navegador o Postman
GET http://IP_DEL_SERVIDOR_LINUX:5000/api/flutter/diagnostico-bd
# Reemplaza IP_DEL_SERVIDOR_LINUX con la IP real (ej: 192.168.1.100)

# Debes ver:
{
  "success": true,
  "totales": {
    "estudiantes_activos": 45,
    "matriculas_activas": 120,
    ...
  },
  "warnings": null  ← No debe haber warnings
}
```

Si hay warnings → Lee el archivo `RESUMEN_SISTEMA_ASISTENCIAS.md` sección "Problemas Comunes"

---

## 📋 CHECKLIST RÁPIDO

Para implementar el listado de asistencias:

- [ ] Obtengo el session_token del login
- [ ] Creo el servicio `AsistenciasService`
- [ ] Implemento la pantalla de listado
  - [ ] Llamo a `/flutter/curso/{id}/estudiantes`
  - [ ] Muestro lista de estudiantes
  - [ ] Implemento filtros (año, semestre, corte)
- [ ] Implemento la pantalla de perfil
  - [ ] Llamo a `/flutter/curso/{id}/estudiante/{codigo}/detalle`
  - [ ] Muestro historial completo
  - [ ] (Opcional) Llamo a `/faltas` para mostrar solo faltas
- [ ] Manejo errores 401, 403, 404, 500
- [ ] Pruebo el flujo completo

---

## 🆘 SI ALGO NO FUNCIONA

1. **Ejecuta el diagnóstico:** `GET /api/flutter/diagnostico-bd`
2. **Verifica errores comunes:**
   - 401 → Token expirado o inválido
   - 403 → El docente no tiene acceso al curso
   - 404 → ID de curso o código de estudiante no existe
   - 500 → Error del servidor, revisar logs
3. **Lee la documentación completa:** `DOCUMENTACION_FLUTTER_ASISTENCIAS.md`

---

## 📚 MÁS INFORMACIÓN

- **Documentación completa:** `DOCUMENTACION_FLUTTER_ASISTENCIAS.md` (30 min de lectura)
- **Resumen ejecutivo:** `RESUMEN_SISTEMA_ASISTENCIAS.md` (10 min de lectura)
- **Script de pruebas:** `PRUEBAS_ENDPOINTS_FLUTTER.ps1` (para probar endpoints)

---

## ✅ ESO ES TODO

Con esto ya sabes **exactamente** qué hacer:
1. Crea el servicio con los 4 endpoints
2. Implementa la pantalla de listado
3. Implementa la pantalla de perfil
4. Agrega filtros
5. Maneja errores

**¡Éxito!** 🚀

---

_¿Dudas? Pregunta al backend o lee la documentación completa._
