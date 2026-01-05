# Solución para Autenticación de Apple TV en Jellyfin

## Problema

Los clientes de Apple TV (Swiftfin, Infuse, Streamify) fallan al autenticarse con el error:
```
System.ArgumentNullException: Value cannot be null. (Parameter 'request.App')
```

## Solución Oficial

Según el issue [#15730](https://github.com/jellyfin/jellyfin/issues/15730), la solución es:

**Cambiar `EnableLegacyAuthorization` a `true` en el archivo `system.xml`**

Ubicación del archivo: `/config/config/system.xml` (dentro del contenedor)

### Método 1: Manual (Editar después de que Jellyfin inicie)

1. Acceder al contenedor:
   ```bash
   kubectl exec -it -n jellyfin deployment/jellyfin -- sh
   ```

2. Editar `system.xml`:
   ```bash
   vi /config/config/system.xml
   ```

3. Buscar y cambiar:
   ```xml
   <EnableLegacyAuthorization>false</EnableLegacyAuthorization>
   ```
   a:
   ```xml
   <EnableLegacyAuthorization>true</EnableLegacyAuthorization>
   ```

4. Reiniciar el pod:
   ```bash
   kubectl rollout restart deployment/jellyfin -n jellyfin
   ```

### Método 2: Automático con InitContainer (Recomendado)

Usar un initContainer para configurar automáticamente este valor. Ver `deployment.yaml` para la implementación.

## Notas Importantes

⚠️ **IMPLICACIONES DE SEGURIDAD**:
- Habilitar `EnableLegacyAuthorization` puede exponer el servidor a vulnerabilidades de seguridad
- Es una solución temporal hasta que los clientes de Apple TV se actualicen
- Se recomienda deshabilitar nuevamente una vez que los clientes sean compatibles

✅ **VENTAJAS**:
- Mucho más simple que el sidecar nginx
- No requiere modificación de requests HTTP
- Solución oficial recomendada en el issue de GitHub

## Alternativas

1. **Downgrade a versión 10.11.4**: Funciona pero no recomendado (versiones antiguas)
2. **Esperar actualización de clientes**: La solución ideal a largo plazo
3. **Sidecar nginx con inyección de parámetro App**: Funciona pero más complejo (ya intentado y removido)

## Referencias

- GitHub Issue: https://github.com/jellyfin/jellyfin/issues/15730
- Comentario de solución: Usuario reportó que `EnableLegacyAuthorization=true` resolvió el problema

