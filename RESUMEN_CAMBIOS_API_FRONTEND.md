# 📱 PARA EL FRONTEND - Cambios en API de Asistencias

**Fecha:** 27 de Febrero 2026  
**Backend actualizado con 3 mejoras importantes**

---

## ✅ Cambio 1: Periodos y Cortes con Fechas Límite

### Endpoint: `GET /api/flutter/diagnostico-bd`

**Nuevo campo en la respuesta:**
```json
{
  "success": true,
  "periodos_disponibles": [
    {
      "id_periodo": 1,
      "año": 2026,
      "semestre": "1",
      "nombre_periodo": "2026-1",
      "fecha_inicio": "2026-02-01",
      "fecha_fin": "2026-06-30",
      "estado": "activo",
      "cortes": [
        {
          "numero": 1,
          "nombre": "Corte 1",
          "fecha_inicio": "2026-02-01",
          "fecha_fin": "2026-03-15"
        },
        {
          "numero": 2,
          "nombre": "Corte 2",
          "fecha_inicio": "2026-03-16",
          "fecha_fin": "2026-05-15"
        },
        {
          "numero": 3,
          "nombre": "Corte 3",
          "fecha_inicio": "2026-05-16",
          "fecha_fin": "2026-06-30"
        }
      ]
    }
  ]
}
```

**💡 Qué hacer con esto:**
- Llama a este endpoint **al iniciar la app**
- Guarda los periodos disponibles en memoria/state
- Usa esta info para construir tus selectores de periodo/corte
- Puedes validar qué corte está activo comparando la fecha actual con los rangos

**Ejemplo Flutter:**
```dart
class PeriodoService {
  List<Periodo> periodosDisponibles = [];
  
  Future<void> cargarPeriodos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/diagnostico-bd')
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      periodosDisponibles = (data['periodos_disponibles'] as List)
          .map((p) => Periodo.fromJson(p))
          .toList();
    }
  }
  
  // Detectar corte actual por fecha
  int? getCorteActual(DateTime fecha) {
    for (var periodo in periodosDisponibles) {
      if (periodo.estado == 'activo') {
        for (var corte in periodo.cortes) {
          if (fecha.isAfter(corte.fechaInicio) && 
              fecha.isBefore(corte.fechaFin)) {
            return corte.numero;
          }
        }
      }
    }
    return null;
  }
}
```

---

## ✅ Cambio 2: Tardanzas Cuentan como Asistencias

### Endpoints afectados:
- `POST /api/flutter/curso/{id}/estudiantes` (Listado)
- `POST /api/flutter/curso/{id}/estudiante/{codigo}/detalle` (Detalle)

### ❌ ANTES (confuso):
```json
{
  "estadisticas": {
    "presentes": 10,
    "tardanzas": 2,
    "ausencias": 1,
    "total_faltas": 3,  // tardanzas + ausencias (confuso)
    "porcentaje_asistencia": 92.31
  }
}
```

### ✅ AHORA (claro):
```json
{
  "estadisticas": {
    "asistencias_totales": 12,  // ← NUEVO: presentes + tardanzas
    "presentes": 10,
    "tardanzas": 2,
    "ausencias": 1,
    "total_faltas": 1,         // ← CAMBIADO: SOLO ausencias
    "porcentaje_asistencia": 92.31
  }
}
```

**💡 Cambios en tu UI:**

**ANTES mostrábamos:**
```dart
// ❌ Confuso
Text('Presentes: ${est.presentes}')      // 10
Text('Tardanzas: ${est.tardanzas}')      // 2
Text('Faltas: ${est.total_faltas}')      // 3
```

**AHORA debes mostrar:**
```dart
// ✅ Claro
Text('Asistencias: ${est.asistencias_totales}')  // 12 ← NUEVO CAMPO
Text('└ Puntuales: ${est.presentes}')            // 10
Text('└ Llegaron tarde: ${est.tardanzas}')       // 2
Text('Faltas (ausencias): ${est.total_faltas}')  // 1
```

