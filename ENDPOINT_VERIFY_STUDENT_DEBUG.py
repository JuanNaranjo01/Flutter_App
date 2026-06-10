"""
COPIA ESTE CÓDIGO EN TU BACKEND - Reemplaza tu endpoint /api/verify-student actual
Este versión tiene logs detallados para depurar el problema
"""

@api.route('/api/verify-student', methods=['POST'])
def verify_student():
    """Verifica si un email corresponde a un estudiante registrado."""
    try:
        data = request.get_json()
        print(f"📥 Request body recibido: {data}")
        
        if not data or 'email' not in data:
            print("❌ Error: Email no proporcionado en el request")
            return jsonify({'success': False, 'message': 'Email es requerido'}), 400

        email = data.get('email', '').lower().strip()
        print(f"📧 Email normalizado: '{email}'")
        
        if '@' not in email:
            print("❌ Error: Email inválido (no tiene @)")
            return jsonify({'success': False, 'message': 'Email inválido'}), 400

        # Obtener conexión
        db = get_db_session()
        if not db:
            print("❌ Error: No se pudo obtener conexión a BD")
            return jsonify({'success': False, 'message': 'Error de conexión a la base de datos'}), 500

        try:
            cursor = db.cursor(cursor_factory=RealDictCursor)
            
            # PRIMERO: Verificar qué emails existen en la BD (para debug)
            print("🔍 Consultando todos los emails en la tabla estudiantes...")
            cursor.execute("SELECT codigo_estudiante, email_institucional FROM estudiantes LIMIT 10")
            all_students = cursor.fetchall()
            print(f"📋 Muestra de estudiantes en BD: {all_students}")
            
            # SEGUNDO: Buscar el email específico
            query = """
                SELECT
                    codigo_estudiante as codigo,
                    nombre,
                    apellidos,
                    email_institucional
                FROM estudiantes
                WHERE LOWER(TRIM(email_institucional)) = %s
                LIMIT 1
            """
            print(f"🔍 Ejecutando query con email: '{email}'")
            cursor.execute(query, (email,))
            student = cursor.fetchone()
            print(f"🎯 Resultado de la búsqueda: {student}")
            
            cursor.close()
            db.close()

            if student:
                print(f"✅ Estudiante encontrado: {student}")
                return jsonify({'success': True, 'student': dict(student)}), 200
            else:
                print(f"❌ Estudiante no encontrado con email: '{email}'")
                return jsonify({'success': False, 'message': 'Estudiante no encontrado'}), 404

        except Exception as e:
            print(f"❌ Error en consulta SQL: {str(e)}")
            try:
                cursor.close()
            except:
                pass
            try:
                db.close()
            except:
                pass
            return jsonify({'success': False, 'message': f'Error en la consulta: {str(e)}'}), 500

    except Exception as e:
        print(f"❌ Error del servidor: {str(e)}")
        return jsonify({'success': False, 'message': f'Error del servidor: {str(e)}'}), 500
