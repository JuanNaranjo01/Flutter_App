# 📘 GUÍA DE INTEGRACIÓN - ENDPOINT DE ESTUDIANTES POR CURSO

## 🎯 Para: Equipo Frontend Flutter
## 📅 Fecha: 26 de Febrero 2026
## 🔧 Versión Backend: Corregida y Optimizada

---

## 📌 RESUMEN EJECUTIVO

Este endpoint permite listar los estudiantes de un curso con sus estadísticas de asistencia.
Soporta filtros opcionales por **periodo académico** y **corte** (parcial).

**Cambios principales vs versión anterior:**
- ✅ Ahora incluye `horas_faltadas`, `minutos_tardanza` y `tardanzas`
- ✅ Los filtros por periodo y corte funcionan correctamente
- ✅ Valida que el corte haya empezado antes de permitir filtrarlo
- ✅ Aplica política institucional de horas faltadas correctamente

---

## 🔌 ENDPOINT

```
POST /api/teacher/course/{id_curso}/students
```

**URL completa ejemplo:**
```
http://192.168.14.25:5001/api/teacher/course/300/students
```

---

## 📥 REQUEST

### Headers
```json
{
  "Content-Type": "application/json"
}
```

### Body Parameters

| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| `session_token` | String | ✅ Sí | Token de sesión del docente |
| `año` | Integer | ❌ No | Año del periodo (ej: 2026) |
| `semestre` | String | ❌ No | Semestre ("1" o "2") |
| `corte` | Integer | ❌ No | Número de corte (1, 2, o 3) |

### Reglas de Validación

⚠️ **IMPORTANTE:**
- Si envías `corte`, DEBES enviar también `año` y `semestre`
- El backend validará que el corte solicitado ya haya empezado
- Si el corte no ha empezado, recibirás un error 400 con las fechas

---

## 📤 RESPONSE

### Respuesta Exitosa (200 OK)

```json
{
  "success": true,
  "students": [
    {
      "codigo_estudiante": "320252057",
      "nombre_completo": "JUAN PÉREZ GARCÍA",
      "programa_academico": "Ingeniería de Sistemas",
      "email_institucional": "juan.perez@ejemplo.edu.co",
      "semestre": 5,
      "estadisticas": {
        "total_clases": 10,
        "presentes": 7,
        "tardanzas": 2,
        "ausencias": 1,
        "horas_faltadas": 5.83,
        "minutos_tardanza": 150,
        "porcentaje_asistencia": 90.0
      }
    }
  ],
  "filtros_aplicados": {
    "año": 2026,
    "semestre": "1",
    "corte": 1,
    "fecha_inicio": "2026-01-20",
    "fecha_fin": "2026-03-15"
  }
}
```

### Campos Importantes

#### 📊 `estadisticas` - Explicación de cada campo:

| Campo | Tipo | Qué significa |
|-------|------|---------------|
| `total_clases` | Integer | Total de clases registradas (presentes + tardanzas + ausencias) |
| `presentes` | Integer | Clases donde llegó a tiempo (dentro de 15 min tolerancia) |
| `tardanzas` | Integer | Clases donde llegó tarde (después de 15 min) |
| `ausencias` | Integer | Clases donde no asistió |
| `horas_faltadas` | Float | **Total de horas perdidas** (ausencias completas + horas de tardanza) |
| `minutos_tardanza` | Integer | Total de minutos acumulados de llegadas tarde |
| `porcentaje_asistencia` | Float | Porcentaje: (presentes + tardanzas) / total * 100 |

---

## 🎓 POLÍTICA INSTITUCIONAL DE HORAS FALTADAS

### ⚠️ IMPORTANTE: Cómo se calculan las horas faltadas

La universidad tiene una política específica sobre tardanzas:

#### 1️⃣ Tolerancia: 15 minutos
- **0-15 min tarde** → `presente` (sin penalización)
- **16+ min tarde** → `tardanza` (con penalización)

#### 2️⃣ Las tardanzas SÍ suman horas faltadas

**Fórmula:** `horas_faltadas = minutos_tardanza / 60`

**Ejemplos reales:**

| Minutos tarde | Estado | Horas faltadas | Explicación |
|---------------|--------|----------------|-------------|
| 10 min | presente | 0 | Dentro de tolerancia |
| 45 min | tardanza | 0.75 | Llegó 45 min tarde = 0.75h de falta |
| 55 min | tardanza | 0.92 | Llegó 55 min tarde = casi 1h de falta |
| 80 min | tardanza | 1.33 | Llegó 1h 20min tarde = 1.33h de falta |
| 218 min | tardanza | 3.63 | Llegó 3h 38min tarde = 3.63h de falta |
| No asistió | ausente | 3.0 | Clase de 3h = 3h de falta |

