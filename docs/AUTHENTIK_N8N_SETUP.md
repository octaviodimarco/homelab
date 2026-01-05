# Configuración de OAuth2/OIDC Provider para n8n en Authentik

Esta guía te ayudará a configurar el proveedor OAuth2/OIDC en Authentik para que n8n pueda autenticarse mediante SSO.

## Prerequisitos

1. Authentik debe estar funcionando y accesible en `https://authentik.dimarco-server.site`
2. Debes haber completado la configuración inicial de Authentik (usuario administrador creado)
3. n8n debe estar desplegado y accesible en `https://n8n.dimarco-server.site`

## Paso 1: Crear el OAuth2/OpenID Provider (Genérico y Reutilizable)

1. **Accede a Authentik**: `https://authentik.dimarco-server.site`
2. **Navega a**: `Applications` → `Providers` (en el menú lateral)
3. **Haz clic en**: `Create` → `OAuth2/OpenID Provider`

4. **Completa el formulario con los siguientes valores**:

   - **Name**: `OAuth2 Provider` o `Homelab OIDC Provider` (nombre genérico para reutilizar)
   - **Authorization flow**: Selecciona `Explicit` (Authorization Code Flow - más seguro)
   - **Client type**: `Confidential` (importante para seguridad)
   - **Redirect URIs**: 
     ```
     https://n8n.dimarco-server.site/rest/login
     ```
     ⚠️ **Nota**: Puedes agregar múltiples Redirect URIs aquí si planeas usar este provider para otras aplicaciones. Por ahora, agrega solo el de n8n.
   
   - **Scopes**: Selecciona o agrega:
     - `openid` (requerido)
     - `profile` (recomendado)
     - `email` (recomendado)
   
   - **Sub mode**: `user_username` (o `user_email` si prefieres usar email como identificador)
   
   - **Property mappings** (opcional pero recomendado):
     - **User property mappings**: Selecciona mappings que incluyan `email`, `name`, `username`
     - **Scope mappings**: Asegúrate de que `profile` y `email` tengan mappings apropiados

5. **Haz clic en**: `Create`

6. **Copia los valores generados**:
   - **Client ID**: Se muestra después de crear el provider
   - **Client Secret**: Se muestra una sola vez, cópialo inmediatamente
   
   ⚠️ **IMPORTANTE**: Guarda estos valores de forma segura. Los necesitarás para Infisical.
   
   💡 **Nota**: Este provider puede ser reutilizado para otras aplicaciones (Grafana, Jellyfin, etc.) agregando sus Redirect URIs a la lista.

## Paso 2: Crear la Application en Authentik

1. **Navega a**: `Applications` → `Applications` (en el menú lateral)
2. **Haz clic en**: `Create`

3. **Completa el formulario**:

   - **Name**: `n8n`
   - **Slug**: `n8n` ⚠️ **CRÍTICO**: Este slug debe ser exactamente `n8n` porque las URLs de n8n lo usan
   - **Provider**: Selecciona el provider genérico que acabas de crear (ej: `OAuth2 Provider` o `Homelab OIDC Provider`)
   - **Launch URL**: `https://n8n.dimarco-server.site`
   - **Meta launch URL** (opcional): `https://n8n.dimarco-server.site`
   - **Meta icon** (opcional): Puedes subir un icono para n8n
   - **Meta description** (opcional): Descripción de la aplicación

4. **Haz clic en**: `Create`
   
   💡 **Nota**: El slug de la Application (`n8n`) es lo que se usa en las URLs OIDC, no el nombre del Provider. Puedes crear múltiples Applications (n8n, Grafana, etc.) que usen el mismo Provider genérico.

## Paso 3: Configurar Acceso de Usuarios

1. **En la página de la Application** que acabas de crear, ve a la pestaña `Access`
2. **Asigna usuarios o grupos** que pueden acceder a n8n:
   - Puedes asignar usuarios individuales
   - O grupos de usuarios (recomendado para gestión más fácil)

## Paso 4: Guardar Credenciales en Infisical

1. **Accede a Infisical** y navega a tu proyecto
2. **Crea los siguientes secretos**:

   - **Ruta**: `/authentik/n8n/client_id`
     - **Valor**: El Client ID que copiaste del provider
   
   - **Ruta**: `/authentik/n8n/client_secret`
     - **Valor**: El Client Secret que copiaste del provider

3. **Verifica** que los secretos estén en el entorno correcto (`dev` según tu configuración)

## Paso 5: Verificar URLs del Provider

Las URLs que n8n usará se generan automáticamente basándose en el slug de la aplicación. Deben ser:

- **Issuer**: `https://authentik.dimarco-server.site/application/o/n8n/`
- **Authorization URL**: `https://authentik.dimarco-server.site/application/o/n8n/authorize/`
- **Token URL**: `https://authentik.dimarco-server.site/application/o/n8n/token/`
- **User Info URL**: `https://authentik.dimarco-server.site/application/o/n8n/userinfo/`

⚠️ **Nota**: Estas URLs ya están configuradas en el ConfigMap de n8n. Solo necesitas asegurarte de que el slug de la aplicación sea exactamente `n8n`.

## Paso 6: Verificar la Configuración

1. **Verifica que External Secrets sincronice los nuevos secretos**:
   ```bash
   kubectl get externalsecret n8n-container-env -n n8n
   kubectl get secret n8n-container-env -n n8n
   ```

2. **Verifica que los secretos contengan los valores**:
   ```bash
   kubectl get secret n8n-container-env -n n8n -o jsonpath='{.data.N8N_OIDC_CLIENT_ID}' | base64 -d && echo
   kubectl get secret n8n-container-env -n n8n -o jsonpath='{.data.N8N_OIDC_CLIENT_SECRET}' | base64 -d && echo
   ```

3. **Reinicia el pod de n8n** para cargar las nuevas variables de entorno:
   ```bash
   kubectl rollout restart deployment/n8n -n n8n
   ```

## Paso 7: Probar la Integración

1. **Accede a n8n**: `https://n8n.dimarco-server.site`
2. **Deberías ver**:
   - Una opción de "Sign in with OIDC" o similar
   - O ser redirigido automáticamente a Authentik para autenticarte

3. **Inicia sesión** con tus credenciales de Authentik
4. **Deberías ser redirigido** de vuelta a n8n autenticado

## Troubleshooting

### n8n no muestra la opción de OIDC

- Verifica que `N8N_AUTHENTICATION_METHOD=oidc` esté en el ConfigMap
- Revisa los logs de n8n: `kubectl logs -n n8n deployment/n8n`
- Verifica que los secretos estén sincronizados

### Error de redirección

- Asegúrate de que la Redirect URI en Authentik sea exactamente: `https://n8n.dimarco-server.site/rest/login`
- Verifica que el slug de la aplicación sea exactamente `n8n` (sin mayúsculas, sin espacios)

### Error de autenticación

- Verifica que el Client ID y Client Secret en Infisical coincidan con los de Authentik
- Revisa los logs de Authentik para ver errores de autenticación
- Verifica que el usuario tenga acceso a la aplicación en Authentik

### URLs incorrectas

- El slug de la aplicación DEBE ser `n8n` (minúsculas)
- Las URLs se generan automáticamente como: `https://authentik.dimarco-server.site/application/o/{slug}/...`

## Notas Adicionales

- El Client Secret solo se muestra una vez. Si lo pierdes, necesitarás regenerarlo en Authentik
- Puedes regenerar el Client Secret desde la página del Provider en Authentik
- Los cambios en Authentik son inmediatos, pero n8n puede necesitar reiniciarse para cargar nuevos secretos

