"""
═══════════════════════════════════════════════════════════════════════════════
ENDPOINT PARA CONSULTA DE HISTORIAL DE ASISTENCIAS
═══════════════════════════════════════════════════════════════════════════════

INSTRUCCIONES:
1. Abrir tu archivo app.py del backend (en el servidor)
2. Copiar TODO el código de abajo (desde @app.route hasta el return final)
3. Pegarlo DESPUÉS de tu endpoint /api/recognize_mobile
4. Ajustar nombres de tablas/columnas según tu base de datos (ver comentarios)
5. Guardar y reiniciar el servidor

UBICACIÓN: Agregar en tu archivo del servidor (donde están los otros endpoints)
═══════════════════════════════════════════════════════════════════════════════
"""

@app.route('/api/get_attendance_history', methods=['POST'])
def get_attendance_history():
    """
    Obtiene el historial de asistencias de un docente con filtros opcionales
    
    REQUEST (desde Flutter):
    {
        "codigo_docente": "DOC123",    // REQUERIDO
        "semestre": "2024-I",           // OPCIONAL (o "Todos")
        "corte": "1er Corte",           // OPCIONAL (o "Todos")
        "materia": "Programación..."    // OPCIONAL (o "Todas")
    }
    
    RESPONSE:
    {
        "success": true,
        "records": [
            {
                "fecha": "2024-01-15",
                "codigo": "EST001234",
                "nombre": "María González López",
                "materia": "Programación Orientada a Objetos",
                "asistio": true,
                "horasAsistidas": 4,
                "semestre": "2024-I",
                "corte": "1er Corte"
            }
        ]
    }
    """
    try:
        # Obtener datos del request
        data = request.json
        codigo_docente = data.get('codigo_docente')
        
        # Validar que venga el código del docente
        if not codigo_docente:
            return jsonify({
                'success': False,
                'error': 'Código de docente requerido'
            }), 400
        
        # Obtener filtros opcionales (pueden venir como None, "Todos" o "Todas")
        semestre = data.get('semestre')
        corte = data.get('corte')
        materia = data.get('materia')
        
        # ═══════════════════════════════════════════════════════════════════
        # AJUSTAR NOMBRES DE TABLAS Y COLUMNAS SEGÚN TU BASE DE DATOS
        # ═══════════════════════════════════════════════════════════════════
        
        # Construir query SQL base
        # NOTA: Cambia 'asistencias' y 'sesiones' por los nombres de TUS tablas
        query = """
            SELECT 
                a.fecha,
                a.codigo_estudiante AS codigo,
                a.nombre_estudiante AS nombre,
                s.materia,
                TRUE AS asistio,
                s.horas_clase AS horasAsistidas,
                s.semestre,
                s.corte
            FROM asistencias a
            INNER JOIN sesiones s ON a.sesion_id = s.id
            WHERE s.codigo_docente = %s
        """
        
        # Lista de parámetros para la query
        params = [codigo_docente]
        
        # Agregar filtros opcionales SOLO si están presentes y no son "Todos"/"Todas"
        if semestre and semestre != 'Todos':
            query += " AND s.semestre = %s"
            params.append(semestre)
            
        if corte and corte != 'Todos':
            query += " AND s.corte = %s"
            params.append(corte)
            
        if materia and materia != 'Todas':
            query += " AND s.materia = %s"
            params.append(materia)
        
        # Ordenar por fecha descendente (más recientes primero)
        query += " ORDER BY a.fecha DESC, a.hora DESC"
        
        # ═══════════════════════════════════════════════════════════════════
        # EJECUTAR QUERY - AJUSTAR SEGÚN TU CONEXIÓN A BD
        # ═══════════════════════════════════════════════════════════════════
        
        # OPCIÓN 1: Si usas MySQL con mysql.connector
        cursor = db.cursor(dictionary=True)
        cursor.execute(query, params)
        registros = cursor.fetchall()
        cursor.close()
        
        # OPCIÓN 2: Si usas PostgreSQL con psycopg2
        # import psycopg2.extras
        # cursor = db.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        # cursor.execute(query, params)
        # registros = cursor.fetchall()
        # cursor.close()
        
        # OPCIÓN 3: Si usas SQLite
        # cursor = db.cursor()
        # cursor.row_factory = sqlite3.Row
        # cursor.execute(query, params)
        # registros = [dict(row) for row in cursor.fetchall()]
        # cursor.close()
        
        # OPCIÓN 4: Si usas SQLAlchemy (ORM)
        # from sqlalchemy import and_
        # query_obj = db.session.query(Asistencia).join(Sesion).filter(
        #     Sesion.codigo_docente == codigo_docente
        # )
        # if semestre and semestre != 'Todos':
        #     query_obj = query_obj.filter(Sesion.semestre == semestre)
        # if corte and corte != 'Todos':
        #     query_obj = query_obj.filter(Sesion.corte == corte)
        # if materia and materia != 'Todas':
        #     query_obj = query_obj.filter(Sesion.materia == materia)
        # registros_obj = query_obj.order_by(Asistencia.fecha.desc()).all()
        # registros = [r.to_dict() for r in registros_obj]
        
        # ═══════════════════════════════════════════════════════════════════
        # CONVERTIR A FORMATO ESPERADO POR FLUTTER
        # ═══════════════════════════════════════════════════════════════════
        
        records = []
        for r in registros:
            # Convertir fecha a string si es necesario
            fecha_str = r['fecha']
            if hasattr(fecha_str, 'strftime'):
                fecha_str = fecha_str.strftime('%Y-%m-%d')
            else:
                fecha_str = str(fecha_str)
            
            records.append({
                'fecha': fecha_str,
                'codigo': str(r['codigo']),
                'nombre': str(r['nombre']),
                'materia': str(r['materia']),
                'asistio': bool(r['asistio']),
                'horasAsistidas': int(r['horasAsistidas']),
                'semestre': str(r['semestre']),
                'corte': str(r['corte'])
            })
        
        # Log para debug (opcional)
        print(f"[INFO] Consulta de asistencias - Docente: {codigo_docente}, Registros: {len(records)}")
        
        # Retornar respuesta exitosa
        return jsonify({
            'success': True,
            'records': records
        }), 200
        
    except Exception as e:
        # Log del error
        print(f"[ERROR] get_attendance_history: {str(e)}")
        import traceback
        traceback.print_exc()
        
        # Retornar error al cliente
        return jsonify({
            'success': False,
            'error': f'Error al obtener historial de asistencias: {str(e)}'
        }), 500