#### 3️⃣ Impacto en suspensión

```
Total de horas faltadas = horas de ausencias + horas de tardanzas
Porcentaje de fallas = (horas_faltadas / horas_totales_periodo) * 100

Si porcentaje > 20% → RIESGO DE SUSPENSIÓN
```

**Ejemplo:**
- Periodo: 30 horas totales
- Ausencias: 2 clases de 3h = 6h
- Tardanzas: 2 llegadas de 60 min c/u = 2h
- **Total faltado:** 8h de 30h = 26.6% → ⚠️ SUSPENSIÓN

---

## 📋 EJEMPLOS DE USO EN FLUTTER

### Caso 1: Sin filtros (todos los estudiantes, todo el histórico)

```dart
Future<List<Student>> getCourseStudents(int courseId, String token) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/teacher/course/$courseId/students'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'session_token': token,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
      return (data['students'] as List)
          .map((json) => Student.fromJson(json))
          .toList();
    }
  }
  throw Exception('Error al obtener estudiantes');
}
```

### Caso 2: Filtrar por periodo (año + semestre)

```dart
Future<List<Student>> getCourseStudentsByPeriod(
  int courseId, 
  String token,
  int year,
  String semester,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/teacher/course/$courseId/students'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'session_token': token,
      'año': year,
      'semestre': semester,
    }),
  );
  
  // ... manejar respuesta
}
```

### Caso 3: Filtrar por corte específico

```dart
Future<List<Student>> getCourseStudentsByCorte(
  int courseId, 
  String token,
  int year,
  String semester,
  int corte,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/teacher/course/$courseId/students'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'session_token': token,
      'año': year,
      'semestre': semester,
      'corte': corte, // 1, 2, o 3
    }),
  );
  
  if (response.statusCode == 400) {
    // El corte no ha empezado aún
    final error = jsonDecode(response.body);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Corte no disponible'),
        content: Text(error['error']),
      ),
    );
    return [];
  }
  
  // ... manejar respuesta exitosa
}
```

---

## ⚠️ MANEJO DE ERRORES

### Error 400: Validación fallida

```json
{
  "success": false,
  "error": "Para filtrar por corte debe especificar año y semestre"
}
```

**Cuándo ocurre:** Enviaste `corte` sin `año` o `semestre`

---

```json
{
  "success": false,
  "error": "El corte 2 del periodo 2026-1 aún no ha empezado",
  "fecha_inicio_corte": "2026-03-16",
  "fecha_actual": "2026-02-26"
}
```

**Cuándo ocurre:** Intentas filtrar por un corte que no ha empezado

**Qué hacer:** Mostrar mensaje al usuario con las fechas

---

### Error 404: Periodo no encontrado

```json
{
  "success": false,
  "error": "No existe el periodo 2027-2"
}
```

**Cuándo ocurre:** El periodo especificado no está configurado en la BD

---

### Error 500: Error interno del servidor

```json
{
  "success": false,
  "error": "Error al obtener estudiantes: ..."
}
```

**Cuándo ocurre:** Error inesperado (contactar backend)

---

## 🧮 LÓGICA DE NEGOCIO QUE DEBEN CONOCER

### 1️⃣ Reglas de Estado de Asistencia

| Estado | horas_faltadas | minutos_tardanza | Lógica |
|--------|---------------|------------------|--------|
| **presente** | 0 | 0 | Llegó a tiempo (0-15 min tolerancia) |
| **tardanza** | minutos/60 | > 0 | Llegó tarde → convierte minutos a horas |
| **ausente** | duración_clase | 0 | No asistió → suma toda la clase |

✅ **Validaciones esperadas:**
- `presente` → `horas_faltadas = 0` y `minutos_tardanza = 0`
- `tardanza` → `horas_faltadas = minutos_tardanza/60` y `minutos_tardanza > 0`
- `ausente` → `horas_faltadas > 0` y `minutos_tardanza = 0`

### 2️⃣ Cálculo de Porcentaje de Asistencia

```
porcentaje_asistencia = (presentes + tardanzas) / total_clases * 100
```

**Ejemplo:**
- Total: 10 clases
- Presentes: 7
- Tardanzas: 2
- Ausencias: 1
- **Resultado:** (7 + 2) / 10 * 100 = **90%**

⚠️ **Las tardanzas SÍ cuentan como asistencia** (el estudiante sí fue a clase)  
⚠️ **PERO las tardanzas TAMBIÉN suman horas faltadas** (penalización por impuntualidad)

### 3️⃣ Alerta de Suspensión