**O más simple:**
```dart
Card(
  child: Column(
    children: [
      Text('✅ Asistió ${est.asistencias_totales} veces'),
      if (est.tardanzas > 0)
        Text('  (${est.tardanzas} con retraso)', style: TextStyle(fontSize: 12)),
      Text('❌ Faltó ${est.total_faltas} veces'),
    ],
  ),
)
```

**Lógica del cambio:**
- **Tardanza = Asistencia** (porque el estudiante llegó, aunque tarde)
- **Falta = Solo ausencias** (no apareció)
- Las tardanzas siguen visibles por separado para análisis

---

## ✅ Cambio 3: Horas de Falta Ahora Visibles

### Endpoint: `POST /api/flutter/curso/{id}/estudiante/{codigo}/detalle`

### Nuevos campos en cada registro:
```json
{
  "asistencias": [
    {
      "fecha_formateada": "20/02/2026",
      "estado": "presente",
      "horas_falta_equivalentes": 0.0  // ← NUEVO
    },
    {
      "fecha_formateada": "22/02/2026",
      "estado": "tardanza",
      "minutos_tardanza": 25,
      "horas_falta_equivalentes": 0.5  // ← NUEVO (25 min ÷ 50)
    },
    {
      "fecha_formateada": "25/02/2026",
      "estado": "ausente",
      "horas_falta_equivalentes": 2.0  // ← NUEVO (120 min ÷ 60)
    }
  ],
  "resumen": {
    "asistencias_totales": 13,
    "presentes": 12,
    "tardanzas": 1,
    "ausencias": 1,
    "total_horas_falta": 2.63,  // ← NUEVO: Total acumulado
    "porcentaje_asistencia": 92.86
  }
}
```

**Regla de cálculo:**
- **Tardanza:** `horas_falta = minutos_tardanza ÷ 50`
  - 20 min → 0.4 horas
  - 50 min → 1.0 hora
  - 60 min → 1.2 horas

- **Ausencia:** `horas_falta = duración_clase ÷ 60`
  - Clase de 120 min → 2.0 horas
  - Clase de 90 min → 1.5 horas

**💡 Cómo mostrarlo:**

```dart
// En la lista de asistencias
ListView.builder(
  itemBuilder: (context, index) {
    final asist = asistencias[index];
    return ListTile(
      title: Text('${asist.fechaFormateada} - ${asist.estado}'),
      subtitle: Text(asist.descripcionEstado),
      trailing: asist.horasFaltaEquivalentes > 0
          ? Chip(
              label: Text('${asist.horasFaltaEquivalentes} hrs'),
              backgroundColor: Colors.red[100],
            )
          : Icon(Icons.check_circle, color: Colors.green),
    );
  },
)

// En el resumen
Card(
  child: Column(
    children: [
      Text('Total Asistencias: ${resumen.asistenciasTotales}'),
      Text('Total Horas Falta: ${resumen.totalHorasFalta} hrs',
           style: TextStyle(color: Colors.red)),
    ],
  ),
)
```

---

## 📊 Cuadro Comparativo de Campos

### Endpoint Listado de Estudiantes

| Campo | Antes | Ahora | Descripción |
|-------|-------|-------|-------------|
| `asistencias_totales` | ❌ No existía | ✅ Nuevo | Presentes + Tardanzas |
| `presentes` | ✅ | ✅ | Sin cambios |
| `tardanzas` | ✅ | ✅ | Sin cambios |
| `ausencias` | ✅ | ✅ | Sin cambios |
| `total_faltas` | tardanzas + ausencias | **Solo ausencias** | ⚠️ Cambió |
| `porcentaje_asistencia` | ✅ | ✅ | Sin cambios |

### Endpoint Detalle de Estudiante

