"""
ENDPOINT PARA VERIFICAR ESTUDIANTES
====================================

Este endpoint es prácticamente IGUAL al de docentes, pero consulta la tabla 'estudiantes'
en lugar de 'docentes'. Solo cambia la tabla y los campos específicos.

AGREGAR ESTO A TU SERVIDOR FLASK EXISTENTE:
"""

@app.route('/api/verify_student', methods=['POST'])
def verify_student():
    """
    Verificar si un correo electrónico corresponde a un estudiante registrado.

    MISMO FORMATO que verify_teacher, pero para estudiantes.

    Request Body:
        {
            "email": "estudiante@uceva.edu.co"
        }

    Response (200 OK):
        {
            "success": true,
            "student": {
                "codigo_estudiante": "1234567890",
                "nombre_completo": "Juan Pérez García",
                "email_institucional": "juan.perez@uceva.edu.co",
                "programa": "Ingeniería de Sistemas",
                "semestre": 5
            },
            "session_token": "token_jwt_aqui",
            "token_expires_in_hours": 24
        }

    Response (404 Not Found):
        {
            "success": false,
            "message": "Estudiante no encontrado"
        }
    """
    try:
        data = request.get_json()

        if not data or 'email' not in data:
            return jsonify({
                'success': False,
                'message': 'Email es requerido'
            }), 400

        email = data['email'].lower().strip()
        print(f"🔍 Verificando estudiante: {email}")

        # USAR LA MISMA CONEXIÓN QUE TU SERVIDOR YA TIENE
        conn = get_db_connection()

        if not conn:
            return jsonify({
                'success': False,
                'message': 'Error de conexión a la base de datos'
            }), 500

        try:
            cursor = conn.cursor(cursor_factory=RealDictCursor)

            # CONSULTA A TABLA ESTUDIANTES (misma estructura que docentes pero tabla diferente)
            query = """
                SELECT
                    codigo_estudiante,
                    nombre_completo,
                    email_institucional,
                    programa,
                    semestre
                FROM estudiantes
                WHERE LOWER(email_institucional) = %s
                LIMIT 1
            """

            cursor.execute(query, (email,))
            student = cursor.fetchone()

            cursor.close()
            conn.close()

            if student:
                print(f"✅ Estudiante encontrado: {student['nombre_completo']} ({email})")

                # Crear token JWT (igual que para docentes)
                import jwt
                import datetime
                import os

                token_payload = {
                    'codigo_estudiante': student['codigo_estudiante'],
                    'email': student['email_institucional'],
                    'tipo': 'student',
                    'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
                }

                secret_key = os.getenv('JWT_SECRET_KEY', 'tu_clave_secreta')
                session_token = jwt.encode(token_payload, secret_key, algorithm='HS256')

                return jsonify({
                    'success': True,
                    'student': dict(student),  # Convertir a dict normal
                    'session_token': session_token,
                    'token_expires_in_hours': 24
                }), 200
            else:
                print(f"❌ Estudiante NO encontrado: {email}")
                return jsonify({
                    'success': False,
                    'message': 'Estudiante no encontrado'
                }), 404

        except Exception as e:
            print(f"❌ Error en BD: {str(e)}")
            return jsonify({
                'success': False,
                'message': f'Error en base de datos: {str(e)}'
            }), 500

    except Exception as e:
        print(f"❌ Error general: {str(e)}")
        return jsonify({
            'success': False,
            'message': f'Error interno: {str(e)}'
        }), 500

"""
INSTRUCCIONES PARA AGREGAR AL SERVIDOR:
========================================

1. Copia la función verify_student() completa arriba
2. Pégala en tu servidor Flask junto al verify_teacher()
3. Asegúrate de que tengas estas importaciones:
   - from flask import request, jsonify
   - from psycopg2.extras import RealDictCursor
   - import jwt, datetime, os

4. Tu función get_db_connection() ya debe existir del verify_teacher

5. La tabla 'estudiantes' debe tener estos campos:
   - codigo_estudiante (VARCHAR)
   - nombre_completo (VARCHAR)
   - email_institucional (VARCHAR)
   - programa (VARCHAR)
   - semestre (INTEGER)

¡Eso es todo! El endpoint funcionará igual que el de docentes.
"""