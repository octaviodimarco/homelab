# Comandos para Probar el Fix de EnableLegacyAuthorization

## Opción 1: GitOps (Recomendado)

Si usas Flux CD, simplemente haz commit y push:

```bash
git add apps/base/jellyfin/deployment.yaml
git commit -m "fix(jellyfin): enable legacy authorization for Apple TV compatibility"
git push
```

Flux aplicará los cambios automáticamente.

## Opción 2: Aplicar Manualmente

```bash
# Aplicar el deployment
kubectl apply -f apps/base/jellyfin/deployment.yaml

# Ver el estado del pod
kubectl get pods -n jellyfin -w

# Ver los logs del initContainer
kubectl logs -n jellyfin deployment/jellyfin -c enable-legacy-auth

# Si el pod ya estaba corriendo, hacer restart para forzar el initContainer
kubectl rollout restart deployment/jellyfin -n jellyfin

# Ver los logs después del restart
kubectl logs -n jellyfin deployment/jellyfin -c enable-legacy-auth
```

## Verificar que Funcionó

1. **Ver logs del initContainer**:
   ```bash
   kubectl logs -n jellyfin deployment/jellyfin -c enable-legacy-auth
   ```
   
   Deberías ver: `SUCCESS: EnableLegacyAuthorization is set to true`

2. **Verificar el archivo dentro del pod**:
   ```bash
   kubectl exec -n jellyfin deployment/jellyfin -- grep -A 1 EnableLegacyAuthorization /config/config/system.xml
   ```
   
   Deberías ver: `<EnableLegacyAuthorization>true</EnableLegacyAuthorization>`

3. **Probar autenticación desde Apple TV**:
   - Intentar autenticarse desde Swiftfin, Infuse o Streamify
   - Ya no debería aparecer el error `request.App parameter is null`

## Si es Primera Ejecución

Si es la primera vez que Jellyfin se ejecuta y el archivo `system.xml` no existe:

1. El initContainer no hará nada (pero no fallará)
2. Jellyfin creará el archivo con valores por defecto
3. Necesitas hacer restart para que el initContainer aplique el cambio:

```bash
kubectl rollout restart deployment/jellyfin -n jellyfin
kubectl logs -n jellyfin deployment/jellyfin -c enable-legacy-auth
```

## Troubleshooting

Si el initContainer no encuentra el archivo:

```bash
# Ver qué archivos hay en el volumen de config
kubectl exec -n jellyfin deployment/jellyfin -- ls -la /config/config/

# Ver el contenido de system.xml si existe
kubectl exec -n jellyfin deployment/jellyfin -- cat /config/config/system.xml
```