| Campo | Antes | Ahora | Descripción |
|-------|-------|-------|-------------|
| `horas_falta_equivalentes` | ❌ No existía | ✅ Nuevo | Por cada registro |
| `total_horas_falta` | ❌ No existía | ✅ Nuevo | En resumen |
| `asistencias_totales` | ❌ No existía | ✅ Nuevo | En resumen |
| Resto de campos | ✅ | ✅ | Sin cambios |

---

## 🧪 Prueba Rápida

**1. Verifica que el backend tiene los cambios:**
```bash
# Desde el servidor
grep -n "periodos_disponibles" /var/www/.../api_routes.py
grep -n "asistencias_totales" /var/www/.../api_routes.py
grep -n "horas_falta_equivalentes" /var/www/.../api_routes.py
```

**2. Prueba el diagnóstico:**
```dart
final response = await http.get(
  Uri.parse('http://servidor:5000/api/flutter/diagnostico-bd')
);
print(response.body); // Debe contener "periodos_disponibles"
```

**3. Prueba el listado:**
```dart
final response = await http.post(
  Uri.parse('http://servidor:5000/api/flutter/curso/300/estudiantes'),
  body: json.encode({'session_token': token}),
);
final data = json.decode(response.body);
print(data['estudiantes'][0]['estadisticas']); 
// Debe contener "asistencias_totales"
```

**4. Prueba el detalle:**
```dart
final response = await http.post(
  Uri.parse('http://servidor:5000/api/flutter/curso/300/estudiante/320252057/detalle'),
  body: json.encode({'session_token': token}),
);
final data = json.decode(response.body);
print(data['asistencias'][0]); 
// Debe contener "horas_falta_equivalentes"
print(data['resumen']); 
// Debe contener "total_horas_falta"
```

---

## 🔄 Compatibilidad

### ✅ Campos que NO cambiaron (siguen funcionando):
- `presentes`
- `tardanzas`
- `ausencias`
- `porcentaje_asistencia`
- `fecha_formateada`
- `estado`
- `minutos_tardanza`

### ⚠️ Campos que CAMBIARON:
- `total_faltas`: Ahora solo cuenta ausencias (antes incluía tardanzas)

### 🆕 Campos NUEVOS (agrégalos):
- `asistencias_totales`: Presentes + Tardanzas
- `horas_falta_equivalentes`: En cada registro de asistencia
- `total_horas_falta`: En el resumen
- `periodos_disponibles`: En el diagnóstico

---

## 📝 Checklist de Actualización Frontend

- [ ] Actualizar llamada a `/diagnostico-bd` al iniciar la app
- [ ] Guardar `periodos_disponibles` en memoria/state
- [ ] Construir selectores de periodo/corte con las fechas correctas
- [ ] Cambiar UI del listado para mostrar `asistencias_totales`
- [ ] Actualizar lógica que usa `total_faltas` (ahora solo ausencias)
- [ ] Mostrar `horas_falta_equivalentes` en el detalle de asistencias
- [ ] Mostrar `total_horas_falta` en el resumen del estudiante
- [ ] Probar con datos reales y verificar cálculos

---

## 🆘 Ayuda Rápida

**Si no ves los nuevos campos:**
1. Verifica que el backend está actualizado (grep en el archivo)
2. Reinicia Gunicorn en el servidor
3. Limpia cache de Python (`find . -name "*.pyc" -delete`)
4. Verifica la URL (debe ser `/api/flutter/...`)
5. Verifica que usas POST (no GET) donde corresponde

**Si los cálculos no coinciden:**
- Tardanzas: Cada 50 min = 1 hora de falta
- Ausencias: Duración de la clase en horas
- `asistencias_totales = presentes + tardanzas`
- `total_faltas = solo ausencias` (no incluye tardanzas)

**¿Dudas?**  
Revisa los cambios específicos en [api_routes.py](api_routes.py) líneas:
- Diagnóstico: ~4920-5000
- Listado: ~5360-5400
- Detalle: ~5720-5800

---

**¡Listo para implementar!** 🚀
