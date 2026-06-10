"""
Servidor Flask para AsistenciaGuard UCEVA
Endpoint para verificar docentes en la tabla 'docentes'
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
import os

app = Flask(__name__)
CORS(app)  # Permitir peticiones desde Flutter

# ========================================
# CONFIGURACIÓN DE LA BASE DE DATOS
# ========================================
# ⚠️ IMPORTANTE: Actualizar con tus credenciales reales
DB_CONFIG = {
    'host': os.getenv('DB_HOST', '192.168.100.99'),  # Cambiar por tu host
    'database': os.getenv('DB_NAME', 'tu_base_datos'),  # Cambiar por tu BD
    'user': os.getenv('DB_USER', 'tu_usuario'),  # Cambiar por tu usuario
    'password': os.getenv('DB_PASSWORD', 'tu_password'),  # Cambiar por tu password
    'port': int(os.getenv('DB_PORT', 5432))
}


def get_db_connection():
    """Crear conexión a la base de datos PostgreSQL"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except psycopg2.Error as e:
        print(f"❌ Error conectando a la base de datos: {e}")
        return None


@app.route('/api/verify-teacher', methods=['POST'])
def verify_teacher():
    """
    Verificar si un correo electrónico corresponde a un docente registrado.
    
    Request Body:
        {
            "email": "docente@uceva.edu.co"
        }
    
    Response (200 OK - Docente encontrado):
        {
            "success": true,
            "teacher": {
                "id": 1,
                "codigo": "DOC12345",
                "nombre": "Juan Pérez",
                "email": "juan.perez@uceva.edu.co",
                "departamento": "Ingeniería de Sistemas"
            }
        }
    
    Response (404 Not Found - Docente NO encontrado):
        {
            "success": false,
            "message": "Docente no encontrado"
        }
    """
    try:
        # Obtener datos del request
        data = request.get_json()
        
        if not data or 'email' not in data:
            return jsonify({
                'success': False,
                'message': 'Email es requerido'
            }), 400
        
        email = data['email'].lower().strip()
        
        # Validar formato de email
        if '@' not in email:
            return jsonify({
                'success': False,
                'message': 'Email inválido'
            }), 400
        
        # Conectar a la base de datos
        conn = get_db_connection()
        if not conn:
            return jsonify({
                'success': False,
                'message': 'Error de conexión a la base de datos'
            }), 500
        
        try:
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            
            # Consulta ajustada a la estructura real de la tabla docentes
            query = """
                SELECT 
                    "Id_docente" as id,
                    "Identificacion" as codigo,
                    "Nombre" as nombre,
                    "Correo personal" as email,
                    "Dedicacion" as departamento,
                    "Correo Institucional" as correo_institucional,
                    "Periodo",
                    "Semestre"
                FROM docentes
                WHERE LOWER("Correo personal") = %s
                LIMIT 1
            """
            
            cursor.execute(query, (email,))
            teacher = cursor.fetchone()
            
            cursor.close()
            conn.close()
            
            if teacher:
                print(f"✅ Docente encontrado: {teacher['nombre']} ({email})")
                return jsonify({
                    'success': True,
                    'teacher': dict(teacher)
                }), 200
            else:
                print(f"❌ Docente NO encontrado: {email}")
                return jsonify({
                    'success': False,
                    'message': 'Docente no encontrado'
                }), 404
                
        except psycopg2.Error as e:
            if conn:
                conn.close()
            print(f"❌ Error en la consulta SQL: {e}")
            return jsonify({
                'success': False,
                'message': f'Error en la consulta: {str(e)}'
            }), 500
            
    except Exception as e:
        print(f"❌ Error general: {e}")
        return jsonify({
            'success': False,
            'message': f'Error del servidor: {str(e)}'
        }), 500


@app.route('/api/health', methods=['GET'])
def health_check():
    """Endpoint para verificar que el servidor está funcionando"""
    return jsonify({
        'status': 'ok',
        'message': 'Servidor AsistenciaGuard funcionando correctamente'
    }), 200


