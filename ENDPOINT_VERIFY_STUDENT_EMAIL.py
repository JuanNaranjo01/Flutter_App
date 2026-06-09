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

# Registrar en la aplicación principal que corre bajo gunicorn
# Importar `app` y `get_db_connection` desde el módulo principal
try:
    from verify_teacher_email import app, get_db_connection
    print('✅ Imported app and get_db_connection from verify_teacher_email')
except Exception as e:
    # Si no está disponible en este contexto, dejamos una nota en logs
    print(f'⚠️ No se pudo importar app/get_db_connection desde verify_teacher_email: {e}')
    app = None

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
        # DEBUG: registrar body recibido
        print(f"🔔 verify_student_email - request body: {data}")
        
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
        try:
            conn = get_db_connection()  # ⬅️ Ajusta esto si tu función se llama diferente
            print("🔌 get_db_connection() ejecutada correctamente")
        except NameError as ne:
            print(f"❌ get_db_connection no encontrada: {ne}")
            return jsonify({
                'success': False,
                'message': 'get_db_connection no definida en la app'
            }), 500
        except Exception as conn_err:
            print(f"❌ Error al obtener conexión a BD: {conn_err}")
            return jsonify({
                'success': False,
                'message': 'Error de conexión a la base de datos'
            }), 500
        
        try:
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            
            # PASO 1: Buscar al estudiante por código (columnas reales proporcionadas)
            query_student = """
                SELECT
                    codigo_estudiante as codigo,
                    nombre as nombre,
                    apellidos as apellidos,
                    email_institucional as email_institucional
                FROM estudiantes
                WHERE codigo_estudiante = %s
                LIMIT 1
            """
            
            cursor.execute(query_student, (codigo_estudiante,))
            student = cursor.fetchone()
            # DEBUG: mostrar resultado bruto de la consulta
            print(f"🔎 Resultado consulta estudiante para {codigo_estudiante}: {student}")
            
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
            email_en_bd = student.get('email_institucional', '')
            email_en_bd_norm = (email_en_bd or '').lower().strip()
            print(f"   - email recibido: {email}")
            print(f"   - email en BD raw: {email_en_bd}")
            print(f"   - email en BD normalizado: {email_en_bd_norm}")
            
            if email == email_en_bd_norm:
                # ✅ Email válido - proceder con Google Sign In
                cursor.close()
                conn.close()
                print(f"✅ Email verificado: {email} para estudiante {codigo_estudiante}")
                return jsonify({
                    'success': True,
                    'message': 'Email verificado correctamente',
                    'student': {
                        'codigo': student.get('codigo'),
                        'nombre': student.get('nombre'),
                        'apellidos': student.get('apellidos'),
                        'email_institucional': student.get('email_institucional')
                    }
                }), 200
            else:
                # ❌ Email no coincide
                cursor.close()
                conn.close()
                print(f"❌ Email no coincide: {email} != {email_en_bd_norm}")
                return jsonify({
                    'success': False,
                    'message': f'El email {email} no coincide con el registro del estudiante. Email esperado: {email_en_bd_norm}',
                    'debug': {
                        'email_recibido': email,
                        'email_en_bd': email_en_bd,
                        'codigo_estudiante': codigo_estudiante
                    }
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
    
    except Exception as e:
        print(f"❌ Error en verify_student_email: {str(e)}")
        return jsonify({
            'success': False,
            'message': f'Error del servidor: {str(e)}'
        }), 500


# Registrar la ruta en la app principal si está disponible (gunicorn usa verify_teacher_email.py)
if app:
    try:
        app.add_url_rule('/api/student/verify-email', 'verify_student_email', verify_student_email, methods=['POST'])
        print('🔗 Ruta /api/student/verify-email registrada en app')
    except Exception as e:
        print(f'❌ Error registrando ruta en app: {e}')


# ============================================================================
# INFORMACIÓN SOBRE LA TABLA DE ESTUDIANTES
# ============================================================================
"""
Asume que tu tabla de estudiantes tiene al menos estas columnas (según lo indicado):
- `codigo_estudiante` (VARCHAR): Código único del estudiante
- `nombre` (VARCHAR): Nombre
- `apellidos` (VARCHAR): Apellidos
- `email_institucional` (VARCHAR): Email institucional
- `telefonos`, `movil`, `jornada` (opcional)

Si tu estructura es diferente, AJUSTA el query SQL en la función `verify_student_email()` para usar los nombres reales.

Ejemplo mínimo basado en tu esquema:
CREATE TABLE estudiantes (
    id SERIAL PRIMARY KEY,
    codigo_estudiante VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    apellidos VARCHAR(255),
    email_institucional VARCHAR(255),
    telefonos TEXT,
    movil VARCHAR(50),
    jornada VARCHAR(50),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
