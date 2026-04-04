@api.route('/verify_student', methods=['POST'])
def verify_student():
    """
    Verificar si un correo electrónico corresponde a un estudiante registrado.
    Similar a verify_teacher pero busca en tabla estudiantes por email_institucional.

    Request Body:
    {
        "email": "estudiante@uceva.edu.co"
    }

    Response Success (200):
    {
        "success": true,
        "student": {
            "codigo_estudiante": "1234567890",
            "nombre": "JUAN",
            "apellidos": "PEREZ GARCIA",
            "email_institucional": "juan.perez@uceva.edu.co",
            "telefono": "5551234",
            "movil": "3001234567",
            "programa_academico": "ADMINISTRACIÓN DE EMPRESAS",
            "jornada": "DIURNA",
            "semestre": 5,
            "fecha_matricula": "2025-01-20"
        }
    }
    
    Response Error (404):
    {
        "success": false,
        "message": "Estudiante no encontrado"
    }
    """
    try:
        # Validar request - IGUAL al de docentes
        data = request.get_json()
        if not data or 'email' not in data:
            return jsonify({
                'success': False,
                'message': 'Email es requerido'
            }), 400

        email = data['email'].lower().strip()

        # Validar formato de email - IGUAL al de docentes
        if '@' not in email:
            return jsonify({
                'success': False,
                'message': 'Email inválido'
            }), 400

        # Obtener sesión de BD - IGUAL al de docentes
        db = get_db_session()
        
        # Query con nombres EXACTOS de columnas según estructura de BD
        result = db.execute(text("""
            SELECT
                codigo_estudiante,
                nombre,
                apellidos,
                email_institucional,
                telefono,
                movil,
                programa_academico,
                jornada,
                semestre,
                fecha_matricula
            FROM estudiantes
            WHERE LOWER(email_institucional) = :email
            LIMIT 1
        """), {'email': email})

        estudiante = result.fetchone()
        db.close()

        if estudiante:
            student_data = {
                'codigo_estudiante': estudiante[0],
                'nombre': estudiante[1],
                'apellidos': estudiante[2],
                'email_institucional': estudiante[3],
                'telefono': estudiante[4],
                'movil': estudiante[5],
                'programa_academico': estudiante[6],
                'jornada': estudiante[7],
                'semestre': estudiante[8],
                'fecha_matricula': str(estudiante[9]) if estudiante[9] else None
            }
            
            # Crear sesión para el estudiante - IGUAL que docentes
            session_token = create_teacher_session(
                estudiante[0],
                estudiante[1],
                duracion_horas=8
            )
            print(f"Estudiante encontrado: {student_data['nombre']} {student_data['apellidos']} ({email})")
            print(f"Token de sesión generado: {session_token[:8]}...")
            
            return jsonify({
                'success': True,
                'student': student_data,
                'session_token': session_token,
                'token_expires_in_hours': 8
            }), 200
        else:
            print(f"Estudiante NO encontrado: {email}")

            return jsonify({
                'success': False,
                'message': 'Estudiante no encontrado en el sistema'
            }), 404

    except Exception as e:
        print(f"Error en verify_student: {e}")
        traceback.print_exc()

        return jsonify({
            'success': False,
            'message': f'Error del servidor: {str(e)}'
        }), 500
