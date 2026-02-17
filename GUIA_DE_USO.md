# 📋 GUÍA DE USO - Sistema de Registro de Embeddings

Bienvenido a tu aplicación de **Registro de Embeddings Faciales**. Esta guía te ayudará a entender y usar el sistema correctamente.

---

## 🚀 Inicio Rápido

### 1. Asegúrate de que el servidor está corriendo
```
http://192.168.100.99:5000
```

Debe tener los siguientes endpoints implementados:
- `POST /api/search_student` - Buscar estudiante
- `POST /api/register_student_embeddings` - Registrar fotos

### 2. Ejecuta la aplicación
```bash
cd c:\FlutterProyecto\mi_app
flutter run
```

### 3. Navega al módulo de registro
En la app, selecciona la pestaña **"Registrar"** en el BottomNavigationBar (segundo icono).

---

## 📱 Pasos del Proceso

### PASO 1: Búsqueda de Estudiante 🔍

**¿Qué hace?**
Busca tu información en la base de datos del servidor BIENESTAR.

**Instrucciones:**
1. Ingresa tu código de estudiante (solo números)
2. Haz clic en **"Buscar Estudiante"**
3. Espera a que el sistema busque (máximo 15 segundos)

**Posibles resultados:**
- ✅ **Encontrado**: Ve al Paso 2
- ❌ **No encontrado**: Verifica tu código y intenta de nuevo
- ⏱️ **Timeout**: Revisa tu conexión WiFi

---

### PASO 2: Confirmación de Datos ✅

**¿Qué hace?**
Muestra tu información antes de continuar con el registro.

**Información mostrada:**
- Código de estudiante
- Nombre completo
- Programa académico
- Semestre

**Acciones disponibles:**
- **[Cancelar]** - Vuelve a la búsqueda
- **[Continuar]** - Avanza al registro de fotos

**Nota especial:**
Si ya tienes fotos registradas anteriormente, verás una alerta diciendo cuántas tienes. Puedes actualizar tus fotos haciendo clic en **[Continuar]**.

---

### PASO 3: Captura de Fotos 📸

**¿Qué hace?**
Captura 4 fotos biométricas de tu cara en diferentes ángulos.

**Las 4 fotos requeridas:**

| Foto | Descripción | Tip |
|------|-------------|-----|
| 1️⃣ **De Frente** | Mira directamente a la cámara | Posición neutral |
| 2️⃣ **Lado Izquierdo** | Gira la cabeza hacia la izquierda | Ángulo de 45° |
| 3️⃣ **Lado Derecho** | Gira la cabeza hacia la derecha | Ángulo de 45° |
| 4️⃣ **Sonriendo** | Sonríe naturalmente a la cámara | Expresión amigable |

**Cómo capturar fotos:**

1. **Haz clic en el espacio de la foto** que desees capturar
2. **La cámara se abrirá automáticamente** (cámara frontal)
3. **Posiciónate correctamente** según la indicación
4. **Captura la foto** cuando estés listo
5. **Revisa la foto** - aparecerá un preview
6. **Si te gusta**: continúa con la siguiente
7. **Si no te gusta**: haz clic en **[Recapturar]**

**Requisitos de fotos:**
- ✅ Mínimo: 3 fotos
- ✅ Máximo: 5 fotos
- ✅ Tamaño máximo: 2MB cada una
- ✅ Resolución: Se comprimirá automáticamente a 800x800px

**Indicador de progreso:**
- En la parte superior ves: "Captura: X/4 fotos"
- El botón **"Guardar Fotos"** se habilita cuando tengas ≥3 fotos

---

### PASO 4: Procesamiento ⏳

**¿Qué hace?**
Procesa y envía tus fotos al servidor.

**Proceso automático:**
1. Valida que tengas 3-5 fotos
2. Comprime cada foto a máximo 800x800px
3. Convierte a formato base64
4. Envía al servidor

**Tiempo estimado:**
- Procesamiento local: 2-5 segundos
- Envío al servidor: 10-30 segundos
- **Tiempo máximo total: 60 segundos**

**Mientras se procesa:**
- Verás un spinner de carga
- Mensaje: "Procesando imágenes..."
- Espera a que termine (no cierres la app)

**Si se tarda mucho:**
- El sistema reintentar automáticamente (máximo 2 intentos)
- Si aun así falla, verás un error

---

### PASO 5: Resultado 🎉

**Posibles resultados:**

#### ✅ ÉXITO - Registro Completado
```
✅ ¡Registro Exitoso!

Embeddings registrados correctamente
Fotos guardadas: 4/4

[✓ Finalizar]
```

Esto significa:
- ✅ Todas tus fotos se registraron correctamente
- ✅ Puedes usar el sistema de reconocimiento facial
- ✅ Tu información está segura en el servidor

Haz clic en **[Finalizar]** para volver a la búsqueda y registrar otro estudiante si es necesario.

#### ❌ ERROR - Algo salió mal
```
❌ Error en el Registro

[Mensaje específico del error]

[Reintentar]  [Volver]
```

**Errores comunes y soluciones:**

| Error | Causa | Solución |
|-------|-------|----------|
| "No se pudo conectar al servidor" | Sin WiFi | Verifica conexión WiFi |
| "El servidor tardó demasiado" | Servidor lento | Intenta de nuevo |
| "Estudiante no encontrado" | Código incorrecto | Vuelve y verifica el código |
| "Ya tienes embeddings" | Ya registrado | Elige actualizar o cancelar |
| "No se detectó rostro" | Foto mala calidad | Recaptura la foto |
| "La imagen no debe exceder 2MB" | Foto demasiado grande | Recaptura la foto |

