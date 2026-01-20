# Solución al ApiException: 7 en Google Sign-In

## Diagnóstico
El error `ApiException: 7 (NETWORK_ERROR)` persiste a pesar de tener configurado:
- ✅ SHA-1 fingerprint registrado en Firebase
- ✅ OAuth Web Client ID configurado en `serverClientId`
- ✅ google-services.json actualizado con ambos client types (1 y 3)

## Causa Raíz
El problema es que **falta configurar la pantalla de consentimiento OAuth** en Google Cloud Console, o el OAuth Web Client no está habilitado correctamente.

## Solución Paso a Paso

### Opción 1: Configurar OAuth Consent Screen (RECOMENDADO)

1. **Ir a Google Cloud Console**
   - https://console.cloud.google.com/
   - Seleccionar el proyecto: `asistenciaguard-uceva` (ID: 827103064094)

2. **Configurar OAuth Consent Screen**
   - En el menú lateral: **APIs & Services > OAuth consent screen**
   - Si no está configurado, clic en **CONFIGURE CONSENT SCREEN**
   - Seleccionar **External** (o Internal si tienes Google Workspace)
   - Clic en **CREATE**

3. **Completar información básica**
   ```
   App name: Asistencia Guard UCEVA
   User support email: [tu correo @uceva.edu.co]
   Developer contact: [tu correo]
   ```
   - Clic en **SAVE AND CONTINUE**

4. **Scopes (alcances)**
   - Clic en **ADD OR REMOVE SCOPES**
   - Agregar:
     - `.../auth/userinfo.email`
     - `.../auth/userinfo.profile`
   - Clic en **UPDATE** → **SAVE AND CONTINUE**

5. **Test users (usuarios de prueba)**
   - Si elegiste External, agregar emails de prueba:
     - Clic en **ADD USERS**
     - Agregar todos los correos @uceva.edu.co que necesites probar
   - Clic en **SAVE AND CONTINUE**

6. **Publicar la app**
   - En la pantalla de resumen, clic en **BACK TO DASHBOARD**
   - Clic en **PUBLISH APP** (para que cualquier @uceva.edu.co pueda usarla)

### Opción 2: Verificar OAuth Web Client

1. **Ir a Credentials**
   - https://console.cloud.google.com/apis/credentials
   - Proyecto: `asistenciaguard-uceva`

2. **Verificar Web Client**
   - Buscar el cliente: `827103064094-pd3fuh7ip54ump5lj19uq1gnb093d9qs`
   - Debe ser tipo **"Web application"**
   - **Authorized redirect URIs** debe incluir:
     ```
     https://asistenciaguard-uceva.firebaseapp.com/__/auth/handler
     ```

3. **Si no existe, crear nuevo OAuth Web Client**
   - Clic en **+ CREATE CREDENTIALS > OAuth 2.0 Client ID**
   - Application type: **Web application**
   - Name: `Web client (auto created by Google Service)`
   - Authorized redirect URIs:
     ```
     https://asistenciaguard-uceva.firebaseapp.com/__/auth/handler
     ```
   - Clic en **CREATE**
   - **IMPORTANTE**: Copiar el nuevo Client ID y actualizar en auth_service.dart

### Opción 3: Solución Alternativa (Sin serverClientId)

Si las opciones anteriores no funcionan, puedes eliminar `serverClientId` y usar solo autenticación básica:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  // Removido serverClientId para autenticación básica
);
```

**Ventajas**: Login funcionará sin problemas de OAuth
**Desventajas**: No podrás obtener ID tokens para verificación backend robusta

## Verificación Final

Después de aplicar la solución:

1. Desinstalar app del dispositivo:
   ```bash
   adb uninstall com.uceva.asistencia_guard
   ```

2. Limpiar y reconstruir:
   ```bash
   flutter clean
   flutter run
   ```

3. Probar login con cuenta @uceva.edu.co

## Logs Esperados

Si funciona correctamente, deberías ver:
```
I/flutter: 🔷 INICIO: signInWithGoogle()
I/flutter: 🔷 Llamando a _googleSignIn.signIn()...
I/flutter: ✅ Google Sign-In exitoso: tu.correo@uceva.edu.co
I/flutter: ✅ Es correo institucional válido
I/flutter: 🔷 Verificando docente en base de datos...
I/flutter: ✅✅✅ LOGIN EXITOSO: [nombre del docente]
```

## Referencias
- [Google Sign-In Plugin](https://pub.dev/packages/google_sign_in)
- [OAuth Consent Screen Setup](https://support.google.com/cloud/answer/10311615)
- [ApiException Codes](https://developers.google.com/android/reference/com/google/android/gms/common/api/CommonStatusCodes)
