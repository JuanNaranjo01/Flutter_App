"""
INSTRUCCIONES: Copia y pega este código en tu servidor Flask existente
===========================================================================

Este endpoint verifica que el email del estudiante exista en la BD.
Se usa en el flujo de autenticación con Google Sign In para estudiantes.

OPCIÓN 1: Si tu servidor ya tiene get_db_connection() definido
---------------------------------------------------------------
Copia solo la función verify_student_email() (línea ~50 en adelante)
Y agrégala con los demás endpoints

OPCIÓN 2: Si no tienes get_db_connection()
-------------------------------------------
Copia todo el código desde la línea ~12 en adelante
===========================================================================
"""

from flask import request, jsonify
from psycopg2.extras import RealDictCursor

# ============================================================================
# ENDPOINT PARA VERIFICAR EMAIL DE ESTUDIANTE (GOOGLE SIGN IN)
# ============================================================================

@app.route('/api/student/verify-email', methods=['POST'])
def verify_student_email():
    """
    Verifica que el email del estudiante exista en la BD.
    
    Request Body:
        {
            "email": "estudiante@uceva.edu.co",
            "codigo_estudiante": "20221234567"
        }
    
    Response (200 OK) - Email válido:
        {
            "success": true,
            "message": "Email verificado correctamente",
            "student": {
                "codigo": "20221234567",
                "nombre": "Juan García",
                "correo_institucional": "juan.garcia@uceva.edu.co"
            }
        }
    
    Response (200 OK) - Email no coincide:
        {
            "success": false,
            "message": "El email no coincide con el registro del estudiante"
        }
    
    Response (404 Not Found):
        {
            "success": false,
            "message": "Estudiante no encontrado en la BD"
        }
    
    Response (400 Bad Request):
        {
            "success": false,
            "message": "Email o código de estudiante son requeridos"
        }
    
    Response (500 Server Error):
        {
            "success": false,
            "message": "Error al conectar con la base de datos"
        }
    """
    try:
        data = request.get_json()
        
        # Validar que los parámetros estén presentes
        if not data:
            return jsonify({
                'success': False,
                'message': 'Request body es requerido'
            }), 400
        
        email = data.get('email', '').strip().lower()
        codigo_estudiante = data.get('codigo_estudiante', '').strip()
        
        if not email or not codigo_estudiante:
            return jsonify({
                'success': False,
                'message': 'Email y código de estudiante son requeridos'
            }), 400
        
        # Conectar a la BD
        conn = get_db_connection()  # ⬅️ Ajusta esto si tu función se llama diferente
        
        if not conn:
            return jsonify({
                'success': False,
                'message': 'Error de conexión a la base de datos'
            }), 500
        
        try:
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            
            # PASO 1: Buscar al estudiante por código
            query_student = """
                SELECT 
                    "Codigo" as codigo,
                    "Nombre" as nombre,
                    "Correo_institucional" as correo_institucional
                FROM estudiantes
                WHERE "Codigo" = %s
                LIMIT 1
            """
            
            cursor.execute(query_student, (codigo_estudiante,))
            student = cursor.fetchone()
            
            # Si no existe el estudiante
            if not student:
                cursor.close()
                conn.close()
                print(f"❌ Estudiante no encontrado: {codigo_estudiante}")
                return jsonify({
                    'success': False,
                    'message': f'Estudiante con código {codigo_estudiante} no encontrado'
                }), 404
            
            # PASO 2: Comparar el email proporcionado con el de la BD
            email_en_bd = student.get('correo_institucional', '').lower().strip()
            
            if email == email_en_bd:
                # ✅ Email válido - proceder con Google Sign In
                cursor.close()
                conn.close()
                print(f"✅ Email verificado: {email} para estudiante {codigo_estudiante}")
                return jsonify({
                    'success': True,
                    'message': 'Email verificado correctamente',
                    'student': {
                        'codigo': student['codigo'],
                        'nombre': student['nombre'],
                        'correo_institucional': student['correo_institucional']
                    }
                }), 200
            else:
                # ❌ Email no coincide
                cursor.close()
                conn.close()
                print(f"❌ Email no coincide: {email} != {email_en_bd}")
                return jsonify({
                    'success': False,
                    'message': f'El email {email} no coincide con el registro del estudiante. Email esperado: {email_en_bd}'
                }), 200  # Devolver 200 pero success=false para que el cliente sepa que fue un error de validación
            
        except Exception as db_error:
            print(f"❌ Error en base de datos: {str(db_error)}")
            cursor.close() if 'cursor' in locals() else None
            conn.close() if conn else None
            return jsonify({
                'success': False,
                'message': f'Error al consultar la base de datos: {str(db_error)}'
            }), 500
    
    except Exception as e:
        print(f"❌ Error en verify_student_email: {str(e)}")
        return jsonify({
            'success': False,
            'message': f'Error del servidor: {str(e)}'
        }), 500


# ============================================================================
# INFORMACIÓN SOBRE LA TABLA DE ESTUDIANTES
# ============================================================================
"""
Asume que tu tabla de estudiantes tiene al menos estas columnas:
- "Codigo" (VARCHAR): Código único del estudiante
- "Nombre" (VARCHAR): Nombre completo
- "Correo_institucional" (VARCHAR): Email institucional

Si tu estructura es diferente, AJUSTA el query SQL en la función verify_student_email()

Ejemplo de estructura típica:
CREATE TABLE estudiantes (
    "Id_estudiante" SERIAL PRIMARY KEY,
    "Codigo" VARCHAR(20) UNIQUE NOT NULL,
    "Nombre" VARCHAR(255) NOT NULL,
    "Apellido" VARCHAR(255),
    "Correo_institucional" VARCHAR(255),
    "Correo_personal" VARCHAR(255),
    "Telefono" VARCHAR(20),
    "Foto_perfil" TEXT,
    "Fecha_registro" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"""

# ============================================================================
# NOTAS IMPORTANTES
# ============================================================================
"""
1. SEGURIDAD:
   - Este endpoint es de solo lectura (SELECT)
   - No almacena ni modifica datos
   - Solo valida la existencia y correspondencia del email
   - El usuario proporciona el email desde su cuenta Google

2. FLUJO:
   - Frontend: Usuario hace Google Sign In
   - Frontend obtiene el email del usuario autenticado
   - Frontend envía: email + codigo_estudiante a esta API
   - Backend valida que el email coincida con el del estudiante
   - Si es válido: procede con captura de facial embeddings
   - Si no coincide: muestra error, pide que use la cuenta correcta

3. CASOS DE ERROR:
   - 400: Faltan parámetros
   - 404: Estudiante no existe
   - 200 con success=false: Email no coincide (error de validación)
   - 500: Error de conexión a BD

4. PRÓXIMOS PASOS:
   - Después de esta validación, el frontend captura la facial embeddings
   - Se llama a /api/register_student_embeddings con los frames capturados
"""
