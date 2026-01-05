# Configuración de Authentik

Este documento describe cómo configurar Authentik y la integración con n8n después del despliegue inicial.

## Prerequisitos

1. Authentik debe estar desplegado y accesible en `https://authentik.dimarco-server.site`
2. La base de datos PostgreSQL debe estar creada y accesible
3. Los secretos deben estar configurados en Infisical:
   - `/authentik/secret_key` - Clave secreta de 50 caracteres
   - `/authentik/postgres_user` - Usuario de PostgreSQL
   - `/authentik/postgres_password` - Contraseña de PostgreSQL
   - `/authentik/n8n/client_id` - Client ID de OAuth2 para n8n
   - `/authentik/n8n/client_secret` - Client Secret de OAuth2 para n8n

## Configuración Inicial de Authentik

1. Accede a Authentik: `https://authentik.dimarco-server.site/if/flow/initial-setup/`
2. Crea el usuario administrador inicial (`akadmin`)
3. Configura el dominio y otras opciones básicas

## Configurar OAuth2/OIDC Provider para n8n

### En Authentik:

1. Ve a **Applications > Providers**
2. Crea un nuevo **OAuth2/OpenID Provider**:
   - **Name**: `n8n`
   - **Client type**: `Confidential`
   - **Redirect URIs**: `https://n8n.dimarco-server.site/rest/login`
   - **Scopes**: `openid`, `profile`, `email`
   - **Sub mode**: `user_username`
3. Guarda el **Client ID** y **Client Secret** en Infisical:
   - `/authentik/n8n/client_id`
   - `/authentik/n8n/client_secret`

4. Ve a **Applications > Applications**
5. Crea una nueva **Application**:
   - **Name**: `n8n`
   - **Slug**: `n8n`
   - **Provider**: Selecciona el provider `n8n` creado anteriormente
   - **Launch URL**: `https://n8n.dimarco-server.site`

## Configuración de n8n

n8n está configurado para usar OIDC con las siguientes variables de entorno:

- `N8N_AUTHENTICATION_METHOD=oidc`
- `N8N_OIDC_ISSUER` - URL del issuer de Authentik
- `N8N_OIDC_AUTHORIZATION_URL` - URL de autorización
- `N8N_OIDC_TOKEN_URL` - URL del token
- `N8N_OIDC_USER_INFO_URL` - URL de información del usuario
- `N8N_OIDC_CLIENT_ID` - Desde Infisical
- `N8N_OIDC_CLIENT_SECRET` - Desde Infisical

**Nota**: Si n8n no soporta OIDC en tu versión, puedes usar SAML en su lugar. Consulta la documentación de n8n para la configuración SAML.

## Verificación

1. Reinicia el pod de n8n para cargar las nuevas variables de entorno
2. Accede a `https://n8n.dimarco-server.site`
3. Deberías ver la opción de "Sign in with OIDC" o ser redirigido automáticamente a Authentik

## Troubleshooting

- Si n8n no muestra la opción de OIDC, verifica que las variables de entorno estén correctamente configuradas
- Revisa los logs de n8n: `kubectl logs -n n8n deployment/n8n`
- Verifica que los secretos estén sincronizados: `kubectl get secret -n n8n n8n-container-env`
- Asegúrate de que las URLs de redirección en Authentik coincidan exactamente con la URL de n8n

