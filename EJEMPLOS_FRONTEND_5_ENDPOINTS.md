# 📱 EJEMPLOS DE USO - ENDPOINTS DE REPORTES
## Para que el Frontend entienda cómo consumir los datos

---

## 🔵 ENDPOINT 1: Reporte Detallado de Estudiante

### Request:
```http
GET /api/reportes/estudiante/320252057?id_curso=300&id_periodo=1
```

### Response Ejemplo:
```json
{
  "success": true,
  "estudiante": {
    "codigo_estudiante": "320252057",
    "nombre_completo": "JUAN PÉREZ GARCÍA"
  },
  "total_cursos": 2,
  "cursos": [
    {
      "curso": {
        "id_curso": 300,
        "nombre_curso": "CRÉDITOS BIENESTAR - FÚTBOL",
        "intensidad_horaria": 2
      },
      "asistencias": {
        "total_clases": 20,
        "asistencias": 18,
        "presentes": 15,
        "tardanzas": 3,
        "ausencias": 2,
        "justificadas": 0
      },
      "tardanzas": {
        "minutos_totales": 120,
        "horas_equivalentes_decimal": 3.0,
        "explicacion": "50 minutos de tardanza = 1 hora de falta"
      },
      "horas_faltadas": {
        "ausencias_decimal": 4.0,
        "tardanzas_decimal": 3.0,
        "total_decimal": 7.0,
        "total_entero": 7,
        "horas_totales_semestre": 40
      },
      "porcentajes": {
        "asistencia": 90.0,
        "fallas": 17.5
      },
      "alertas": {
        "suspension": false,
        "mensaje": null
      },
      "periodo": {
        "id_periodo": 1,
        "corte": 1
      }
    }
  ]
}
```

### Cómo Usarlo en el Frontend:

#### 🟢 Flutter (Dart):
```dart
class ReporteService {
  Future<EstudianteReporte> obtenerReporte(String codigoEstudiante, {int? idCurso}) async {
    final url = Uri.parse('$baseUrl/api/reportes/estudiante/$codigoEstudiante')
        .replace(queryParameters: {
      if (idCurso != null) 'id_curso': idCurso.toString(),
    });
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return EstudianteReporte.fromJson(data);
    }
    throw Exception('Error al cargar reporte');
  }
}

// Modelo
class EstudianteReporte {
  final String codigoEstudiante;
  final List<CursoReporte> cursos;
  
  EstudianteReporte.fromJson(Map<String, dynamic> json)
      : codigoEstudiante = json['estudiante']['codigo_estudiante'],
        cursos = (json['cursos'] as List)
            .map((c) => CursoReporte.fromJson(c))
            .toList();
}

class CursoReporte {
  final String nombreCurso;
  final int horasFaltadas;  // ⭐ ENTERO para reportes
  final double porcentajeFallas;
  final bool alertaSuspension;
  
  CursoReporte.fromJson(Map<String, dynamic> json)
      : nombreCurso = json['curso']['nombre_curso'],
        horasFaltadas = json['horas_faltadas']['total_entero'],
        porcentajeFallas = json['porcentajes']['fallas'],
        alertaSuspension = json['alertas']['suspension'];
}

// Widget
class ReporteCard extends StatelessWidget {
  final CursoReporte curso;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(curso.nombreCurso),
          Text('Horas faltadas: ${curso.horasFaltadas}'),
          Text('${curso.porcentajeFallas}% de fallas'),
          
          // ⚠️ Alerta de suspensión
          if (curso.alertaSuspension)
            Container(
              color: Colors.red,
              child: Text(
                '⚠️ En riesgo de suspensión',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
```

