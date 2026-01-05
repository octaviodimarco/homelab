# Secretos Requeridos en Infisical para Authentik

Este documento lista todos los secretos que debes crear en Infisical antes de desplegar Authentik.

## Secretos para Authentik (Inmediatos - Antes del Despliegue)

### 1. Secret Key de Authentik
- **Ruta**: `/authentik/secret_key`
- **Tipo**: String
- **Valor**: Clave secreta de 50 caracteres (mínimo)
- **Cómo generarlo**:
  ```bash
  # Opción 1: Usando OpenSSL
  openssl rand -base64 50 | tr -d '\n' | head -c 50
  
  # Opción 2: Usando Python
  python3 -c "import secrets; print(secrets.token_urlsafe(50)[:50])"
  
  # Opción 3: Usando /dev/urandom
  head -c 50 /dev/urandom | base64 | tr -d '\n' | head -c 50
  ```
- **Importante**: Debe ser una cadena de al menos 50 caracteres. Guárdalo de forma segura, es crítico para el funcionamiento de Authentik.

### 2. Usuario de PostgreSQL
- **Ruta**: `/authentik/postgres_user`
- **Tipo**: String
- **Valor**: Nombre de usuario para la base de datos PostgreSQL (ej: `authentik`)
- **Ejemplo**: `authentik`

### 3. Contraseña de PostgreSQL
- **Ruta**: `/authentik/postgres_password`
- **Tipo**: String
- **Valor**: Contraseña segura para el usuario de PostgreSQL
- **Cómo generarlo**:
  ```bash
  # Opción 1: Usando OpenSSL
  openssl rand -base64 32
  
  # Opción 2: Usando Python
  python3 -c "import secrets; print(secrets.token_urlsafe(32))"
  ```
- **Recomendación**: Mínimo 32 caracteres, alfanuméricos con símbolos

## Secretos para n8n OIDC (Después de Configurar Authentik)

Estos secretos se obtienen **después** de configurar el OAuth2/OIDC Provider en Authentik. No los necesitas para el despliegue inicial.

### 4. Client ID de n8n
- **Ruta**: `/authentik/n8n/client_id`
- **Tipo**: String
- **Valor**: Se obtiene al crear el OAuth2/OpenID Provider en Authentik
- **Cuándo crearlo**: Después de acceder a Authentik y crear el provider para n8n

### 5. Client Secret de n8n
- **Ruta**: `/authentik/n8n/client_secret`
- **Tipo**: String
- **Valor**: Se obtiene al crear el OAuth2/OpenID Provider en Authentik
- **Cuándo crearlo**: Después de acceder a Authentik y crear el provider para n8n

## Resumen de Rutas en Infisical

```
/authentik/
  ├── secret_key              (REQUERIDO - Antes del despliegue)
  ├── postgres_user           (REQUERIDO - Antes del despliegue)
  ├── postgres_password       (REQUERIDO - Antes del despliegue)
  └── n8n/
      ├── client_id           (OPCIONAL - Después de configurar Authentik)
      └── client_secret       (OPCIONAL - Después de configurar Authentik)
```

## Orden de Configuración

1. **Antes del despliegue** (requeridos):
   - ✅ `/authentik/secret_key`
   - ✅ `/authentik/postgres_user`
   - ✅ `/authentik/postgres_password`

2. **Después del despliegue inicial** (para habilitar OIDC en n8n):
   - ⏳ `/authentik/n8n/client_id` - Obtener de Authentik después de crear el provider
   - ⏳ `/authentik/n8n/client_secret` - Obtener de Authentik después de crear el provider

## Verificación

Después de crear los secretos en Infisical, puedes verificar que External Secrets los sincronice correctamente:

```bash
# Verificar el secret de Authentik
kubectl get secret -n authentik authentik-secrets

# Verificar el secret de la base de datos
kubectl get secret -n authentik authentik-db-credentials

# Verificar el secret de n8n (después de configurar OIDC)
kubectl get secret -n n8n n8n-container-env
```

## Notas Importantes

- **Secret Key**: Si pierdes o cambias el `secret_key` después del despliegue inicial, Authentik no podrá descifrar datos existentes. Guárdalo de forma segura.
- **PostgreSQL**: El usuario y contraseña deben coincidir con los que se configuran en la base de datos PostgreSQL del cluster `data`.
- **Client ID/Secret**: Estos se generan automáticamente en Authentik cuando creas el OAuth2 Provider. No los generes manualmente.