@app.route('/api/student/verify-email', methods=['POST'])
def verify_student_email():
    """Verifica que el email del estudiante exista en la BD.

    Comportamiento:
      - Si llega `codigo_estudiante` en el body: busca por código y compara el email proporcionado
      - Si NO llega código: busca por email y devuelve el registro si existe
    Request Body ejemplo:
      {"email": "estudiante@uceva.edu.co"}
      {"email": "estudiante@uceva.edu.co", "codigo_estudiante": "20221234567"}
    """
    try:
        data = request.get_json()
        print(f"🔔 verify_student_email - request body: {data}")

        if not data or 'email' not in data:
            return jsonify({'success': False, 'message': 'Email es requerido'}), 400

        email = data.get('email', '').lower().strip()
        codigo = data.get('codigo_estudiante', '')

        conn = get_db_connection()
        if not conn:
            return jsonify({'success': False, 'message': 'Error de conexión a la base de datos'}), 500

        try:
            cursor = conn.cursor(cursor_factory=RealDictCursor)

            if codigo:
                # Buscar por código y comparar email
                query = """
                    SELECT
                        codigo_estudiante as codigo,
                        nombre as nombre,
                        apellidos as apellidos,
                        email_institucional as email_institucional
                    FROM estudiantes
                    WHERE codigo_estudiante = %s
                    LIMIT 1
                """
                cursor.execute(query, (codigo,))
                student = cursor.fetchone()
                print(f"🔎 Consulta por codigo {codigo}: {student}")
                if not student:
                    cursor.close(); conn.close()
                    return jsonify({'success': False, 'message': f'Estudiante con código {codigo} no encontrado'}), 404

                email_bd = (student.get('email_institucional') or '').lower().strip()
                if email == email_bd:
                    cursor.close(); conn.close()
                    return jsonify({'success': True, 'message': 'Email verificado correctamente', 'student': dict(student)}), 200
                else:
                    cursor.close(); conn.close()
                    return jsonify({'success': False, 'message': 'El email no coincide con el registro del estudiante', 'debug': {'email_recibido': email, 'email_en_bd': email_bd, 'codigo_estudiante': codigo}}), 200
            else:
                # Buscar por email directamente
                query = """
                    SELECT
                        codigo_estudiante as codigo,
                        nombre as nombre,
                        apellidos as apellidos,
                        email_institucional as email_institucional
                    FROM estudiantes
                    WHERE LOWER(email_institucional) = %s
                    LIMIT 1
                """
                cursor.execute(query, (email,))
                student = cursor.fetchone()
                print(f"🔎 Consulta por email {email}: {student}")
                cursor.close(); conn.close()
                if student:
                    return jsonify({'success': True, 'message': 'Email encontrado', 'student': dict(student)}), 200
                else:
                    return jsonify({'success': False, 'message': f'Email {email} no encontrado en la BD'}), 404

        except Exception as e:
            print(f"❌ Error en la consulta SQL verify_student_email: {e}")
            try:
                cursor.close()
            except:
                pass
            try:
                conn.close()
            except:
                pass
            return jsonify({'success': False, 'message': f'Error en la consulta: {str(e)}'}), 500

    except Exception as e:
        print(f"❌ Error en verify_student_email: {e}")
        return jsonify({'success': False, 'message': f'Error del servidor: {str(e)}'}), 500


if __name__ == '__main__':
    print("=" * 60)
    print("🚀 Servidor AsistenciaGuard UCEVA")
    print("=" * 60)
    print(f"📍 Host: 0.0.0.0")
    print(f"🔌 Puerto: 5000")
    print(f"🔗 Endpoint: POST /api/verify-teacher")
    print(f"❤️  Health check: GET /api/health")
    print("=" * 60)
    print("⚠️  RECUERDA: Actualizar DB_CONFIG con tus credenciales reales")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=5000, debug=True)