#### 🔵 React (JavaScript/TypeScript):
```typescript
// services/reportes.service.ts
interface EstudianteReporte {
  success: boolean;
  estudiante: {
    codigo_estudiante: string;
    nombre_completo: string;
  };
  total_cursos: number;
  cursos: CursoReporte[];
}

interface CursoReporte {
  curso: {
    id_curso: number;
    nombre_curso: string;
    intensidad_horaria: number;
  };
  asistencias: {
    total_clases: number;
    presentes: number;
    tardanzas: number;
    ausencias: number;
  };
  horas_faltadas: {
    total_entero: number;  // ⭐ USAR ESTE
    total_decimal: number;
    horas_totales_semestre: number;
  };
  porcentajes: {
    asistencia: number;
    fallas: number;
  };
  alertas: {
    suspension: boolean;
    mensaje: string | null;
  };
}

export const obtenerReporteEstudiante = async (
  codigoEstudiante: string,
  idCurso?: number
): Promise<EstudianteReporte> => {
  const params = new URLSearchParams();
  if (idCurso) params.append('id_curso', idCurso.toString());
  
  const response = await fetch(
    `/api/reportes/estudiante/${codigoEstudiante}?${params}`
  );
  
  if (!response.ok) throw new Error('Error al cargar reporte');
  return response.json();
};

// components/ReporteCard.tsx
import { Alert } from '@mui/material';

export const ReporteCard: React.FC<{ curso: CursoReporte }> = ({ curso }) => {
  return (
    <Card>
      <CardHeader title={curso.curso.nombre_curso} />
      <CardContent>
        {/* ⚠️ Alerta de suspensión */}
        {curso.alertas.suspension && (
          <Alert severity="error" sx={{ mb: 2 }}>
            ⚠️ Este estudiante está en riesgo de suspensión
            ({curso.porcentajes.fallas}% de fallas)
          </Alert>
        )}
        
        <Grid container spacing={2}>
          <Grid item xs={6}>
            <Typography variant="body2" color="text.secondary">
              Clases Totales
            </Typography>
            <Typography variant="h6">
              {curso.asistencias.total_clases}
            </Typography>
          </Grid>
          
          <Grid item xs={6}>
            <Typography variant="body2" color="text.secondary">
              Presentes
            </Typography>
            <Typography variant="h6" color="success.main">
              {curso.asistencias.presentes}
            </Typography>
          </Grid>
          
          <Grid item xs={6}>
            <Typography variant="body2" color="text.secondary">
              Tardanzas
            </Typography>
            <Typography variant="h6" color="warning.main">
              {curso.asistencias.tardanzas}
            </Typography>
          </Grid>
          
          <Grid item xs={6}>
            <Typography variant="body2" color="text.secondary">
              Ausencias
            </Typography>
            <Typography variant="h6" color="error.main">
              {curso.asistencias.ausencias}
            </Typography>
          </Grid>
        </Grid>
        
        <Divider sx={{ my: 2 }} />
        
        {/* ⭐ HORAS FALTADAS - USAR total_entero */}
        <Box>
          <Typography variant="body2" color="text.secondary">
            Horas Faltadas (con tardanzas)
          </Typography>
          <Typography 
            variant="h4" 
            color={curso.horas_faltadas.total_entero > 8 ? 'error' : 'inherit'}
          >
            {curso.horas_faltadas.total_entero} horas
          </Typography>
          <Typography variant="caption">
            de {curso.horas_faltadas.horas_totales_semestre} horas totales
          </Typography>
        </Box>
        
        <Divider sx={{ my: 2 }} />
        
        {/* Porcentaje de fallas */}
        <Box>
          <LinearProgress 
            variant="determinate" 
            value={curso.porcentajes.fallas} 
            color={curso.porcentajes.fallas >= 20 ? 'error' : 'success'}
            sx={{ height: 10, borderRadius: 5 }}
          />
          <Typography variant="body2" align="center" sx={{ mt: 1 }}>
            {curso.porcentajes.fallas}% de fallas
            {curso.porcentajes.fallas >= 20 && ' ⚠️'}
          </Typography>
        </Box>
      </CardContent>
    </Card>
  );
};
```

---

## 🟢 ENDPOINT 2: Resumen Ejecutivo de Estudiante

### Request:
```http
GET /api/reportes/estudiante/320252057/resumen?id_periodo=1
```

### Response Ejemplo:
```json
{
  "success": true,
  "data": [
    {
      "periodo": {
        "id_periodo": 1,
        "corte": 1
      },
      "academico": {
        "cursos_matriculados": 3
      },
      "asistencias": {
        "total_clases": 60,
        "asistencias": 54,
        "tardanzas": 4,
        "ausencias": 2
      },
      "horas": {
        "horas_faltadas_total": 8,
        "horas_totales_periodo": 120
      },
      "promedios": {
        "porcentaje_asistencia": 90.0,
        "porcentaje_fallas": 6.67
      },
      "alertas": {
        "tiene_alerta_suspension": false
      }
    }
  ]
}
```

