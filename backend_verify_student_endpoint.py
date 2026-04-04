"""
INSTRUCCIONES: Copia y pega este código en tu servidor Flask existente
===========================================================================

OPCIÓN 1: Si tu servidor ya tiene get_db_connection() definido
---------------------------------------------------------------
Copia solo la función verify_student() (línea 35 en adelante)
Y agrégala con los demás endpoints

OPCIÓN 2: Si no tienes get_db_connection()
--------------------------------------------
Copia todo el código desde la línea 12 en adelante
===========================================================================
"""

from flask import request, jsonify
from psycopg2.extras import RealDictCursor
import jwt
import datetime
import os

# ============================================================================
# ENDPOINT PARA VERIFICAR ESTUDIANTES - AGREGAR A TU SERVIDOR FLASK EXISTENTE
# ============================================================================

@app.route('/api/verify_student', methods=['POST'])
def verify_student():
    """
    Verificar si un correo electrónico corresponde a un estudiante registrado.

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
            "session_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
            "token_expires_in_hours": 24
        }

    Response (404 Not Found):
        {
            "success": false,
            "message": "Estudiante no encontrado"
        }
    """
    try:
        # Obtener datos del request
        data = request.get_json()
        if not data or 'email' not in data:
            return jsonify({
                'success': False,
                'message': 'Email requerido'
            }), 400

        email = data['email'].strip().lower()
        print(f"🔍 Verificando estudiante con email: {email}")

        # Conectar a la base de datos
        conn = get_db_connection()
        if conn is None:
            return jsonify({
                'success': False,
                'message': 'Error de conexión a la base de datos'
            }), 500

        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Buscar estudiante por email institucional
                cursor.execute("""
                    SELECT
                        e.codigo_estudiante,
                        e.nombre_completo,
                        e.email_institucional,
                        e.programa,
                        e.semestre
                    FROM estudiantes e
                    WHERE LOWER(e.email_institucional) = %s
                    LIMIT 1
                """, (email,))

                student_row = cursor.fetchone()

                if student_row:
                    # Crear token de sesión
                    token_payload = {
                        'codigo_estudiante': student_row['codigo_estudiante'],
                        'email': student_row['email_institucional'],
                        'tipo': 'student',
                        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
                    }

                    # Usar una clave secreta (deberías tener una variable de entorno para esto)
                    secret_key = os.getenv('JWT_SECRET_KEY', 'tu_clave_secreta_aqui')
                    session_token = jwt.encode(token_payload, secret_key, algorithm='HS256')

                    # Convertir a diccionario y asegurar que los valores sean serializables
                    student_data = dict(student_row)
                    for key, value in student_data.items():
                        if isinstance(value, datetime.date):
                            student_data[key] = value.isoformat()

                    print(f"✅ Estudiante encontrado: {student_row['nombre_completo']}")

                    return jsonify({
                        'success': True,
                        'student': student_data,
                        'session_token': session_token,
                        'token_expires_in_hours': 24
                    }), 200
                else:
                    print(f"❌ Estudiante no encontrado con email: {email}")
                    return jsonify({
                        'success': False,
                        'message': 'Estudiante no encontrado'
                    }), 404

        except Exception as e:
            print(f"❌ Error en consulta de base de datos: {str(e)}")
            return jsonify({
                'success': False,
                'message': f'Error en base de datos: {str(e)}'
            }), 500
        finally:
            conn.close()

    except Exception as e:
        print(f"❌ Error general en verify_student: {str(e)}")
        return jsonify({
            'success': False,
            'message': f'Error interno del servidor: {str(e)}'
        }), 500


# ============================================================================
# FUNCIÓN AUXILIAR PARA CONEXIÓN A BD (SI NO LA TIENES)
# ============================================================================

def get_db_connection():
    """Crear conexión a la base de datos PostgreSQL"""
    try:
        import psycopg2

        # ⚠️ IMPORTANTE: Actualizar con tus credenciales reales
        DB_CONFIG = {
            'host': os.getenv('DB_HOST', '192.168.100.99'),  # Cambiar por tu host
            'database': os.getenv('DB_NAME', 'tu_base_datos'),  # Cambiar por tu BD
            'user': os.getenv('DB_USER', 'tu_usuario'),  # Cambiar por tu usuario
            'password': os.getenv('DB_PASSWORD', 'tu_password'),  # Cambiar por tu password
            'port': int(os.getenv('DB_PORT', 5432))
        }

        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        print(f"❌ Error conectando a la base de datos: {e}")
        return None


# ============================================================================
# EJEMPLO DE USO Y TESTING
# ============================================================================

if __name__ == '__main__':
    # Para testing local
    app.run(debug=True, host='0.0.0.0', port=5000)