"""
===============================================================================
ENDPOINT PARA VERIFICAR DOCENTES - AGREGAR A api_routes.py
===============================================================================

UBICACIÓN: /var/www/reconocimientoFacial_asisencias/api_routes.py
LÍNEA SUGERIDA: Después de search_student (línea ~1560)

INSTRUCCIONES:
1. Conectarte al servidor: ssh admin-rf@192.168.100.99
2. Editar archivo: nano /var/www/reconocimientoFacial_asisencias/api_routes.py
3. Ir a la línea ~1560 (después del endpoint search_student)
4. Copiar y pegar el código de abajo
5. Guardar (Ctrl+O, Enter, Ctrl+X)
6. Reiniciar servidor: pkill -f gunicorn && ./start_server.sh

===============================================================================
"""

@api.route('/verify-teacher', methods=['POST'])
def verify_teacher():
    """
    Verificar si un correo electrónico corresponde a un docente registrado.
    Similar a search_student pero busca en tabla docentes por correo.
    
    Request Body:
    {
        "email": "docente@uceva.edu.co"
    }
    
    Response Success (200):
    {
        "success": true,
        "teacher": {
            "id": 1,
            "codigo": "1234567890",
            "nombre": "GIOVANNA GIL ISAZIGA",
            "email": "giovanna@uceva.edu.co",
            "departamento": "HORA CATEDRA",
            "correo_institucional": "giovanna.gil@uceva.edu.co",
            "Periodo": "2025-2",
            "Semestre": "I"
        }
    }
    
    Response Error (404):
    {
        "success": false,
        "message": "Docente no encontrado"
    }
    """
    try:
        # Obtener funciones importadas (patrón usado en el servidor)
        imports = get_imports()
        if not imports:
            return jsonify({
                'success': False,
                'message': 'Error cargando módulos del servidor'
            }), 500
        
        # Validar request
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
        
        # ================================================
        # BUSCAR DOCENTE EN BASE DE DATOS
        # ================================================
        # Obtener sesión de BD (igual que search_student)
        db = imports['get_db_session']()
        
        # Query a tabla docentes de BIENESTAR
        # Usar nombres exactos de columnas según la estructura real
        result = db.execute(text("""
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
            WHERE LOWER("Correo personal") = :email
            LIMIT 1
        """), {'email': email})
        
        # Obtener resultado
        docente = result.fetchone()
        
        # Cerrar conexión (IMPORTANTE)
        db.close()
        
        # ================================================
        # RESPUESTA
        # ================================================
        if docente:
            # Convertir Row a dict
            teacher_data = {
                'id': docente[0],
                'codigo': docente[1],
                'nombre': docente[2],
                'email': docente[3],
                'departamento': docente[4],
                'correo_institucional': docente[5],
                'Periodo': docente[6],
                'Semestre': docente[7]
            }
            
            print(f"✅ Docente encontrado: {teacher_data['nombre']} ({email})")
            
            return jsonify({
                'success': True,
                'teacher': teacher_data
            }), 200
        else:
            print(f"❌ Docente NO encontrado: {email}")
            
            return jsonify({
                'success': False,
                'message': 'Docente no encontrado en el sistema'
            }), 404
        
    except Exception as e:
        # Log del error (importante para debugging)
        print(f"❌ Error en verify_teacher: {e}")
        traceback.print_exc()
        
        return jsonify({
            'success': False,
            'message': f'Error del servidor: {str(e)}'
        }), 500


"""
===============================================================================
TESTING DEL ENDPOINT
===============================================================================

Después de agregar el código y reiniciar el servidor, probar con:

1. Health check del servidor:
   curl http://192.168.100.99:5000/api/health

2. Probar verify-teacher con curl:
   curl -X POST http://192.168.100.99:5000/api/verify-teacher \
     -H "Content-Type: application/json" \
     -d '{"email": "giovanna@uceva.edu.co"}'

3. Desde Flutter (ya configurado en ApiConfig):
   El endpoint ya está configurado como:
   ApiConfig.verifyTeacherEndpoint = '/api/verify-teacher'
   
   La app Flutter llamará automáticamente a:
   http://192.168.100.99:5000/api/verify-teacher

===============================================================================
VERIFICACIÓN
===============================================================================

✓ El endpoint sigue el mismo patrón que search_student
✓ Usa get_imports() para obtener get_db_session()
✓ Usa SQLAlchemy con text() para queries
✓ Usa los nombres exactos de columnas de la tabla docentes
✓ Cierra la conexión con db.close()
✓ Retorna JSON en formato consistente
✓ Incluye logs para debugging
✓ Maneja errores con try-except

===============================================================================
NOTAS IMPORTANTES
===============================================================================

1. La tabla 'docentes' tiene 33 registros (según BIENESTAR)
2. Las columnas usan nombres con espacios ("Correo personal", etc.)
3. El servidor ya está configurado en Flutter: 192.168.100.99:5000
4. El endpoint seguirá disponible después de reiniciar el servidor
5. Los logs se guardarán en /var/log/gunicorn/error.log

===============================================================================
"""