### Cómo Usarlo:

#### Flutter:
```dart
class ResumenWidget extends StatelessWidget {
  final ResumenEjecutivo resumen;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Periodo ${resumen.periodo.idPeriodo} - Corte ${resumen.periodo.corte}'),
            SizedBox(height: 16),
            
            // Cursos matriculados
            _buildStat(
              'Cursos Matriculados',
              '${resumen.academico.cursosMatriculados}',
            ),
            
            // Horas faltadas
            _buildStat(
              'Horas Faltadas',
              '${resumen.horas.horasFaltadasTotal} / ${resumen.horas.horasTotalesPeriodo}',
              color: resumen.horas.horasFaltadasTotal > 10 ? Colors.red : Colors.green,
            ),
            
            // Porcentaje promedio
            LinearPercentIndicator(
              percent: resumen.promedios.porcentajeFallas / 100,
              lineHeight: 20,
              progressColor: resumen.alertas.tieneAlertaSuspension 
                  ? Colors.red 
                  : Colors.green,
              center: Text('${resumen.promedios.porcentajeFallas}%'),
            ),
            
            // Alerta
            if (resumen.alertas.tieneAlertaSuspension)
              Container(
                margin: EdgeInsets.only(top: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tiene al menos un curso en riesgo de suspensión',
                        style: TextStyle(color: Colors.red[900]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStat(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔴 ENDPOINT 3: Estudiantes en Riesgo

### Request:
```http
GET /api/reportes/estudiantes-en-riesgo?corte=1&id_periodo=1
```

### Response Ejemplo:
```json
{
  "success": true,
  "total": 5,
  "estudiantes": [
    {
      "codigo_estudiante": "320252058",
      "nombre_completo": "MARÍA GARCÍA LÓPEZ",
      "curso": "CRÉDITOS BIENESTAR - FÚTBOL",
      "horas_faltadas": 12,
      "horas_totales": 40,
      "porcentaje_fallas": 30.0,
      "detalle": {
        "total_clases": 20,
        "ausencias": 5,
        "tardanzas": 4
      }
    },
    {
      "codigo_estudiante": "320252059",
      "nombre_completo": "CARLOS RODRÍGUEZ",
      "curso": "CRÉDITOS BIENESTAR - BALONCESTO",
      "horas_faltadas": 10,
      "horas_totales": 40,
      "porcentaje_fallas": 25.0,
      "detalle": {
        "total_clases": 20,
        "ausencias": 4,
        "tardanzas": 3
      }
    }
  ]
}
```

### Cómo Usarlo:

#### React - Lista de Estudiantes en Riesgo:
```typescript
// components/EstudiantesEnRiesgo.tsx
import { DataGrid, GridColDef } from '@mui/x-data-grid';

interface EstudianteEnRiesgo {
  codigo_estudiante: string;
  nombre_completo: string;
  curso: string;
  horas_faltadas: number;
  horas_totales: number;
  porcentaje_fallas: number;
  detalle: {
    total_clases: number;
    ausencias: number;
    tardanzas: number;
  };
}

