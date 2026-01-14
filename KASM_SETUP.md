# Configuración de Kasm Workspaces

## Secrets a crear en Infisical

### Base de Datos PostgreSQL

Crea los siguientes secrets en Infisical bajo el path `/databases/kasm/`:

- **`KASM_DB_USERNAME`**: Usuario de PostgreSQL para Kasm (ej: `kasm`)
- **`KASM_DB_PASSWORD`**: Contraseña del usuario de PostgreSQL

#### Generar contraseña de PostgreSQL

```bash
# Opción 1: Usando openssl (32 caracteres, alfanuméricos + símbolos)
openssl rand -base64 24 | tr -d "=+/" | cut -c1-32

# Opción 2: Usando openssl (32 caracteres, solo alfanuméricos)
openssl rand -hex 16

# Opción 3: Usando /dev/urandom (32 caracteres, alfanuméricos + símbolos)
cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()_+-=' | fold -w 32 | head -n 1

# Opción 4: Si tienes pwgen instalado (32 caracteres, alfanuméricos + símbolos)
pwgen -s 32 1

# Opción 5: Contraseña más segura (40 caracteres, alfanuméricos + símbolos)
openssl rand -base64 30 | tr -d "=+/" | cut -c1-40
```

**Recomendación**: Usa la **Opción 1** o **Opción 5** para PostgreSQL (32-40 caracteres con símbolos).

### Redis Externo (LXC)

Crea los siguientes secrets en Infisical bajo el path `/kasm/redis/`:

- **`REDIS_HOST`**: IP o hostname del LXC donde corre Redis (ej: `192.168.1.100` o `redis.lxc.local`)
- **`REDIS_PORT`**: Puerto de Redis (típicamente `6379`)
- **`REDIS_PASSWORD`**: Contraseña de Redis (dejar vacío si no tiene password)

#### Generar contraseña de Redis

```bash
# Opción 1: Usando openssl (24 caracteres, alfanuméricos + símbolos)
openssl rand -base64 18 | tr -d "=+/" | cut -c1-24

# Opción 2: Usando openssl (24 caracteres, solo alfanuméricos)
openssl rand -hex 12

# Opción 3: Usando /dev/urandom (24 caracteres, alfanuméricos + símbolos)
cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()_+-=' | fold -w 24 | head -n 1

# Opción 4: Si tienes pwgen instalado (24 caracteres, alfanuméricos + símbolos)
pwgen -s 24 1

# Opción 5: Contraseña más simple para Redis (16 caracteres, alfanuméricos)
openssl rand -hex 8
```

**Recomendación**: Usa la **Opción 1** o **Opción 2** para Redis (24 caracteres).

#### Nota sobre Redis sin password

Si Redis no tiene password configurado, deja el campo `REDIS_PASSWORD` vacío en Infisical.

### Comandos rápidos para generar y copiar

```bash
# PostgreSQL - Generar y copiar al portapapeles (macOS)
echo "KASM_DB_USERNAME=kasm"
echo "KASM_DB_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)" | pbcopy
echo "Contraseña copiada al portapapeles"

# PostgreSQL - Generar y mostrar (Linux)
echo "KASM_DB_USERNAME=kasm"
echo "KASM_DB_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)"
# Para copiar en Linux: echo "PASSWORD" | xclip -selection clipboard

# Redis - Generar y copiar al portapapeles (macOS)
echo "REDIS_HOST=TU_IP_LXC"
echo "REDIS_PORT=6379"
echo "REDIS_PASSWORD=$(openssl rand -base64 18 | tr -d "=+/" | cut -c1-24)" | pbcopy
echo "Contraseña copiada al portapapeles"

# Redis - Generar y mostrar (Linux)
echo "REDIS_HOST=TU_IP_LXC"
echo "REDIS_PORT=6379"
echo "REDIS_PASSWORD=$(openssl rand -base64 18 | tr -d "=+/" | cut -c1-24)"
```

## Estructura en Infisical

```
/databases/kasm/
  ├── KASM_DB_USERNAME
  └── KASM_DB_PASSWORD

/kasm/redis/
  ├── REDIS_HOST
  ├── REDIS_PORT
  └── REDIS_PASSWORD
```

## Comandos de Verificación

### 1. Verificar que Flux detectó los cambios

```bash
# Verificar el estado del HelmRepository
kubectl get helmrepository -n flux-system kasm

# Verificar el estado del HelmRelease
kubectl get helmrelease -n kasm kasm

# Ver logs del HelmRelease
flux logs helmrelease -n kasm kasm --tail=50
```

### 2. Verificar ExternalSecrets

```bash
# Verificar que los ExternalSecrets se crearon
kubectl get externalsecret -n kasm

# Verificar el estado de los ExternalSecrets
kubectl describe externalsecret -n kasm kasm-redis-credentials
kubectl describe externalsecret -n kasm kasm-db-credentials
kubectl describe externalsecret -n kasm kasm-helm-values

# Verificar que los Secrets se generaron
kubectl get secrets -n kasm
```

### 3. Verificar la Base de Datos

