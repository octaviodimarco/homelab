# Configuración de oauth2-proxy para Jellyfin con Pocket ID

Esta guía explica cómo configurar oauth2-proxy para proteger Jellyfin con autenticación OIDC usando Pocket ID, mientras se permite el acceso directo para clientes nativos (Apple TV, móviles, etc.).

## Arquitectura

```
Internet → Ingress → oauth2-proxy → Jellyfin
```

- **Acceso Web**: Los usuarios son redirigidos a Pocket ID para autenticarse antes de acceder a Jellyfin.
- **Clientes Nativos**: Los clientes nativos (Apple TV, móviles) pueden acceder directamente a Jellyfin sin autenticación OAuth, usando los paths configurados en `skipAuthRegex`.

## Secretos Requeridos en Infisical

Crea los siguientes secretos en Infisical:

### 1. Credenciales de Pocket ID para Jellyfin

**Path:** `/pocket-id/jellyfin/`

- `client_id`: ID de cliente de la aplicación en Pocket ID
- `client_secret`: Secreto de cliente de la aplicación en Pocket ID
- `oidc_issuer_url`: URL del issuer OIDC de Pocket ID (ej: `https://auth.tu-dominio.com`)

### 2. Cookie Secret de oauth2-proxy

**Path:** `/oauth2-proxy/jellyfin/`

- `cookie_secret`: Secret aleatorio para firmar las cookies (genera uno con `openssl rand -base64 32`)

## Configuración en Pocket ID

### Paso 1: Crear una Aplicación

1. Accede a tu instancia de Pocket ID
2. Crea una nueva aplicación OIDC
3. Configura la aplicación:
   - **Name**: `Jellyfin` (o el nombre que prefieras)
   - **Redirect URI**: 
     ```
     https://jellyfin.dimarco-server.site/oauth2/callback
     ```
   - **Scopes**: `openid`, `email`, `profile`
4. Guarda la aplicación y **copia el Client ID, Client Secret y OIDC Issuer URL**

### Paso 2: Asignar Usuarios/Grupos

Asigna los usuarios o grupos que deben tener acceso a Jellyfin según la configuración de tu instancia de Pocket ID.

## Agregar Secretos a Infisical

1. Agrega `client_id`, `client_secret` y `oidc_issuer_url` de Pocket ID en `/pocket-id/jellyfin/`
2. Genera y agrega `cookie_secret` en `/oauth2-proxy/jellyfin/`:
   ```bash
   openssl rand -base64 32
   ```

## Paths con Bypass de Autenticación

Los siguientes paths están configurados para permitir acceso directo sin autenticación OAuth (para clientes nativos):

- `/emby/*` - Compatibilidad con clientes Emby
- `/Users/*` - Autenticación de usuarios
- `/Items/*` - Items de la biblioteca
- `/Playback/*` - Reproducción de contenido
- `/Sessions/*` - Sesiones de usuario
- `/System/*` - Información del sistema
- `/Videos/*` - Videos
- `/Audio/*` - Audio
- `/Images/*` - Imágenes
- `/web/*` - Interfaz web
- `/health` - Health check

**Nota**: Los clientes nativos (Apple TV, móviles) usan estos paths para autenticarse directamente con Jellyfin usando credenciales locales, por lo que no necesitan pasar por oauth2-proxy.

## Verificación

1. **Acceso Web**: Intenta acceder a `https://jellyfin.dimarco-server.site` desde un navegador. Deberías ser redirigido a Pocket ID para autenticarte.

2. **Cliente Nativo**: Configura Streamify o cualquier cliente nativo de Jellyfin con la URL `https://jellyfin.dimarco-server.site`. El cliente debería poder autenticarse directamente sin pasar por OAuth.

## Troubleshooting

### El botón de login no aparece en el navegador

- Verifica que oauth2-proxy esté corriendo: `kubectl get pods -n oauth2-proxy`
- Revisa los logs: `kubectl logs -n oauth2-proxy -l app.kubernetes.io/name=oauth2-proxy`
- Verifica que los secretos estén sincronizados: `kubectl get secret -n oauth2-proxy oauth2-proxy-secrets`
- Verifica que el `oidc_issuer_url` esté correctamente configurado

### El cliente nativo no puede conectarse

- Verifica que los paths estén en `skipAuthRegex` en el HelmRelease
- Revisa los logs de oauth2-proxy para ver si las peticiones están siendo bloqueadas
- Verifica que el Ingress esté apuntando correctamente a oauth2-proxy

### Error de redirección

- Verifica que el Redirect URI en Pocket ID sea exactamente: `https://jellyfin.dimarco-server.site/oauth2/callback`
- Verifica que `redirectURL` en el HelmRelease coincida con el Redirect URI en Pocket ID
- Verifica que el `oidc_issuer_url` sea correcto y accesible

### Problemas con Apple TV / Streamify

- El fix de Apple TV que estaba en el Ingress se removió porque ahora oauth2-proxy está en el medio
- Los clientes nativos deberían poder autenticarse directamente usando los paths en `skipAuthRegex`
- Si persisten problemas, considera usar Swiftfin (cliente oficial de Jellyfin para Apple TV) en lugar de Streamify
