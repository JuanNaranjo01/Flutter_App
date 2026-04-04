# 🎯 SOLUCIÓN SIMPLE: Endpoint para Estudiantes

## ❌ Problema
Tu app Flutter está llamando a `/api/verify_student` pero este endpoint NO existe.

## ✅ Solución: Copia y pega esto en tu servidor Flask

**Solo necesitas agregar estas líneas a tu servidor Flask existente:**

```python
@app.route('/api/verify_student', methods=['POST'])
def verify_student():
    """
    Verificar estudiante - IGUAL que verify_teacher pero para tabla estudiantes
    """
    try:
        data = request.get_json()

        if not data or 'email' not in data:
            return jsonify({
                'success': False,
                'message': 'Email es requerido'
            }), 400

        email = data['email'].lower().strip()

        # USAR LA MISMA CONEXIÓN QUE YA TIENES
        conn = get_db_connection()

        if not conn:
            return jsonify({
                'success': False,
                'message': 'Error de conexión a la base de datos'
            }), 500

        try:
            cursor = conn.cursor(cursor_factory=RealDictCursor)

            # CONSULTA A TABLA ESTUDIANTES
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
                # Crear token JWT (igual que para docentes)
                import jwt, datetime, os

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
                    'student': dict(student),
                    'session_token': session_token,
                    'token_expires_in_hours': 24
                }), 200
            else:
                return jsonify({
                    'success': False,
                    'message': 'Estudiante no encontrado'
                }), 404

        except Exception as e:
            return jsonify({
                'success': False,
                'message': f'Error en base de datos: {str(e)}'
            }), 500

    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error interno: {str(e)}'
        }), 500
```

## 📋 Lo que cambia vs verify_teacher:

| verify_teacher | verify_student |
|---|---|
| `@app.route('/api/verify-teacher')` | `@app.route('/api/verify_student')` |
| `def verify_teacher():` | `def verify_student():` |
| `FROM docentes` | `FROM estudiantes` |
| Campos de docente | `codigo_estudiante, nombre_completo, email_institucional, programa, semestre` |

## 🧪 Probar:

```bash
curl -X POST http://tu-servidor/api/verify_student \
  -H "Content-Type: application/json" \
  -d '{"email": "tu-email@uceva.edu.co"}'
```

## ✅ Resultado:
- Si el email existe en `estudiantes` → Login exitoso
- Si NO existe → "Estudiante no encontrado"

**¡Eso es todo!** No necesitas crear un servidor nuevo, solo agregar esta función junto a tu `verify_teacher` existente.</content>
<parameter name="filePath">c:\FlutterProyecto\mi_app\SOLUCION_RAPIDA_VERIFY_STUDENT.md