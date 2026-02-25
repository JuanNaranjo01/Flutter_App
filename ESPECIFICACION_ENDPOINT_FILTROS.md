# 📋 Especificación: Modificación del Endpoint para Filtros

## Endpoint a Modificar

**POST** `/api/teacher/course/:id/students`

## Descripción

Este endpoint debe ser modificado para aceptar parámetros opcionales de filtrado por **periodo académico** y **corte**, permitiendo a los docentes consultar las estadísticas de asistencia de sus estudiantes filtradas por estos criterios.

---

## Request Body Actual vs Modificado

### ❌ Actual (solo session_token)
```json
{
  "session_token": "abc123xyz"
}
```

### ✅ Modificado (con filtros opcionales)
```json
{
  "session_token": "abc123xyz",
  "año": 2026,           // OPCIONAL - Año del periodo
  "semestre": "1",       // OPCIONAL - Semestre ("1" o "2")
  "corte": 1             // OPCIONAL - Número de corte (1, 2 o 3)
}
```

---

## Parámetros del Body

| Parámetro | Tipo | Requerido | Descripción | Ejemplo |
|-----------|------|-----------|-------------|---------|
| `session_token` | string | ✅ Sí | Token de sesión del docente | `"abc123xyz"` |
| `año` | integer | ❌ No | Año del periodo académico | `2026` |
| `semestre` | string | ❌ No | Semestre del periodo ("1" o "2") | `"1"` |
| `corte` | integer | ❌ No | Número del corte (1, 2 o 3) | `1` |

---

## Lógica del Filtrado

### Caso 1: Sin filtros (comportamiento actual)
```json
{
  "session_token": "token"
}
```
**Resultado:** Retorna TODOS los estudiantes del curso con sus estadísticas generales de asistencia (sin filtrar por periodo/corte).

---

### Caso 2: Filtro por periodo (año + semestre)
```json
{
  "session_token": "token",
  "año": 2026,
  "semestre": "1"
}
```
**Resultado:** Retorna los estudiantes del curso con estadísticas de asistencia correspondientes **solo al periodo 2026-1** (todos los cortes de ese periodo).

---

### Caso 3: Filtro por periodo y corte específico
```json
{
  "session_token": "token",
  "año": 2026,
  "semestre": "1",
  "corte": 1
}
```
**Resultado:** Retorna los estudiantes del curso con estadísticas de asistencia correspondientes **solo al corte 1 del periodo 2026-1**.

---

## Response Esperado

La respuesta debe mantener la estructura actual pero con las estadísticas filtradas:

```json
{
  "success": true,
  "students": [
    {
      "codigo": "320252057",
      "nombre_completo": "JUAN PÉREZ GARCÍA",
      "programa": "INGENIERÍA DE SISTEMAS",
      "asistencias": 12,        // Asistencias en el periodo/corte filtrado
      "tardanzas": 2,            // Tardanzas en el periodo/corte filtrado
      "ausencias": 1,            // Ausencias en el periodo/corte filtrado
      "total_clases": 15,        // Total de clases en el periodo/corte filtrado
      "porcentaje_asistencia": 93.33
    },
    {
      "codigo": "320252058",
      "nombre_completo": "MARÍA LÓPEZ FERNÁNDEZ",
      "programa": "INGENIERÍA CIVIL",
      "asistencias": 14,
      "tardanzas": 1,
      "ausencias": 0,
      "total_clases": 15,
      "porcentaje_asistencia": 100.0
    }
  ],
  "total": 2
}
```

---

## Consideraciones Importantes

### 1️⃣ Filtrado en Base de Datos
Las estadísticas (asistencias, tardanzas, ausencias, total_clases, porcentaje) deben calcularse **solo con los registros que cumplan los criterios del filtro**.

### 2️⃣ Relación con Tabla de Periodos
Utilizar las tablas:
- `periodos_academicos` - Para obtener año y semestre
- `cortes` - Para obtener las fechas de inicio y fin de cada corte

### 3️⃣ Query SQL de Ejemplo
```sql
SELECT 
    e.codigo,
    e.nombre_completo,
    e.programa,
    COUNT(CASE WHEN a.estado = 'presente' THEN 1 END) as asistencias,
    COUNT(CASE WHEN a.estado = 'tardanza' THEN 1 END) as tardanzas,
    COUNT(CASE WHEN a.estado = 'ausente' THEN 1 END) as ausencias,
    COUNT(*) as total_clases,
    (COUNT(CASE WHEN a.estado = 'presente' OR a.estado = 'tardanza' THEN 1 END) * 100.0 / COUNT(*)) as porcentaje_asistencia
FROM estudiantes e
LEFT JOIN asistencias a ON e.codigo = a.codigo_estudiante
LEFT JOIN cursos c ON a.id_curso = c.id_curso
WHERE c.id_curso = :id_curso
  AND (:año IS NULL OR YEAR(a.fecha) = :año)
  AND (:semestre IS NULL OR /* lógica para determinar semestre */)
  AND (:corte IS NULL OR /* fecha entre corte.fecha_inicio y corte.fecha_fin */)
GROUP BY e.codigo, e.nombre_completo, e.programa
```

### 4️⃣ Compatibilidad hacia atrás
Si **no se envían los parámetros opcionales**, el endpoint debe funcionar **exactamente igual que antes** (retornando todas las estadísticas sin filtrar).

---

## Ejemplo de Uso desde Flutter

```dart
// Sin filtros
final students = await ApiService.getCourseStudents(
  sessionToken,
  courseId,
);

// Con filtro de periodo
final students = await ApiService.getCourseStudents(
  sessionToken,
  courseId,
  anio: 2026,
  semestre: "1",
);

// Con filtro de periodo y corte
final students = await ApiService.getCourseStudents(
  sessionToken,
  courseId,
  anio: 2026,
  semestre: "1",
  corte: 1,
);
```

---

## Validaciones Requeridas

1. ✅ `año` debe ser un número entero válido (2020-2030)
2. ✅ `semestre` debe ser "1" o "2"
3. ✅ `corte` debe ser 1, 2 o 3
4. ✅ Si se envía `corte`, debe enviarse también `año` y `semestre`
5. ✅ Validar que el periodo/corte exista en la base de datos

---

## Códigos de Error

| Código | Descripción |
|--------|-------------|
| 200 | Exitoso |
| 400 | Parámetros inválidos (ej: semestre "3", corte "5") |
| 401 | Session token inválido o expirado |
| 404 | Curso no encontrado o periodo/corte no existe |
| 500 | Error interno del servidor |

---

## Testing Recomendado

### Test 1: Sin filtros
```bash
curl -X POST http://localhost/api/teacher/course/1/students \
  -H "Content-Type: application/json" \
  -d '{"session_token": "token123"}'
```

### Test 2: Con filtro de periodo
```bash
curl -X POST http://localhost/api/teacher/course/1/students \
  -H "Content-Type: application/json" \
  -d '{"session_token": "token123", "año": 2026, "semestre": "1"}'
```

### Test 3: Con filtro de corte
```bash
curl -X POST http://localhost/api/teacher/course/1/students \
  -H "Content-Type: application/json" \
  -d '{"session_token": "token123", "año": 2026, "semestre": "1", "corte": 1}'
```

---

## Notas Adicionales

- El frontend ya está preparado para enviar estos parámetros
- Los modelos de Flutter están listos
- La UI tiene los dropdowns de filtro implementados
- Solo falta la implementación en el backend

---

**Implementado por:** Frontend - Flutter  
**Pendiente:** Backend - Python/Flask  
**Fecha:** Febrero 2026
