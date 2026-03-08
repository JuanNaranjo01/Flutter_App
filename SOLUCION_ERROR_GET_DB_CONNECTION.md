# 🔧 SOLUCIÓN ERROR: `get_db_connection` is not defined

## ❌ Error Actual:
```
NameError: name 'get_db_connection' is not defined
```

---

## ✅ OPCIÓN A: Reemplazar en el Endpoint (Rápida)

### 1. En el servidor, editar `/var/www/reconocimientoFacial_asisencias/api_routes.py`

### 2. Buscar esta línea en la función `get_course_students` (~línea 3113):
```python
conn = get_db_connection()
```

### 3. Reemplazar por:
```python
conn = psycopg2.connect(**DB_CONFIG)
```

### 4. Verificar que al inicio del archivo estén estos imports:
```python
import psycopg2
from psycopg2.extras import RealDictCursor
```

### 5. Reiniciar el servicio:
```bash
sudo systemctl restart reconocimiento_service
```

---

## ✅ OPCIÓN B: Agregar Función Helper (Mejor Práctica)

### 1. En el servidor, editar `/var/www/reconocimientoFacial_asisencias/api_routes.py`

### 2. Buscar donde están definidas las constantes `DB_CONFIG` (inicio del archivo)

### 3. Justo después de `DB_CONFIG`, agregar esta función:
```python
def get_db_connection():
    """Crear conexión a la base de datos PostgreSQL"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except psycopg2.Error as e:
        print(f"❌ Error conectando a la base de datos: {e}")
        return None
```

### 4. Reiniciar el servicio:
```bash
sudo systemctl restart reconocimiento_service
```

### ✅ Ventaja: Con esta opción, el endpoint funciona tal como está.

---

## 🎯 Recomendación:

**Para salir del paso rápido → Usar OPCIÓN A**  
**Para código más limpio → Usar OPCIÓN B**

Ambas soluciones funcionan perfectamente. La diferencia es solo de estilo de código.

---

## 🧪 Probar después de aplicar:

En Flutter, al buscar estudiantes de un curso, debería cargar la lista sin errores 500.

**Log esperado en servidor:**
```
✅ Estudiantes del curso 300 obtenidos correctamente
```

**Log esperado en Flutter:**
```
Estudiantes cargados: 25
```
