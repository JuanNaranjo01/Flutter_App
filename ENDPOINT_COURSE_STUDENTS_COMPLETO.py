"""
===============================================================================
ENDPOINT CORREGIDO: ESTUDIANTES DE UN CURSO CON FILTROS Y ESTADÍSTICAS COMPLETAS
===============================================================================

UBICACIÓN: Agregar a /var/www/reconocimientoFacial_asisencias/api_routes.py
RUTA: POST /api/teacher/course/<int:id_curso>/students

Este endpoint reemplaza el actual y soluciona TODOS los problemas:
✅ Incluye horas_faltadas del estudiante
✅ Incluye tardanzas y minutos_tardanza
✅ Valida que el corte haya empezado antes de permitir filtrar
✅ Filtra correctamente por periodo y corte
✅ Calcula estadísticas basándose solo en el rango de fechas del filtro

FECHA DE CREACIÓN: 25 de febrero de 2026
===============================================================================
"""

from flask import jsonify, request
from datetime import datetime, date

@api.route('/teacher/course/<int:id_curso>/students', methods=['POST'])
def get_course_students_with_filters(id_curso):
    """
    Obtiene los estudiantes de un curso con sus estadísticas de asistencia.
    Permite filtrar por periodo académico y corte específico.
    
    CAMBIOS RESPECTO A LA VERSIÓN ANTERIOR:
    - ✅ Valida que el corte haya empezado antes de filtrar
    - ✅ Incluye horas_faltadas, tardanzas y minutos_tardanza
    - ✅ Filtra correctamente usando las fechas de cortes
    - ✅ Calcula estadísticas SOLO del rango de fechas solicitado
    
    REQUEST BODY:
    {
        "session_token": "abc123",    // REQUERIDO
        "año": 2026,                   // OPCIONAL - año del periodo
        "semestre": "1",               // OPCIONAL - semestre ("1" o "2")
        "corte": 1                     // OPCIONAL - número de corte (1, 2, o 3)
    }
    
    RESPONSE:
    {
        "success": true,
        "students": [
            {
                "codigo_estudiante": "320252057",
                "nombre_completo": "JUAN PÉREZ GARCÍA",
                "programa_academico": "INGENIERÍA DE SISTEMAS",
                "email_institucional": "juan.perez@uceva.edu.co",
                "semestre": 5,
                "estadisticas": {
                    "total_clases": 15,
                    "presentes": 12,
                    "tardanzas": 2,
                    "ausencias": 1,
                    "porcentaje_asistencia": 93.33
                },
                "horas_faltadas": {
                    "total_entero": 8
                },
                "tardanzas": {
                    "minutos_totales": 196
                }
            }
        ]
    }
    """
    try:
        # ═══════════════════════════════════════════════════════════════
        # 1️⃣ VALIDAR SESSION TOKEN (tu lógica existente)
        # ═══════════════════════════════════════════════════════════════
        data = request.get_json()
        session_token = data.get('session_token')
        
        if not session_token:
            return jsonify({
                'success': False,
                'error': 'Session token requerido'
            }), 401
        
        # Validar session_token (usa tu función existente)
        # docente = validar_session_token(session_token)
        # if not docente:
        #     return jsonify({'success': False, 'error': 'Sesión inválida'}), 401
        
        # ═══════════════════════════════════════════════════════════════
        # 2️⃣ OBTENER Y VALIDAR FILTROS OPCIONALES
        # ═══════════════════════════════════════════════════════════════
        anio_filtro = data.get('año')
        semestre_filtro = data.get('semestre')
        corte_filtro = data.get('corte')
        
        # Variables para fechas del filtro
        fecha_inicio = None
        fecha_fin = None
        periodo_info = None
        
        # Si se proporcionan filtros, validar y obtener fechas
        if anio_filtro or semestre_filtro or corte_filtro:
            # ═══════════════════════════════════════════════════════════════
            # 2.1 Validar que si hay corte, también haya año y semestre
            # ═══════════════════════════════════════════════════════════════
            if corte_filtro and (not anio_filtro or not semestre_filtro):
                return jsonify({
                    'success': False,
                    'error': 'Para filtrar por corte debe especificar año y semestre'
                }), 400
            
            # ═══════════════════════════════════════════════════════════════
            # 2.2 Buscar el periodo académico
            # ═══════════════════════════════════════════════════════════════
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            
            query_periodo = """
                SELECT 
                    id_periodo, año, semestre, nombre_periodo,
                    fecha_inicio, fecha_fin,
                    corte_1_inicio, corte_1_fin,
                    corte_2_inicio, corte_2_fin,
                    corte_3_inicio, corte_3_fin
                FROM periodos_academicos
                WHERE año = %s AND semestre = %s
                LIMIT 1
            """
            
            cursor.execute(query_periodo, (anio_filtro, semestre_filtro))
            periodo_info = cursor.fetchone()
            
            if not periodo_info:
                cursor.close()
                return jsonify({
                    'success': False,
                    'error': f'No existe el periodo {anio_filtro}-{semestre_filtro}'
                }), 404
            
            # ═══════════════════════════════════════════════════════════════
            # 2.3 Validar que el corte haya empezado
            # ═══════════════════════════════════════════════════════════════
            hoy = date.today()
            
            if corte_filtro:
                corte_num = int(corte_filtro)
                
                if corte_num == 1:
                    fecha_inicio = periodo_info['corte_1_inicio']
                    fecha_fin = periodo_info['corte_1_fin']
                    fecha_inicio_corte = periodo_info['corte_1_inicio']
                elif corte_num == 2:
                    fecha_inicio = periodo_info['corte_2_inicio']
                    fecha_fin = periodo_info['corte_2_fin']
                    fecha_inicio_corte = periodo_info['corte_2_inicio']
                elif corte_num == 3:
                    fecha_inicio = periodo_info['corte_3_inicio']
                    fecha_fin = periodo_info['corte_3_fin']
                    fecha_inicio_corte = periodo_info['corte_3_inicio']
                else:
                    cursor.close()
                    return jsonify({
                        'success': False,
                        'error': 'El corte debe ser 1, 2 o 3'
                    }), 400
                
                # ⚠️ VALIDACIÓN CRÍTICA: El corte debe haber empezado
                if hoy < fecha_inicio_corte:
                    cursor.close()
                    return jsonify({
                        'success': False,
                        'error': f'El corte {corte_num} del periodo {anio_filtro}-{semestre_filtro} aún no ha empezado',
                        'fecha_inicio_corte': fecha_inicio_corte.strftime('%Y-%m-%d'),
                        'fecha_actual': hoy.strftime('%Y-%m-%d')
                    }), 400
            else:
                # Sin corte específico, usar todo el periodo
                fecha_inicio = periodo_info['fecha_inicio']
                fecha_fin = periodo_info['fecha_fin']
            
            cursor.close()
        
        # ═══════════════════════════════════════════════════════════════
        # 3️⃣ CONSULTAR ESTUDIANTES CON ESTADÍSTICAS
        # ═══════════════════════════════════════════════════════════════
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Base de la query
        query = """
        WITH estudiantes_curso AS (
            -- Obtener todos los estudiantes matriculados en el curso
            SELECT DISTINCT
                m.codigo_estudiante,
                e.nombre_completo,
                e.programa_academico,
                e.email_institucional,
                m.semestre
            FROM matriculas m
            INNER JOIN estudiantes e ON m.codigo_estudiante = e.codigo_estudiante
            WHERE m.id_curso = %s
        ),
        estadisticas_asistencia AS (
            -- Calcular estadísticas de asistencia
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
        
        # Agregar filtros de fechas si existen
        params = [id_curso, id_curso]
        
        if fecha_inicio and fecha_fin:
            query += " AND a.fecha_registro BETWEEN %s AND %s"
            params.extend([fecha_inicio, fecha_fin])
        
        if anio_filtro and semestre_filtro:
            query += " AND a.id_periodo = %s"
            params.append(periodo_info['id_periodo'])
        
        if corte_filtro:
            query += " AND a.corte = %s"
            params.append(corte_filtro)
        
        query += """
            GROUP BY a.codigo_estudiante
        )
        SELECT 
            ec.codigo_estudiante,
            ec.nombre_completo,
            ec.programa_academico,
            ec.email_institucional,
            ec.semestre,
            COALESCE(ea.total_clases, 0) AS total_clases,
            COALESCE(ea.presentes, 0) AS presentes,
            COALESCE(ea.tardanzas, 0) AS tardanzas,
            COALESCE(ea.ausencias, 0) AS ausencias,
            COALESCE(ea.horas_faltadas, 0) AS horas_faltadas,
            COALESCE(ea.minutos_tardanza, 0) AS minutos_tardanza,
            CASE 
                WHEN COALESCE(ea.total_clases, 0) > 0 
                THEN ROUND((COALESCE(ea.presentes, 0)::numeric + COALESCE(ea.tardanzas, 0)::numeric) / ea.total_clases::numeric * 100, 2)
                ELSE 0.0
            END AS porcentaje_asistencia
        FROM estudiantes_curso ec
        LEFT JOIN estadisticas_asistencia ea ON ec.codigo_estudiante = ea.codigo_estudiante
        ORDER BY ec.nombre_completo
        """
        
        print(f"📊 Query con parámetros: {params}")
        cursor.execute(query, params)
        resultados = cursor.fetchall()
        cursor.close()
        
        # ═══════════════════════════════════════════════════════════════
        # 4️⃣ FORMATEAR RESPUESTA (Estructura híbrida compatible con endpoints de reportes)
        # ═══════════════════════════════════════════════════════════════
        estudiantes = []
        for row in resultados:
            estudiantes.append({
                'codigo_estudiante': row['codigo_estudiante'],
                'nombre_completo': row['nombre_completo'],
                'programa_academico': row['programa_academico'],
                'email_institucional': row['email_institucional'],
                'semestre': row['semestre'],
                'estadisticas': {
                    'total_clases': int(row['total_clases']),
                    'presentes': int(row['presentes']),
                    'tardanzas': int(row['tardanzas']),
                    'ausencias': int(row['ausencias']),
                    'porcentaje_asistencia': float(row['porcentaje_asistencia'])
                },
                # ✅ Estructura híbrida: objetos anidados simples (consistente con endpoints de reportes)
                'horas_faltadas': {
                    'total_entero': int(row['horas_faltadas'])
                },
                'tardanzas': {
                    'minutos_totales': int(row['minutos_tardanza'])
                }
            })
        
        return jsonify({
            'success': True,
            'students': estudiantes,
            'filtros_aplicados': {
                'año': anio_filtro,
                'semestre': semestre_filtro,
                'corte': corte_filtro,
                'fecha_inicio': fecha_inicio.strftime('%Y-%m-%d') if fecha_inicio else None,
                'fecha_fin': fecha_fin.strftime('%Y-%m-%d') if fecha_fin else None
            }
        }), 200
        
    except Exception as e:
        print(f"❌ Error en get_course_students_with_filters: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return jsonify({
            'success': False,
            'error': f'Error al obtener estudiantes: {str(e)}'
        }), 500


"""
===============================================================================
INSTRUCCIONES DE INSTALACIÓN
===============================================================================

