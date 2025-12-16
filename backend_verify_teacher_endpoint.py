"""
INSTRUCCIONES: Copia y pega este código en tu servidor Flask existente
===========================================================================

OPCIÓN 1: Si tu servidor ya tiene get_db_connection() definido
---------------------------------------------------------------
Copia solo la función verify_teacher() (línea 35 en adelante)
Y agrégala con los demás endpoints

OPCIÓN 2: Si no tienes get_db_connection()
-------------------------------------------
Copia todo el código desde la línea 12 en adelante
===========================================================================
"""

from flask import request, jsonify
from psycopg2.extras import RealDictCursor

# ============================================================================
# ENDPOINT PARA VERIFICAR DOCENTES - AGREGAR A TU SERVIDOR FLASK EXISTENTE
# ============================================================================

@app.route('/api/verify-teacher', methods=['POST'])
def verify_teacher():
    """
    Verificar si un correo electrónico corresponde a un docente registrado.
    
    Request Body:
        {
            "email": "docente@uceva.edu.co"
        }
    
    Response (200 OK):
        {
            "success": true,
            "teacher": {
                "id": 1,
                "codigo": "1234567890",
                "nombre": "Juan Pérez",
                "email": "juan.perez@uceva.edu.co",
                "departamento": "HORA CATEDRA"
            }
        }
    
    Response (404 Not Found):
        {
            "success": false,
            "message": "Docente no encontrado"
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
        
        # USAR TU CONEXIÓN EXISTENTE
        # Si tu servidor tiene una función diferente para conectar, úsala aquí
        conn = get_db_connection()  # ⬅️ Ajusta esto si tu función se llama diferente
        
        if not conn:
            return jsonify({
                'success': False,
                'message': 'Error de conexión a la base de datos'
            }), 500
        
        try:
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            
            # Query ajustada a tu estructura real de tabla docentes
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
                
        except Exception as e:
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


# ===========================================================================
# INSTRUCCIONES DE USO:
# ===========================================================================
# 1. Copia la función verify_teacher() completa (líneas 35-106)
# 2. Pégala en tu servidor Flask junto a los otros endpoints
# 3. Verifica que tengas: from psycopg2.extras import RealDictCursor
# 4. Si tu función de conexión se llama diferente, ajusta línea 70
# 5. Reinicia tu servidor Flask
# 6. Prueba con: curl -X POST http://192.168.100.99:5000/api/verify-teacher \
#                -H "Content-Type: application/json" \
#                -d '{"email": "test@uceva.edu.co"}'
# ===========================================================================
