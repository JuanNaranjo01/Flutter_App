from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3  # Cambia esto por tu motor de base de datos real

app = Flask(__name__)
CORS(app)

# Configuración de la base de datos
DATABASE = 'ruta_a_tu_base_de_datos.db'

def get_db_connection():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/api/verify-teacher-email', methods=['POST'])
def verify_teacher_email():
    data = request.get_json()
    correo_personal = data.get('correo_personal')
    if not correo_personal:
        return jsonify({'success': False, 'message': 'correo_personal requerido'}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM docentes WHERE `Correo personal` = ?", (correo_personal,))
    row = cursor.fetchone()
    conn.close()

    if row:
        # Convertir el row a dict
        docente = {key: row[key] for key in row.keys()}
        return jsonify({'success': True, 'found': True, 'docente': docente})
    else:
        return jsonify({'success': False, 'found': False, 'message': 'No autorizado'}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
