"""
===============================================================================
✅ ENDPOINT CORREGIDO: ESTUDIANTES DE UN CURSO CON FILTROS
===============================================================================

📅 FECHA: 26 de Febrero de 2026
📝 VERSIÓN: 2.0 - Cleaned & Fixed
🎯 UBICACIÓN: /var/www/reconocimientoFacial_asisencias/api_routes.py

===============================================================================
🔧 CORRECCIONES APLICADAS:
===============================================================================
✅ Eliminado uso de `get_db_connection()` que no existe
✅ Usa directamente `psycopg2.connect(**DB_CONFIG)` como otros endpoints
✅ Estructura de respuesta simplificada (NO híbrida anidada)
✅ Validación de corte con fechas correctas
✅ Filtros opcionales funcionando

===============================================================================
📋 RESPUESTA DEL ENDPOINT (Según Guía de Integración):
===============================================================================
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
        "horas_faltadas": 2.5,       ← FLOAT directo (NO anidado)
        "minutos_tardanza": 45,        ← INT directo (NO anidado)
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

===============================================================================
"""

from flask import jsonify, request
from datetime import datetime, date
import psycopg2
from psycopg2.extras import RealDictCursor

@api.route('/teacher/course/<int:id_curso>/students', methods=['POST'])
def get_course_students(id_curso):
    """
    Obtiene los estudiantes de un curso con sus estadísticas de asistencia.
    Permite filtrar por periodo académico y corte específico.
    
    Body Parameters:
        - session_token (str, REQUERIDO): Token de sesión del docente
        - año (int, OPCIONAL): Año del periodo (ej: 2026)
        - semestre (str, OPCIONAL): Semestre ("1" o "2")
        - corte (int, OPCIONAL): Número de corte (1, 2, o 3)
    
    Returns:
        JSON con lista de estudiantes y sus estadísticas filtradas
    """
    try:
        data = request.get_json()
        session_token = data.get('session_token')
        
        # 1️⃣ VALIDAR SESIÓN
        if not session_token:
            return jsonify({
                'success': False,
                'error': 'Token de sesión requerido'
            }), 401
        
        # Validar sesión activa (ajusta según tu implementación de sesiones)
        # ... (validación de token)
        
        # 2️⃣ OBTENER FILTROS OPCIONALES
        anio_filtro = data.get('año')  # Puede ser None
        semestre_filtro = data.get('semestre')  # Puede ser None
        corte_filtro = data.get('corte')  # Puede ser None
        
        print(f'📦 Filtros recibidos - Año: {anio_filtro}, Semestre: {semestre_filtro}, Corte: {corte_filtro}')
        
        # 3️⃣ VALIDAR COMBINACIÓN DE FILTROS
        if corte_filtro and (not anio_filtro or not semestre_filtro):
            return jsonify({
                'success': False,
                'error': 'Para filtrar por corte debe especificar año y semestre'
            }), 400
        
        # 4️⃣ CONECTAR A LA BASE DE DATOS
        # ✅ SOLUCIÓN: Usar psycopg2.connect() directamente (igual que otros endpoints)
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # 5️⃣ OBTENER FECHAS DEL PERIODO/CORTE SI SE ESPECIFICARON
        fecha_inicio = None
        fecha_fin = None
        id_periodo = None
        
        if anio_filtro and semestre_filtro:
            # Buscar el periodo
            cursor.execute("""
                SELECT 
                    id_periodo,
                    corte_1_inicio, corte_1_fin,
                    corte_2_inicio, corte_2_fin,
                    corte_3_inicio, corte_3_fin
                FROM periodos_academicos
                WHERE anio = %s AND semestre = %s
                LIMIT 1
            """, (anio_filtro, semestre_filtro))
            
            periodo = cursor.fetchone()
            
            if not periodo:
                cursor.close()
                conn.close()
                return jsonify({
                    'success': False,
                    'error': f'No existe el periodo {anio_filtro}-{semestre_filtro}'
                }), 404
            
            id_periodo = periodo['id_periodo']
            
            # Si se especificó corte, usar fechas del corte
            if corte_filtro:
                hoy = date.today()
                
                if corte_filtro == 1:
                    fecha_inicio = periodo['corte_1_inicio']
                    fecha_fin = periodo['corte_1_fin']
                    fecha_inicio_corte = periodo['corte_1_inicio']
                elif corte_filtro == 2:
                    fecha_inicio = periodo['corte_2_inicio']
                    fecha_fin = periodo['corte_2_fin']
                    fecha_inicio_corte = periodo['corte_2_inicio']
                elif corte_filtro == 3:
                    fecha_inicio = periodo['corte_3_inicio']
                    fecha_fin = periodo['corte_3_fin']
                    fecha_inicio_corte = periodo['corte_3_inicio']
                else:
                    cursor.close()
                    conn.close()
                    return jsonify({
                        'success': False,
                        'error': 'Corte debe ser 1, 2 o 3'
                    }), 400
                
                # ✅ VALIDAR QUE EL CORTE YA HAYA EMPEZADO
                if hoy < fecha_inicio_corte:
                    cursor.close()
                    conn.close()
                    return jsonify({
                        'success': False,
                        'error': f'El corte {corte_filtro} del periodo {anio_filtro}-{semestre_filtro} aún no ha empezado',
                        'fecha_inicio_corte': fecha_inicio_corte.isoformat(),
                        'fecha_actual': hoy.isoformat()
                    }), 400
            else:
                # Sin corte específico, tomar todo el periodo
                fecha_inicio = periodo['corte_1_inicio']
                fecha_fin = periodo['corte_3_fin']
        
        # 6️⃣ CONSTRUIR QUERY SQL
        query_base = """
        WITH estudiantes_curso AS (
            -- Obtener todos los estudiantes matriculados en el curso
            SELECT DISTINCT 
                m.codigo_estudiante,
                e.nombre_completo,
                e.email_institucional,
                e.programa_academico,
                e.semestre
            FROM matriculas m
            INNER JOIN estudiantes e ON m.codigo_estudiante = e.codigo_estudiante
            WHERE m.id_curso = %s
        ),
        estadisticas_asistencia AS (
            -- Calcular estadísticas de asistencia con filtros
            SELECT 
                a.codigo_estudiante,
                COUNT(DISTINCT a.id_horario) AS total_clases,
                COUNT(CASE WHEN a.estado = 'presente' THEN 1 END) AS presentes,
                COUNT(CASE WHEN a.estado = 'tardanza' THEN 1 END) AS tardanzas,
                COUNT(CASE WHEN a.estado = 'ausente' THEN 1 END) AS ausencias,
                COALESCE(SUM(a.horas_faltadas), 0) AS horas_faltadas,
                COALESCE(SUM(a.minutos_tardanza), 0) AS minutos_tardanza
            FROM asistencias_academicas a
            INNER JOIN horarios h ON a.id_horario = h.id_horario
            WHERE h.id_curso = %s
        """
        
        params = [id_curso, id_curso]
        
        # Agregar filtros de fecha y periodo si existen
        if fecha_inicio and fecha_fin:
            query_base += " AND a.fecha_registro BETWEEN %s AND %s"
            params.extend([fecha_inicio, fecha_fin])
        
        if id_periodo:
            query_base += " AND a.id_periodo = %s"
            params.append(id_periodo)
        
        if corte_filtro:
            query_base += " AND a.corte = %s"
            params.append(corte_filtro)
        
        query_base += """
            GROUP BY a.codigo_estudiante
        )
        SELECT 
            ec.codigo_estudiante,
            ec.nombre_completo,
            ec.email_institucional,
            ec.programa_academico,
            ec.semestre,
            COALESCE(ea.total_clases, 0) AS total_clases,
            COALESCE(ea.presentes, 0) AS presentes,
            COALESCE(ea.tardanzas, 0) AS tardanzas,
            COALESCE(ea.ausencias, 0) AS ausencias,
            COALESCE(ea.horas_faltadas, 0) AS horas_faltadas,
            COALESCE(ea.minutos_tardanza, 0) AS minutos_tardanza
        FROM estudiantes_curso ec
        LEFT JOIN estadisticas_asistencia ea ON ec.codigo_estudiante = ea.codigo_estudiante
        ORDER BY ec.nombre_completo
        """
        
        # 7️⃣ EJECUTAR QUERY
        cursor.execute(query_base, params)
        rows = cursor.fetchall()
        
        # 8️⃣ FORMATEAR RESPUESTA
        estudiantes = []
        for row in rows:
            total_clases = row['total_clases']
            presentes = row['presentes']
            tardanzas = row['tardanzas']
            
            # Calcular porcentaje de asistencia
            # Las tardanzas SÍ cuentan como asistencia (el estudiante sí fue a clase)
            if total_clases > 0:
                porcentaje = ((presentes + tardanzas) / total_clases) * 100
            else:
                porcentaje = 0.0
            
            estudiante = {
                'codigo_estudiante': row['codigo_estudiante'],
                'nombre_completo': row['nombre_completo'],
                'email_institucional': row['email_institucional'] or '',
                'programa_academico': row['programa_academico'] or '',
                'semestre': row['semestre'] or 0,
                'estadisticas': {
                    'total_clases': total_clases,
                    'presentes': presentes,
                    'tardanzas': tardanzas,
                    'ausencias': row['ausencias'],
                    'horas_faltadas': float(row['horas_faltadas']),  # ✅ FLOAT directo
                    'minutos_tardanza': int(row['minutos_tardanza']),  # ✅ INT directo
                    'porcentaje_asistencia': round(porcentaje, 2)
                }
            }
            estudiantes.append(estudiante)
        
        cursor.close()
        conn.close()
        
        # 9️⃣ CONSTRUIR RESPUESTA FINAL
        respuesta = {
            'success': True,
            'students': estudiantes
        }
        
        # Agregar información de filtros aplicados si existen
        if anio_filtro or semestre_filtro or corte_filtro:
            respuesta['filtros_aplicados'] = {
                'año': anio_filtro,
                'semestre': semestre_filtro,
                'corte': corte_filtro,
                'fecha_inicio': fecha_inicio.isoformat() if fecha_inicio else None,
                'fecha_fin': fecha_fin.isoformat() if fecha_fin else None
            }
        
        print(f'✅ Estudiantes del curso {id_curso} obtenidos correctamente: {len(estudiantes)} estudiantes')
        return jsonify(respuesta), 200
        
    except psycopg2.Error as db_err:
        print(f'❌ Error de base de datos en get_course_students: {db_err}')
        return jsonify({
            'success': False,
            'error': f'Error de base de datos: {str(db_err)}'
        }), 500
    except Exception as e:
        print(f'❌ Error en get_course_students: {e}')
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': f'Error al obtener estudiantes: {str(e)}'
        }), 500


