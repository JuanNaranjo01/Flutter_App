"""
ENDPOINT: Verificar estudiante por correo
======================================

Instrucciones:
- Copia todo el contenido de este archivo y pégalo junto a los demás endpoints
  en el servidor Flask (por ejemplo en `api_routes.py` o donde tengas los `@app.route`).
- Este archivo asume que existe una variable `app` (Flask) en el módulo destino
  y una función `get_db_connection()` disponible. Si tu función de conexión se
  llama diferente, reemplaza la llamada.

Descripción:
- Endpoint: POST /api/verify-student
- Body: {"email": "estudiante@uceva.edu.co"}
- Respuesta 200 (success): {'success': True, 'student': {...}}
- Respuesta 404 (no encontrado): {'success': False, 'message': 'Estudiante no encontrado'}
"""

from flask import request, jsonify
from psycopg2.extras import RealDictCursor


@api.route('/api/verify-student', methods=['POST'])
def verify_student():
    """Verifica si un email corresponde a un estudiante registrado.

    Usa la conexión proporcionada por la app: `conn = get_db_connection()`.
    Ajusta el nombre de la función si tu proyecto usa otro helper.
    """
    try:
        data = request.get_json()
        if not data or 'email' not in data:
            return jsonify({'success': False, 'message': 'Email es requerido'}), 400

        email = data.get('email', '').lower().strip()
        if '@' not in email:
            return jsonify({'success': False, 'message': 'Email inválido'}), 400

        # Obtener conexión (usa tu helper de conexión)
        db = get_db_session()  # Ajusta si tu función se llama distinto
        if not db:
            return jsonify({'success': False, 'message': 'Error de conexión a la base de datos'}), 500

        try:
            cursor = db.cursor(cursor_factory=RealDictCursor)
            query = """
                SELECT
                    codigo_estudiante as codigo,
                    nombre,
                    apellidos,
                    email_institucional
                FROM estudiantes
                WHERE LOWER(email_institucional) = %s
                LIMIT 1
            """
            cursor.execute(query, (email,))
            student = cursor.fetchone()
            cursor.close()
            db.close()

            if student:
                return jsonify({'success': True, 'student': dict(student)}), 200
            else:
                return jsonify({'success': False, 'message': 'Estudiante no encontrado'}), 404

        except Exception as e:
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
        return jsonify({'success': False, 'message': f'Error del servidor: {str(e)}'}), 500
z