```dart
double calcularPorcentajeFallas(double horasFaltadas, double horasTotales) {
  if (horasTotales == 0) return 0;
  return (horasFaltadas / horasTotales) * 100;
}

String getAttendanceStatus(double porcentajeFallas) {
  if (porcentajeFallas <= 10) return '✅ Excelente';
  if (porcentajeFallas <= 20) return '⚠️ Aceptable';
  return '❌ RIESGO DE SUSPENSIÓN';
}
```

**Nota:** Un estudiante puede tener 90% de asistencia pero >20% de fallas por tardanzas largas.

---

## 🎨 SUGERENCIAS DE UI

### Visualización de Estadísticas

```
┌─────────────────────────────────────────┐
│ 📊 Estadísticas de Juan Pérez           │
├─────────────────────────────────────────┤
│ Total de clases:       10               │
│ ✅ Presentes:          7 (70%)          │
│ ⏰ Tardanzas:          2 (20%)          │
│ ❌ Ausencias:          1 (10%)          │
│                                         │
│ ⚠️ Horas faltadas:     5.83h            │
│    - Por ausencias:    3.0h             │
│    - Por tardanzas:    2.83h (170 min)  │
│                                         │
│ Asistencia:            90% ✅           │
│ Fallas del periodo:    19.4% ⚠️         │
└─────────────────────────────────────────┘
```

### Indicadores Visuales

```dart
Color getFallasColor(double porcentajeFallas) {
  if (porcentajeFallas <= 10) return Colors.green;
  if (porcentajeFallas <= 20) return Colors.orange;
  return Colors.red;
}

IconData getFallasIcon(double porcentajeFallas) {
  if (porcentajeFallas <= 10) return Icons.check_circle;
  if (porcentajeFallas <= 20) return Icons.warning;
  return Icons.error;
}

// Widget de alerta
Widget buildAlertaBanner(double horasFaltadas, double horasTotales) {
  double porcentaje = (horasFaltadas / horasTotales) * 100;
  
  if (porcentaje > 20) {
    return Container(
      color: Colors.red,
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.white),
          SizedBox(width: 8),
          Text(
            '⚠️ RIESGO DE SUSPENSIÓN: ${porcentaje.toStringAsFixed(1)}% de fallas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  return SizedBox.shrink();
}
```

---

## 🔄 FLUJO RECOMENDADO

```
1. Usuario abre pantalla de curso
   ↓
2. Flutter hace request SIN filtros
   ↓
3. Mostrar lista completa de estudiantes
   ↓
4. Destacar estudiantes en riesgo (>20% fallas)
   ↓
5. Usuario selecciona filtros (opcional):
   - Año + Semestre
   - O Año + Semestre + Corte
   ↓
6. Flutter hace nuevo request CON filtros
   ↓
7. Si corte no empezó: mostrar error
8. Si OK: actualizar lista con datos filtrados
```

---

## 🧪 TESTING

### Test Case 1: Lista completa
```
REQUEST: { session_token: "abc123" }
EXPECT: Lista de todos los estudiantes matriculados
STATUS: 200
```

### Test Case 2: Filtro por periodo
```
REQUEST: { session_token: "abc123", año: 2026, semestre: "1" }
EXPECT: Solo estadísticas del periodo 2026-1
STATUS: 200
```

### Test Case 3: Validar horas faltadas
```
CASO: Estudiante con 2 tardanzas de 60 min + 1 ausencia de 3h
EXPECT: 
  - tardanzas: 2
  - ausencias: 1  
  - horas_faltadas: 5.0 (2h de tardanzas + 3h de ausencia)
  - minutos_tardanza: 120
```

### Test Case 4: Corte no empezado
```
REQUEST: { session_token: "abc123", año: 2026, semestre: "1", corte: 3 }
EXPECT: Error con fecha_inicio_corte y fecha_actual
STATUS: 400
```

---

## 📞 CONTACTO Y SOPORTE

**Si encuentran algún problema:**

1. ✅ Verificar que enviaron `session_token` válido
2. ✅ Revisar la consola del servidor (verán logs con 📊 y ❌)
3. ✅ Verificar que los filtros cumplan las reglas de validación
4. ✅ Confirmar que las horas_faltadas tienen sentido con las tardanzas
5. ❌ Si el error persiste: compartir el request completo y el error exacto

**Backend está monitoreando:** Todos los requests dejan logs con el formato `📊 Query con parámetros: {...}`

---

## ✨ RESUMEN FINAL

| Aspecto | Estado |
|---------|--------|
| Endpoint funcional | ✅ Sí |
| Filtros implementados | ✅ Sí (periodo + corte) |
| Validaciones | ✅ Sí (corte empezado, params requeridos) |
| Política institucional aplicada | ✅ Sí (tardanzas = horas faltadas) |
| Documentación | ✅ Este documento |

**Todo está listo para su integración. ¡Manos a la obra!** 🚀