export const EstudiantesEnRiesgo: React.FC = () => {
  const [estudiantes, setEstudiantes] = useState<EstudianteEnRiesgo[]>([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    fetchEstudiantesEnRiesgo();
  }, []);
  
  const fetchEstudiantesEnRiesgo = async () => {
    try {
      const response = await fetch('/api/reportes/estudiantes-en-riesgo?corte=1');
      const data = await response.json();
      setEstudiantes(data.estudiantes);
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };
  
  const columns: GridColDef[] = [
    {
      field: 'codigo_estudiante',
      headerName: 'Código',
      width: 130,
    },
    {
      field: 'nombre_completo',
      headerName: 'Nombre Completo',
      width: 250,
    },
    {
      field: 'curso',
      headerName: 'Curso',
      width: 200,
    },
    {
      field: 'horas_faltadas',
      headerName: 'Horas Faltadas',
      width: 150,
      renderCell: (params) => (
        <Chip 
          label={`${params.value} / ${params.row.horas_totales}`}
          color="error"
          size="small"
        />
      ),
    },
    {
      field: 'porcentaje_fallas',
      headerName: '% Fallas',
      width: 120,
      renderCell: (params) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Typography 
            variant="body2" 
            color={params.value >= 30 ? 'error' : 'warning.main'}
            fontWeight="bold"
          >
            {params.value}%
          </Typography>
          {params.value >= 30 && '🔴'}
          {params.value >= 20 && params.value < 30 && '⚠️'}
        </Box>
      ),
    },
    {
      field: 'detalle',
      headerName: 'Detalle',
      width: 200,
      renderCell: (params) => (
        <Typography variant="caption">
          {params.value.ausencias} ausencias, {params.value.tardanzas} tardanzas
        </Typography>
      ),
    },
  ];
  
  return (
    <Box sx={{ height: 600, width: '100%' }}>
      <Typography variant="h5" gutterBottom>
        ⚠️ Estudiantes en Riesgo de Suspensión
      </Typography>
      <Alert severity="warning" sx={{ mb: 2 }}>
        Estos estudiantes tienen 20% o más de fallas
      </Alert>
      
      <DataGrid
        rows={estudiantes}
        columns={columns}
        getRowId={(row) => row.codigo_estudiante}
        loading={loading}
        pageSizeOptions={[10, 25, 50]}
        initialState={{
          pagination: { paginationModel: { pageSize: 10 } },
        }}
      />
    </Box>
  );
};
```

---

## 🔵 ENDPOINT 4: Reporte para Docente

### Request:
```http
GET /api/reportes/docente/lzuluagar@uceva.edu.co
```

### Response Ejemplo:
```json
{
  "success": true,
  "docente": {
    "nombre": "LUIS ZULUAGA",
    "correo": "lzuluagar@uceva.edu.co"
  },
  "total_cursos": 3,
  "cursos": [
    {
      "curso": "CRÉDITOS BIENESTAR - FÚTBOL",
      "horario": {
        "dia": "lunes",
        "hora_inicio": "10:40",
        "hora_fin": "12:20"
      },
      "matricula": {
        "estudiantes_matriculados": 30,
        "registros_totales": 600
      },
      "asistencias": {
        "asistencias": 540,
        "con_tardanza": 40,
        "ausencias": 20
      },
      "estadisticas": {
        "porcentaje_asistencia": 90.0
      }
    }
  ]
}
```

### Cómo Usarlo:

#### Flutter - Dashboard del Docente:
```dart
class DocenteDashboard extends StatelessWidget {
  final ReporteDocente reporte;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${reporte.docente.nombre}'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: reporte.cursos.length,
        itemBuilder: (context, index) {
          final curso = reporte.cursos[index];
          return CursoDocenteCard(curso: curso);
        },
      ),
    );
  }
}

class CursoDocenteCard extends StatelessWidget {
  final CursoDocente curso;
  
