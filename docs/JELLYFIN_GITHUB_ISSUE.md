# Issue de GitHub #15730 - Jellyfin Apple TV Authentication

## Resumen

El problema de autenticación con clientes Apple TV que estás experimentando **YA FUE REPORTADO** en GitHub como issue [#15730](https://github.com/jellyfin/jellyfin/issues/15730).

## Detalles del Issue

- **URL**: https://github.com/jellyfin/jellyfin/issues/15730
- **Título**: "Jellyfin login does not work from Apple devices"
- **Reportado por**: @gelato
- **Fecha de apertura**: 6 de diciembre de 2025
- **Fecha de cierre**: 7 de diciembre de 2025 (al día siguiente)
- **Estado**: Cerrado
- **Etiqueta**: "bug" → Marcado como "Not A Bug"

## Error Reportado

El mismo error que experimentas:

```
System.ArgumentNullException: Value cannot be null. (Parameter 'request.App')
   at Emby.Server.Implementations.Session.SessionManager.AuthenticateNewSessionInternal(AuthenticationRequest request, Boolean enforcePassword)
   at Jellyfin.Api.Controllers.UserController.AuthenticateUserByName(AuthenticateUserByName request)
```

## Clientes Afectados (según el issue)

- Apple TV 4K
- Infuse en macOS
- Navegadores funcionan correctamente (Safari, Chrome)

## Versión del Servidor

- **Versión reportada**: 2025120105 (actualización del 1 de diciembre de 2025)
- El problema comenzó después de actualizar a esta versión

## Estado del Issue

El issue fue **cerrado rápidamente** (al día siguiente de ser reportado). Según los metadatos, fue marcado como "Not A Bug", lo que sugiere que:

1. Los mantenedores consideran que esto no es un bug de Jellyfin
2. Puede ser un problema con los clientes que no envían el parámetro `App` correctamente
3. Puede haber una solución/workaround que los mantenedores conocen
4. Puede haber sido un problema temporal que se resolvió en una versión posterior

## Implicaciones

Dado que el issue fue cerrado como "Not A Bug", es probable que:

- Los clientes de Apple TV deberían enviar el parámetro `App` en las peticiones de autenticación
- El problema puede estar en los clientes (Swiftfin, Infuse, Streamify) y no en Jellyfin
- Puede haber una solución del lado del servidor (como el sidecar nginx que intentaste implementar)

## Relación con Tu Configuración

Tu intento de solucionar esto con un **nginx sidecar que inyecta el parámetro `App=Apple TV`** es una solución válida del lado del servidor, aunque:

1. El sidecar fue removido en el commit `ca85b29` (5 de enero)
2. Actualmente no tienes el sidecar implementado
3. El problema persiste sin el sidecar

## Recomendaciones

1. **Revisar el hilo completo del issue #15730** para ver si hay comentarios sobre la resolución o workarounds
2. **Actualizar a la versión más reciente de Jellyfin** para ver si el problema fue resuelto en versiones posteriores
3. **Considerar restaurar el sidecar nginx** si el problema persiste y no hay otra solución
4. **Contactar a los desarrolladores de los clientes** (Swiftfin, Infuse) para reportar que no envían el parámetro `App`

## Referencias

- Issue de GitHub: https://github.com/jellyfin/jellyfin/issues/15730
- Tu reporte local: `JELLYFIN_ISSUE_REPORT.md`
- Documentación de OAuth2: `docs/OAUTH2_PROXY_JELLYFIN_POCKETID.md`

