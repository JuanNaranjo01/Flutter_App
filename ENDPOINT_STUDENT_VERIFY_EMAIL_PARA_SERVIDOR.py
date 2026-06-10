"""
AGREGAR ESTE ENDPOINT AL SERVIDOR FLASK (192.168.14.25)
========================================================

Problema: la app Flutter llama POST /api/student/verify-email pero esa ruta
no existe en el servidor (devuelve 404 HTML de Flask).

Los endpoints OTP ya existen en /api/student/request-otp y /api/student/verify-otp.
Agrega este bloque en el MISMO archivo donde están esos endpoints.

Si usas Blueprint `api` con url_prefix='/api', registra así:
    @api.route('/student/verify-email', methods=['POST'])

Si usas app Flask directamente:
    @app.route('/api/student/verify-email', methods=['POST'])
"""

from flask import request, jsonify
from psycopg2.extras import RealDictCursor


# --- Opción A: si tu proyecto usa Blueprint `api` (como request-otp) ---
@api.route('/student/verify-email', methods=['POST'])
def verify_student_email():
    return _verify_student_email_impl()


# --- Opción B: si usas app Flask directamente, comenta la opción A y usa:
# @app.route('/api/student/verify-email', methods=['POST'])
# def verify_student_email():
#     return _verify_student_email_impl()


def _verify_student_email_impl():
    """Verifica estudiante por email. codigo_estudiante es opcional."""
    try:
        data = request.get_json()
        print(f"🔔 verify_student_email - request body: {data}")

        if not data or 'email' not in data:
            return jsonify({'success': False, 'message': 'Email es requerido'}), 400

        email = data.get('email', '').lower().strip()
        codigo = (data.get('codigo_estudiante') or '').strip()

        if '@' not in email:
            return jsonify({'success': False, 'message': 'Email inválido'}), 400

        db = get_db_session()  # o get_db_connection() según tu proyecto
        if not db:
            return jsonify({'success': False, 'message': 'Error de conexión a la base de datos'}), 500

        try:
            cursor = db.cursor(cursor_factory=RealDictCursor)

            if codigo:
                query = """
                    SELECT
                        codigo_estudiante AS codigo,
                        nombre,
                        apellidos,
                        email_institucional
                    FROM estudiantes
                    WHERE codigo_estudiante = %s
                    LIMIT 1
                """
                cursor.execute(query, (codigo,))
                student = cursor.fetchone()
                if not student:
                    return jsonify({'success': False, 'message': f'Estudiante con código {codigo} no encontrado'}), 404

                email_bd = (student.get('email_institucional') or '').lower().strip()
                if email != email_bd:
                    return jsonify({
                        'success': False,
                        'message': 'El email no coincide con el registro del estudiante',
                    }), 200

                return jsonify({
                    'success': True,
                    'message': 'Email verificado correctamente',
                    'student': dict(student),
                }), 200

            query = """
                SELECT
                    codigo_estudiante AS codigo,
                    nombre,
                    apellidos,
                    email_institucional
                FROM estudiantes
                WHERE LOWER(TRIM(email_institucional)) = %s
                LIMIT 1
            """
            cursor.execute(query, (email,))
            student = cursor.fetchone()

            if student:
                return jsonify({
                    'success': True,
                    'message': 'Email encontrado',
                    'student': dict(student),
                }), 200

            return jsonify({
                'success': False,
                'message': f'Email {email} no encontrado en la BD',
            }), 404

        finally:
            try:
                cursor.close()
            except Exception:
                pass
            try:
                db.close()
            except Exception:
                pass

    except Exception as e:
        print(f"❌ Error en verify_student_email: {e}")
        return jsonify({'success': False, 'message': f'Error del servidor: {str(e)}'}), 500