"""
═══════════════════════════════════════════════════════════════════════════════
PROBARLO DESPUÉS DE AGREGARLO
═══════════════════════════════════════════════════════════════════════════════

Usar curl o Postman:

curl -X POST http://192.168.100.99:5000/api/get_attendance_history \
  -H "Content-Type: application/json" \
  -d '{
    "codigo_docente": "TU_CODIGO_DOCENTE_AQUI"
  }'

RESPUESTA ESPERADA:
{
  "success": true,
  "records": [
    {
      "fecha": "2024-01-15",
      "codigo": "EST001234",
      "nombre": "María González",
      "materia": "Programación",
      "asistio": true,
      "horasAsistidas": 4,
      "semestre": "2024-I",
      "corte": "1er Corte"
    }
  ]
}

═══════════════════════════════════════════════════════════════════════════════
AJUSTES COMUNES SEGÚN TU BD
═══════════════════════════════════════════════════════════════════════════════

1. Si tus tablas se llaman diferente:
   - Cambiar "asistencias" por el nombre de tu tabla
   - Cambiar "sesiones" por el nombre de tu tabla

2. Si tus columnas se llaman diferente:
   - a.fecha → a.tu_columna_fecha
   - a.codigo_estudiante → a.tu_columna_codigo
   - a.nombre_estudiante → a.tu_columna_nombre
   - s.materia → s.tu_columna_materia
   - s.horas_clase → s.tu_columna_horas
   - s.semestre → s.tu_columna_semestre
   - s.corte → s.tu_columna_corte

3. Si usas campo 'presente' o 'ausente' en lugar de solo registrar presentes:
   Cambiar: TRUE AS asistio
   Por: a.presente AS asistio

4. Si tienes relación diferente entre tablas:
   Ajustar el JOIN según tu estructura

═══════════════════════════════════════════════════════════════════════════════
¿PROBLEMAS? CHECKLIST
═══════════════════════════════════════════════════════════════════════════════

❌ Error 500 → Revisar nombres de tablas/columnas en el log del servidor
❌ Error "column not found" → Ajustar nombres de columnas en el SELECT
❌ Error "table not found" → Ajustar nombres de tablas en FROM/JOIN
❌ Lista vacía → Verificar que hay registros con ese codigo_docente
❌ Error de conexión → Verificar variable 'db' y conexión a BD

═══════════════════════════════════════════════════════════════════════════════
"""
