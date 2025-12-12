# 🤖 PROMPT para Implementación de Registro de Embeddings Faciales

---

## 📋 Instrucciones para Copilot/AI

Copia y pega este prompt en tu otro proyecto frontend para que el asistente implemente la funcionalidad de registro de embeddings faciales conectándose correctamente al servidor.

---

## 🎯 PROMPT COMPLETO

```
Necesito implementar un sistema de registro de embeddings faciales para estudiantes que se conecte a mi servidor backend. La implementación debe seguir este flujo específico:

## CONFIGURACIÓN INICIAL DEL SERVIDOR

Primero, configura la conexión al servidor:
- URL base: http://192.168.100.99:5000/api
- Headers: Content-Type: application/json
- Timeout de conexión: 15 segundos
- Timeout de recepción: 60 segundos (para procesamiento de imágenes)

## ENDPOINTS DISPONIBLES

### 1. Buscar Estudiante
**Endpoint:** POST /api/search_student
**Request Body:**
```json
{
  "codigo": "1234567890"
}
```

**Response Exitoso:**
```json
{
  "success": true,
  "found": true,
  "count": 1,
  "students": [
    {
      "codigo": "1234567890",
      "nombre_completo": "Juan Pérez García",
      "nombre": "Juan",
      "apellidos": "Pérez García",
      "email_institucional": "juan.perez@uceva.edu.co",
      "email_personal": "juan@gmail.com",
      "programa": "Ingeniería de Sistemas",
      "semestre": 5,
      "movil": "3001234567",
      "telefonos": "555-1234",
      "tiene_embeddings": false,
      "num_embeddings": 0
    }
  ]
}
```

**Response No Encontrado:**
```json
{
  "success": true,
  "found": false,
  "message": "No se encontraron estudiantes con esos criterios"
}
```

### 2. Registrar Embeddings
**Endpoint:** POST /api/register_student_embeddings
**Request Body:**
```json
{
  "codigo_estudiante": "1234567890",
  "images": [
    "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  ],
  "force_update": false
}
```

**Validaciones importantes:**
- Mínimo: 3 imágenes
- Máximo: 5 imágenes
- Formato: data:image/jpeg;base64,[base64_string]
- Cada imagen debe ser máximo 800x800px, calidad 85%

**Response Exitoso:**
```json
{
  "success": true,
  "message": "Embeddings registrados correctamente (4/4)",
  "student": {
    "codigo": "1234567890",
    "nombre": "Juan",
    "apellido": "Pérez García",
    "nombre_completo": "Juan Pérez García",
    "programa": "Ingeniería de Sistemas",
    "id_usuario": 123,
    "embeddings_saved": 4,
    "embeddings_failed": 0,
    "total_images": 4
  },
  "failed_images": null
}
```

**Response con Fallos Parciales:**
```json
{
  "success": true,
  "message": "Embeddings registrados correctamente (3/4)",
  "student": {
    "codigo": "1234567890",
    "nombre": "Juan",
    "apellido": "Pérez García",
    "nombre_completo": "Juan Pérez García",
    "programa": "Ingeniería de Sistemas",
    "id_usuario": 123,
    "embeddings_saved": 3,
    "embeddings_failed": 1,
    "total_images": 4
  },
  "failed_images": [
    {
      "image_number": 2,
      "reason": "No se detectó rostro"
    }
  ]
}
```

**Response Error 409 (Ya tiene embeddings):**
```json
{
  "success": false,
  "message": "El estudiante ya tiene 3 embeddings registrados. Use force_update=true para actualizar.",
  "existing_embeddings": 3
}
```

**Response Error 404 (No existe):**
```json
{
  "success": false,
  "message": "Estudiante con código 1234567890 no encontrado en BIENESTAR"
}
```

## FLUJO DE USUARIO A IMPLEMENTAR

1. **Pantalla de Búsqueda de Estudiante:**
   - Input para ingresar código de estudiante
   - Botón "Buscar"
   - Validar que el código no esté vacío
   - Hacer POST a /api/search_student
   - Si no existe: mostrar error "Estudiante no encontrado en BIENESTAR"
   - Si existe: mostrar pantalla de confirmación

2. **Pantalla de Confirmación de Datos:**
   - Mostrar datos del estudiante:
     * Código
     * Nombre completo
     * Programa académico
     * Semestre
   - Si tiene_embeddings es true:
     * Mostrar alerta: "Ya tienes X fotos registradas"
     * Botón "Actualizar Fotos" (force_update=true)
   - Si tiene_embeddings es false:
     * Botón "Continuar"
   - Botón "Cancelar"

3. **Pantalla de Captura de Fotos:**
   - Grid de 2x2 con 4 espacios para fotos
   - Etiquetas para cada foto:
     * Foto 1: "De Frente"
     * Foto 2: "Lado Izquierdo"
     * Foto 3: "Lado Derecho"
     * Foto 4: "Sonriendo"
   - Al hacer clic en cada espacio: abrir cámara frontal
   - Configuración de cámara:
     * Resolución máxima: 800x800
     * Calidad: 85%
     * Cámara frontal preferida
   - Mostrar preview de cada foto capturada
   - Permitir recapturar cualquier foto
   - Botón "Guardar Fotos" (activo solo si hay mínimo 3 fotos)

4. **Procesamiento y Envío:**
   - Convertir cada foto a base64 con formato: data:image/jpeg;base64,[base64_string]
   - Validar que haya entre 3 y 5 fotos
   - Mostrar loading spinner con mensaje "Procesando imágenes..."
   - Hacer POST a /api/register_student_embeddings con:
     * codigo_estudiante: código del estudiante
     * images: array de strings base64
     * force_update: true si el estudiante ya tenía embeddings, false si no
   - Manejar timeout de 60 segundos

5. **Pantalla de Resultado:**
   - Si success es true:
     * Ícono de éxito ✓
     * Título: "¡Registro Exitoso!"
     * Mensaje: "Fotos guardadas: X/Y"
     * Si hay failed_images, mostrar advertencia con las fotos que fallaron
     * Botón "Finalizar" que vuelva a la pantalla inicial
   - Si success es false:
     * Ícono de error ✗
     * Mostrar el mensaje de error del servidor
     * Botón "Reintentar" o "Volver"

## MANEJO DE ERRORES REQUERIDO

1. **Error de Red (Sin conexión):**
   - Mensaje: "No se pudo conectar al servidor. Verifica tu conexión WiFi."

2. **Timeout:**
   - Mensaje: "El servidor tardó demasiado en responder. Intenta de nuevo."

3. **Estudiante no encontrado (404):**
   - Mensaje: "Estudiante no encontrado en BIENESTAR. Verifica el código."

4. **Estudiante ya tiene embeddings (409):**
   - Mostrar opción para actualizar con force_update=true

5. **Error en procesamiento de imagen:**
   - Mostrar qué imagen falló y por qué (según failed_images del response)

6. **Número de imágenes inválido:**
   - Mensaje: "Debes capturar entre 3 y 5 fotos"

## REQUISITOS TÉCNICOS

- Usar cámara frontal para las selfies
- Comprimir imágenes a máximo 800x800px antes de enviar
- Calidad de compresión: 85%
- Validar que las imágenes no superen 2MB cada una
- Mostrar indicadores de carga durante llamadas al servidor
- Implementar reintentos automáticos en caso de timeout (máximo 2 reintentos)
- Guardar logs de errores para debugging

## COMPONENTES UI NECESARIOS

1. TextField para código de estudiante (solo números)
2. Botón de búsqueda
3. Card de confirmación de datos
4. Grid 2x2 para captura de fotos
5. Indicador de loading (spinner)
6. Dialog de éxito/error
7. Botón flotante o botón primario para acceder a la funcionalidad

## NAVEGACIÓN

Desde la pantalla principal, debe haber un botón visible (puede ser un FloatingActionButton o un botón en el menú) con el texto "Registrar Estudiante" o "Registrar Rostro" que inicie este flujo.

## IMPORTANTE - ORDEN DE IMPLEMENTACIÓN

1. PRIMERO: Configurar la conexión al servidor con las URLs correctas
2. SEGUNDO: Probar el endpoint /api/search_student con un código real
3. TERCERO: Implementar la UI de búsqueda y confirmación
4. CUARTO: Implementar captura de fotos con compresión
5. QUINTO: Implementar envío a /api/register_student_embeddings
6. SEXTO: Implementar manejo de errores y pantallas de resultado

## TESTING

Antes de considerar completa la implementación, probar:
- [ ] Buscar estudiante existente
- [ ] Buscar estudiante inexistente
- [ ] Capturar 3 fotos y registrar
- [ ] Capturar 4 fotos y registrar
- [ ] Intentar con menos de 3 fotos (debe dar error)
- [ ] Registrar estudiante que ya tiene embeddings
- [ ] Actualizar embeddings con force_update=true
- [ ] Probar sin conexión a internet
- [ ] Probar con timeout del servidor

Por favor, implementa esta funcionalidad siguiendo exactamente este flujo y respetando los formatos de request/response del servidor.
```

---

## 📝 Notas Adicionales

Este prompt contiene:
- ✅ Configuración completa del servidor
- ✅ Especificación exacta de endpoints y formatos
- ✅ Flujo de usuario detallado paso a paso
- ✅ Manejo completo de errores
- ✅ Requisitos técnicos específicos
- ✅ Orden de implementación recomendado
- ✅ Checklist de testing

El asistente de IA tendrá toda la información necesaria para implementar la funcionalidad correctamente sin necesidad de preguntar por detalles adicionales.

---

**Fecha de creación:** 10 de Diciembre de 2025  
**Versión del API:** 2.1.0