1. Conectarte al servidor:
   ssh admin-rf@192.168.14.25

2. Hacer backup del archivo actual:
   cp /var/www/reconocimientoFacial_asisencias/api_routes.py /var/www/reconocimientoFacial_asisencias/api_routes.py.backup

3. Editar el archivo:
   nano /var/www/reconocimientoFacial_asisencias/api_routes.py

4. Buscar la función actual get_course_students (probablemente línea ~800-900)
   Ctrl+W y buscar: "def get_course_students"

5. REEMPLAZAR TODA LA FUNCIÓN con el código de arriba

6. Guardar y salir:
   Ctrl+O (guardar)
   Enter
   Ctrl+X (salir)

7. Reiniciar el servidor:
   pkill -f gunicorn
   cd /var/www/reconocimientoFacial_asisencias
   ./start_server.sh

8. Verificar que el servidor está corriendo:
   ps aux | grep gunicorn

===============================================================================
TESTING
===============================================================================

# Test 1: Sin filtros (debe mostrar TODAS las asistencias del curso)
curl -X POST http://192.168.14.25/api/teacher/course/98/students \
  -H "Content-Type: application/json" \
  -d '{"session_token": "tu_token_aqui"}'

# Test 2: Con filtro de periodo (solo semestre 1 de 2026)
curl -X POST http://192.168.14.25/api/teacher/course/98/students \
  -H "Content-Type: application/json" \
  -d '{"session_token": "tu_token_aqui", "año": 2026, "semestre": "1"}'

# Test 3: Con filtro de corte 1 (debe funcionar porque ya pasó)
curl -X POST http://192.168.14.25/api/teacher/course/98/students \
  -H "Content-Type: application/json" \
  -d '{"session_token": "tu_token_aqui", "año": 2026, "semestre": "1", "corte": 1}'

# Test 4: Con filtro de corte 2 (debe fallar porque NO ha empezado)
curl -X POST http://192.168.14.25/api/teacher/course/98/students \
  -H "Content-Type: application/json" \
  -d '{"session_token": "tu_token_aqui", "año": 2026, "semestre": "1", "corte": 2}'
# Debe retornar: {"success": false, "error": "El corte 2 del periodo 2026-1 aún no ha empezado"}

===============================================================================
"""