  @override
  Widget build(BuildContext context) {
    final porcentaje = curso.estadisticas.porcentajeAsistencia;
    final color = porcentaje >= 90 
        ? Colors.green 
        : porcentaje >= 75 
            ? Colors.orange 
            : Colors.red;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossSection: CrossAxisAlignment.start,
          children: [
            // Título del curso
            Text(
              curso.curso,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            
            // Horario
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${curso.horario.dia} ${curso.horario.horaInicio} - ${curso.horario.horaFin}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            
            Divider(height: 24),
            
            // Estadísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  'Matriculados',
                  '${curso.matricula.estudiantesMatriculados}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStat(
                  'Presentes',
                  '${curso.asistencias.asistencias}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStat(
                  'Tardanzas',
                  '${curso.asistencias.conTardanza}',
                  Icons.access_time,
                  Colors.orange,
                ),
                _buildStat(
                  'Ausencias',
                  '${curso.asistencias.ausencias}',
                  Icons.cancel,
                  Colors.red,
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Barra de progreso
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistencia General del Curso',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: porcentaje / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 12,
                ),
                SizedBox(height: 4),
                Text(
                  '${porcentaje.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
```

---

## 🟣 ENDPOINT 5: Calcular Horas (Herramienta)

### Request:
```http
POST /api/calculos/horas-faltadas
Content-Type: application/json

{
  "horas_ausencias": 2.5,
  "minutos_tardanza": 80
}
```

### Response Ejemplo:
```json
{
  "success": true,
  "entrada": {
    "horas_ausencias": 2.5,
    "minutos_tardanza": 80
  },
  "resultado": {
    "horas_tardanza_equivalentes": 2.0,
    "horas_total_decimal": 4.5,
    "horas_total_entero": 5,
    "explicacion": "50 minutos de tardanza = 1 hora de falta"
  }
}
```

### Cómo Usarlo:

#### React - Calculadora:
```typescript
// components/CalculadoraHoras.tsx
export const CalculadoraHoras: React.FC = () => {
  const [horasAusencias, setHorasAusencias] = useState<number>(0);
  const [minutosTardanza, setMinutosTardanza] = useState<number>(0);
  const [resultado, setResultado] = useState<any>(null);
  
  const calcular = async () => {
    try {
      const response = await fetch('/api/calculos/horas-faltadas', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          horas_ausencias: horasAusencias,
          minutos_tardanza: minutosTardanza,
        }),
      });
      
      const data = await response.json();
      setResultado(data.resultado);
    } catch (error) {
      console.error('Error:', error);
    }
  };
  
  return (
    <Card>
      <CardHeader title="🧮 Calculadora de Horas Faltadas" />
      <CardContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          <TextField
            label="Horas de Ausencias"
            type="number"
            value={horasAusencias}
            onChange={(e) => setHorasAusencias(Number(e.target.value))}
            inputProps={{ step: 0.5 }}
          />
          
          <TextField
            label="Minutos de Tardanza"
            type="number"
            value={minutosTardanza}
            onChange={(e) => setMinutosTardanza(Number(e.target.value))}
            helperText="50 minutos = 1 hora de falta"
          />
          
          <Button variant="contained" onClick={calcular}>
            Calcular
          </Button>
          
          {resultado && (
            <Paper elevation={3} sx={{ p: 2, mt: 2, bgcolor: 'primary.light' }}>
              <Typography variant="h6" gutterBottom>
                Resultado:
              </Typography>
              
              <Divider sx={{ my: 1 }} />
              
              <Typography variant="body1">
                <strong>Horas de tardanza equivalentes:</strong>{' '}
                {resultado.horas_tardanza_equivalentes} horas
              </Typography>
              
              <Typography variant="body1">
                <strong>Total (decimal):</strong>{' '}
                {resultado.horas_total_decimal} horas
              </Typography>
              
              <Typography variant="h5" color="error" sx={{ mt: 2 }}>
                <strong>⭐ Total para reporte:</strong>{' '}
                {resultado.horas_total_entero} horas
              </Typography>
              
              <Alert severity="info" sx={{ mt: 2 }}>
                {resultado.explicacion}
              </Alert>
            </Paper>
          )}
        </Box>
      </CardContent>
    </Card>
  );
};
```

---

## 📊 RESUMEN DE CAMPOS CLAVE

### ⭐ Campos que SIEMPRE debes usar para reportes oficiales:

```javascript
// Para horas faltadas:
horas_faltadas.total_entero  // ← USAR ESTE (número entero)

// Para porcentaje:
porcentajes.fallas           // ← Decimal (ej: 17.50)

// Para alertas:
alertas.suspension           // ← Boolean (true/false)
```

### ❌ NO usar estos campos en reportes oficiales:
```javascript
horas_faltadas.total_decimal     // Solo para detalles internos
horas_faltadas.ausencias_decimal // Solo para debug
```

---

## 🎯 Flujo Completo en la App

```
1. Login Docente
   ↓
2. Ver Dashboard (Endpoint 4: Reporte Docente)
   ↓
3. Seleccionar Curso
   ↓
4. Ver Lista de Estudiantes con filtros (Endpoint 6: Course Students)
   ↓
5. Click en Estudiante
   ↓
6. Ver Reporte Detallado (Endpoint 1: Reporte Estudiante)
   ↓
7. Ver Resumen Ejecutivo (Endpoint 2: Resumen)
   ↓
8. Ver Todos en Riesgo (Endpoint 3: Estudiantes en Riesgo)
```

---

**¿Necesitas ejemplos en otro framework o lenguaje?** Puedo crear ejemplos para:
- Vue.js
- Angular
- React Native
- Kotlin (Android nativo)
- Swift (iOS nativo)