```bash
# Verificar el cluster de PostgreSQL
kubectl get cluster -n kasm kasm-db

# Verificar los pods de la base de datos
kubectl get pods -n kasm -l cnpg.io/cluster=kasm-db

# Verificar el servicio LoadBalancer
kubectl get svc -n kasm kasm-db-lb
```

### 4. Verificar el despliegue de Kasm

```bash
# Ver todos los recursos en el namespace kasm
kubectl get all -n kasm

# Ver los pods de Kasm
kubectl get pods -n kasm

# Ver logs de los pods de Kasm
kubectl logs -n kasm -l app=kasm --tail=50

# Verificar el Ingress
kubectl get ingress -n kasm
```

### 5. Verificar valores del HelmRelease

```bash
# Ver los valores combinados del HelmRelease
kubectl get helmrelease -n kasm kasm -o yaml

# Ver el ConfigMap de valores
kubectl get configmap -n kasm kasm-values -o yaml

# Ver el Secret de valores (valores sensibles)
kubectl get secret -n kasm kasm-helm-values -o jsonpath='{.data.values\.yaml}' | base64 -d
```

### 6. Verificar conectividad a Redis

```bash
# Obtener el host de Redis desde el secret
kubectl get secret -n kasm kasm-redis-credentials -o jsonpath='{.data.host}' | base64 -d
echo ""

# Obtener el puerto de Redis
kubectl get secret -n kasm kasm-redis-credentials -o jsonpath='{.data.port}' | base64 -d
echo ""

# Probar conectividad desde un pod temporal
kubectl run redis-test --image=redis:alpine --rm -it --restart=Never -n kasm -- redis-cli -h $(kubectl get secret -n kasm kasm-redis-credentials -o jsonpath='{.data.host}' | base64 -d) -p $(kubectl get secret -n kasm kasm-redis-credentials -o jsonpath='{.data.port}' | base64 -d) ping
```

### 7. Verificar conectividad a PostgreSQL

```bash
# Verificar que el servicio de PostgreSQL es accesible
kubectl get svc -n kasm kasm-db-lb

# Probar conexión desde un pod temporal
kubectl run postgres-test --image=postgres:alpine --rm -it --restart=Never -n kasm -- env PGHOST=pg-kasm.data.dimarco-server.site PGPORT=5432 PGDATABASE=kasm PGUSER=$(kubectl get secret -n kasm kasm-db-credentials -o jsonpath='{.data.username}' | base64 -d) PGPASSWORD=$(kubectl get secret -n kasm kasm-db-credentials -o jsonpath='{.data.password}' | base64 -d) psql -c "SELECT version();"
```

## Comandos de Debugging

### Ver eventos del namespace

```bash
kubectl get events -n kasm --sort-by='.lastTimestamp'
```

### Ver logs de Flux

```bash
# Logs del Helm Controller
kubectl logs -n flux-system -l app=helm-controller --tail=100

# Logs del Kustomize Controller
kubectl logs -n flux-system -l app=kustomize-controller --tail=100

# Logs del Source Controller
kubectl logs -n flux-system -l app=source-controller --tail=100
```

### Forzar reconciliación

```bash
# Forzar reconciliación del HelmRelease
flux reconcile helmrelease -n kasm kasm

# Forzar reconciliación del HelmRepository
flux reconcile helmrepository -n flux-system kasm

# Forzar reconciliación de los ExternalSecrets
kubectl annotate externalsecret -n kasm kasm-redis-credentials force-sync=$(date +%s) --overwrite
kubectl annotate externalsecret -n kasm kasm-db-credentials force-sync=$(date +%s) --overwrite
kubectl annotate externalsecret -n kasm kasm-helm-values force-sync=$(date +%s) --overwrite
```

### Verificar el estado completo

```bash
# Estado completo del HelmRelease
flux get helmrelease -n kasm kasm

# Estado de todos los recursos de Kasm
kubectl get all,ingress,secret,configmap,externalsecret -n kasm
```

## Acceso a Kasm

Una vez desplegado, accede a Kasm en:
- **URL**: `https://kasm.dimarco-server.site`

### Credenciales por defecto

Las credenciales por defecto de Kasm se generan automáticamente. Para obtenerlas:

```bash
# Obtener contraseña del admin
kubectl get secret -n kasm kasm-secrets -o jsonpath='{.data.admin-password}' | base64 -d
echo ""

# Usuario admin: admin@kasm.local

# Obtener contraseña del usuario
kubectl get secret -n kasm kasm-secrets -o jsonpath='{.data.user-password}' | base64 -d
echo ""

# Usuario: user@kasm.local
```

## Notas Importantes

1. **HelmRepository URL**: Verifica que `https://helm.kasmweb.com` sea la URL correcta del repositorio oficial. Si no funciona, puede que necesites usar el repositorio de GitHub o un OCI registry.

2. **Versión del Chart**: La versión `1.15.0` puede no existir. Verifica la versión correcta con:
   ```bash
   helm search repo kasm/kasm --versions
   ```

3. **Redis sin password**: Si Redis no tiene password, deja `REDIS_PASSWORD` vacío en Infisical.

4. **Storage**: Asegúrate de que el StorageClass `nfs-csi` existe y está funcionando.

5. **DNS**: Verifica que el dominio `kasm.dimarco-server.site` apunta al LoadBalancer de nginx.