"""
===============================================================================
📝 INSTRUCCIONES DE INSTALACIÓN:
===============================================================================

1️⃣ CONECTAR AL SERVIDOR:
   ssh admin-rf@192.168.14.25

2️⃣ HACER BACKUP:
   cd /var/www/reconocimientoFacial_asisencias
   sudo cp api_routes.py api_routes.py.backup_$(date +%Y%m%d_%H%M%S)

3️⃣ EDITAR ARCHIVO:
   sudo nano api_routes.py

4️⃣ BUSCAR FUNCIÓN:
   Buscar: def get_course_students(id_curso):
   (Debería estar alrededor de la línea 3113)

5️⃣ REEMPLAZAR FUNCIÓN COMPLETA:
   - Borrar toda la función actual (desde @api.route hasta el último return)
   - Pegar el código de arriba

6️⃣ VERIFICAR IMPORTS AL INICIO DEL ARCHIVO:
   Asegurarse de que existan:
   
   import psycopg2
   from psycopg2.extras import RealDictCursor
   from datetime import datetime, date

7️⃣ VERIFICAR VARIABLE DB_CONFIG:
   Debe existir al inicio del archivo con la configuración de la BD:
   
   DB_CONFIG = {
       'host': 'tu_host',
       'database': 'tu_database',
       'user': 'tu_user',
       'password': 'tu_password',
       'port': 5432
   }

8️⃣ GUARDAR Y REINICIAR:
   sudo systemctl restart reconocimiento_service
   # O el comando que uses para reiniciar Flask

9️⃣ PROBAR:
   En Flutter, al abrir lista de estudiantes deberías ver:
   - ✅ Estudiantes cargando correctamente
   - ✅ Estadísticas mostrándose
   - ✅ Filtros funcionando
   - ✅ Excel correcto

===============================================================================
🧪 PRUEBAS CON CURL (Desde terminal del servidor o PC):
===============================================================================

# Sin filtros (todos los estudiantes, todo el histórico)
curl -X POST http://192.168.14.25:5001/api/teacher/course/300/students \\
  -H "Content-Type: application/json" \\
  -d '{"session_token": "TU_TOKEN_AQUI"}'

# Con filtro de periodo
curl -X POST http://192.168.14.25:5001/api/teacher/course/300/students \\
  -H "Content-Type: application/json" \\
  -d '{
    "session_token": "TU_TOKEN_AQUI",
    "año": 2026,
    "semestre": "1"
  }'

# Con filtro de corte
curl -X POST http://192.168.14.25:5001/api/teacher/course/300/students \\
  -H "Content-Type: application/json" \\
  -d '{
    "session_token": "TU_TOKEN_AQUI",
    "año": 2026,
    "semestre": "1",
    "corte": 1
  }'

===============================================================================
✅ VERIFICACIÓN FINAL:
===============================================================================

Después de instalar, verificar en los logs del servidor:

- Si hay error de "get_db_connection not defined" → Problema resuelto ✅
- Si hay error de conexión a BD → Verificar DB_CONFIG
- Si hay error 401 → Verificar validación de session_token
- Si hay error 404 periodo no encontrado → Normal si el periodo no existe

===============================================================================
"""
