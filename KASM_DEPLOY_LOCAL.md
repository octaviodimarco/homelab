# Desplegar Kasm Workspaces Localmente (sin Git)

## Pausar sincronización de Flux

Para evitar que Flux sincronice desde el repositorio remoto mientras trabajas localmente:

```bash
# Pausar el GitRepository principal
flux suspend source git flux-system -n flux-system

# Verificar que está pausado
flux get sources git -n flux-system
```

## Aplicar cambios localmente

### Opción 1: Aplicar directamente con kubectl (Recomendado)

```bash
# 1. Aplicar el HelmRepository
kubectl apply -f infrastructure/controllers/base/kasm/repository.yaml

# 2. Aplicar la base de datos
kubectl apply -k databases/data/kasm/

# 3. Aplicar la aplicación
kubectl apply -k apps/gordito/kasm/

# 4. Aplicar la integración en kustomizations principales
kubectl apply -f apps/gordito/kustomization.yaml
kubectl apply -f databases/data/kustomization.yaml
kubectl apply -f infrastructure/controllers/gordito/kustomization.yaml
```

### Opción 2: Forzar reconciliación de Kustomizations (si ya existen)

```bash
# Forzar reconciliación del Kustomization de apps
flux reconcile kustomization apps -n flux-system --with-source

# Forzar reconciliación del Kustomization de databases
flux reconcile kustomization infra-configs -n flux-system --with-source

# Forzar reconciliación del Kustomization de infrastructure
flux reconcile kustomization infra-controllers -n flux-system --with-source
```

### Opción 3: Aplicar todo de una vez

```bash
# Aplicar todo el árbol de Kasm
kubectl apply -k infrastructure/controllers/base/kasm/
kubectl apply -k infrastructure/controllers/gordito/kasm/
kubectl apply -k databases/data/kasm/
kubectl apply -k apps/base/kasm/
kubectl apply -k apps/gordito/kasm/

# Aplicar las integraciones
kubectl apply -f apps/gordito/kustomization.yaml
kubectl apply -f databases/data/kustomization.yaml
kubectl apply -f infrastructure/controllers/gordito/kustomization.yaml
```

## Verificar que se aplicaron los cambios

```bash
# Verificar HelmRepository
kubectl get helmrepository -n flux-system kasm

# Verificar ExternalSecrets
kubectl get externalsecret -n kasm

# Verificar Base de Datos
kubectl get cluster -n kasm kasm-db

# Verificar HelmRelease
kubectl get helmrelease -n kasm kasm

# Verificar que los secrets se generaron
kubectl get secrets -n kasm
```

## Forzar reconciliación de recursos específicos

```bash
# Forzar reconciliación del HelmRepository
flux reconcile source helm kasm -n flux-system

# Forzar reconciliación del HelmRelease
flux reconcile helmrelease kasm -n kasm

# Forzar reconciliación de ExternalSecrets
kubectl annotate externalsecret -n kasm kasm-redis-credentials force-sync=$(date +%s) --overwrite
kubectl annotate externalsecret -n kasm kasm-db-credentials force-sync=$(date +%s) --overwrite
kubectl annotate externalsecret -n kasm kasm-helm-values force-sync=$(date +%s) --overwrite
```

## Reanudar sincronización de Flux

Cuando termines y quieras que Flux vuelva a sincronizar desde Git:

```bash
# Reanudar el GitRepository
flux resume source git flux-system -n flux-system

# Verificar que está activo
flux get sources git -n flux-system
```

## Script completo (todo en uno)

```bash
#!/bin/bash

echo "⏸️  Pausando sincronización de Flux..."
flux suspend source git flux-system -n flux-system

echo "📦 Aplicando HelmRepository..."
kubectl apply -f infrastructure/controllers/base/kasm/repository.yaml

echo "🗄️  Aplicando Base de Datos..."
kubectl apply -k databases/data/kasm/

echo "🚀 Aplicando Aplicación..."
kubectl apply -k apps/gordito/kasm/

echo "🔗 Aplicando integraciones..."
kubectl apply -f apps/gordito/kustomization.yaml
kubectl apply -f databases/data/kustomization.yaml
kubectl apply -f infrastructure/controllers/gordito/kustomization.yaml

echo "🔄 Forzando reconciliación..."
flux reconcile source helm kasm -n flux-system
flux reconcile helmrelease kasm -n kasm

echo "✅ Verificando estado..."
kubectl get helmrepository -n flux-system kasm
kubectl get externalsecret -n kasm
kubectl get cluster -n kasm kasm-db
kubectl get helmrelease -n kasm kasm

echo "✨ Listo! Para reanudar Flux: flux resume source git flux-system -n flux-system"
```

## Notas importantes

1. **Pausar Flux**: Al pausar el GitRepository, Flux dejará de sincronizar desde el repositorio remoto. Los cambios locales se aplicarán directamente.

2. **ExternalSecrets**: Los ExternalSecrets necesitarán que los secrets existan en Infisical para poder generar los Secrets de Kubernetes.

3. **HelmRepository**: El HelmRepository necesita conectarse a la URL del chart. Verifica que `https://helm.kasmweb.com` sea accesible.

4. **Orden de aplicación**: Es importante aplicar primero el HelmRepository, luego la base de datos, y finalmente la aplicación.

5. **Reanudar**: No olvides reanudar la sincronización de Flux cuando termines, o haz commit y push de los cambios para que se sincronicen automáticamente.