---

## ⚙️ Configuración del Sistema

### Conexión al Servidor

El sistema está configurado para conectarse a:
```
URL Base: http://192.168.100.99:5000
API Path: /api
```

**Si necesitas cambiar la URL:**
1. Abre: `lib/config/api_config.dart`
2. Modifica la línea:
   ```dart
   static const String baseUrl = 'http://192.168.100.99:5000';
   ```
3. Guarda y ejecuta: `flutter run`

### Configuración de Cámara

La app usa:
- **Cámara frontal** (preferida para selfies)
- **Resolución máxima:** 800x800px
- **Calidad:** 85% JPEG
- **Formato:** JPEG

---

## 🔒 Privacidad y Seguridad

### Tus datos
- 📸 Las fotos se envían encriptadas (HTTPS recomendado)
- 🔐 Se almacenan en el servidor backend
- 🗑️ Se puede solicitar su eliminación en cualquier momento

### Compresión de imágenes
- Las imágenes se comprimen localmente ANTES de enviar
- Máximo 800x800px a calidad 85%
- Reduce tamaño sin afectar reconocimiento facial

### Timeout
- Si se tarda más de 60 segundos, se intenta de nuevo (máximo 2 reintentos)
- Protege contra conexiones lentas

---

## 💡 Tips y Trucos

### Para mejores fotos:
1. ✅ **Iluminación**: Busca un lugar bien iluminado
2. ✅ **Fondo**: Un fondo claro o neutro es mejor
3. ✅ **Posición**: Coloca la cámara a la altura de los ojos
4. ✅ **Distancia**: Mantén la cámara a 30-50cm de la cara
5. ✅ **Expresión**: Se natural, no fuerces expresiones raras

### Para no perder tiempo:
1. ⏱️ Prepara bien cada foto antes de capturar
2. ⏱️ Si una foto es mala, recaptura inmediatamente
3. ⏱️ No cierres la app durante el proceso
4. ⏱️ Asegúrate tener WiFi estable

### Si algo falla:
1. 🔄 Reintentar (el sistema lo hace automáticamente)
2. 📱 Revisa tu conexión WiFi
3. 🖥️ Verifica que el servidor esté corriendo
4. 📝 Anota el código de error exacto
5. 🆘 Reporta el problema con el código de error

---

## 📊 Estados de la App

### Búsqueda
```
ESPERANDO INPUT → BUSCANDO → CONFIRMACIÓN o ERROR
```

### Captura
```
FOTO 1 → FOTO 2 → FOTO 3 → FOTO 4 → GUARDAR o CANCELAR
```

### Procesamiento
```
VALIDAR → COMPRIMIR → CONVERTIR BASE64 → ENVIAR → RESULTADO
```

---

## 🆘 Solución de Problemas

### "No encuentra al estudiante"
- ❓ ¿El código es correcto?
- ❓ ¿El estudiante está registrado en BIENESTAR?
- 💡 Solución: Verifica el código exacto con administración

### "Se queda cargando"
- ❓ ¿Tienes WiFi estable?
- ❓ ¿El servidor está corriendo?
- 💡 Solución: Revisa conexión, reinicia app

### "La foto no se ve"
- ❓ ¿Permitiste acceso a cámara?
- ❓ ¿Hay luz suficiente?
- 💡 Solución: Acepta permisos, mejor iluminación

### "Error al registrar"
- ❓ ¿Verificaste todos los permisos?
- ❓ ¿Tienes conexión estable?
- 💡 Solución: Revisa logs, intenta de nuevo

---

## 📞 Contacto y Soporte

Si tienes problemas:

1. **Revisa esta guía** - Probablemente está aquí
2. **Verifica tu conexión WiFi**
3. **Confirma que el servidor está corriendo**
4. **Reinicia la aplicación**
5. **Si persiste, contacta al administrador**

---

## 🎓 Preguntas Frecuentes

**P: ¿Puedo usar la cámara trasera?**
R: No, el sistema usa cámara frontal para selfies biométricas.

**P: ¿Qué hago si me equivoco de estudiante?**
R: Haz clic en [Cancelar] en cualquier momento para volver a búsqueda.

**P: ¿Puedo cambiar mis fotos después?**
R: Sí, vuelve a registrar con el mismo código y selecciona "Actualizar".

**P: ¿Cuánto tiempo tarda?**
R: 2-5 minutos si todo va bien (captura + envío).

**P: ¿Las fotos son públicas?**
R: No, se almacenan seguro en el servidor. Solo se usan para reconocimiento.

**P: ¿Qué pasa si cancelo a mitad?**
R: Las fotos se descartan y vuelves a la búsqueda. Puedes reintentar.

**P: ¿Necesito internet para capturar?**
R: La captura es local, pero necesitas internet para enviar al servidor.

---

## 📝 Resumen Rápido

```
1. Ingresa código de estudiante
2. Confirma tus datos
3. Captura 4 fotos (mínimo 3)
4. Sistema procesa y envía
5. Recibes confirmación

¡Listo! Ya estás registrado biométricamente 🎉
```

---

**Versión:** 1.0  
**Última actualización:** 11 de Diciembre de 2025  
**Estado:** Completado ✅
