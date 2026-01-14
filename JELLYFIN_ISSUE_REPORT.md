# Authentication fails for all Apple TV clients: `request.App` parameter is null

**Related GitHub Issue**: [#15730](https://github.com/jellyfin/jellyfin/issues/15730) - "Jellyfin login does not work from Apple devices" (Opened Dec 6, 2025, Closed Dec 7, 2025)

## Description
All Apple TV clients (Swiftfin, Streamify, Infuse) fail to authenticate with Jellyfin server. The server throws `System.ArgumentNullException: Value cannot be null. (Parameter 'request.App')` when processing authentication requests via `POST /Users/AuthenticateByName`.

This issue was reported on GitHub as issue #15730 and appears to have been closed. The same problem affects multiple users with Apple TV clients.

## Environment
- **Jellyfin Version**: `jellyfin/jellyfin:latest` (Docker image, pulled January 2025)
- **Operating System**: Kubernetes (container runtime)
- **Architecture**: x86_64
- **Server Location**: Argentina
- **Client Location**: Spain (Apple TV)
- **Network**: HTTPS via domain, Cloudflare DNS only (no proxy)
- **Infrastructure**: Kubernetes with Nginx Ingress Controller
- **Reverse Proxy**: Nginx Ingress Controller (Kubernetes)

## Clients Tested
All tested clients fail with the same error:
- ✅ Swiftfin (official Jellyfin client for Apple TV)
- ✅ Streamify
- ✅ Infuse Pro

## Error Details

### Stack Trace
```
[ERR] Jellyfin.Api.Middleware.ExceptionMiddleware: Error processing request. URL POST /Users/AuthenticateByName.
System.ArgumentNullException: Value cannot be null. (Parameter 'request.App')
   at System.ArgumentNullException.Throw(String paramName)
   at System.ArgumentNullException.ThrowIfNull(Object argument, String paramName)
   at System.ArgumentException.ThrowNullOrEmptyException(String argument, String paramName)
   at System.ArgumentException.ThrowIfNullOrEmpty(String argument, String paramName)
   at Emby.Server.Implementations.Session.SessionManager.AuthenticateNewSessionInternal(AuthenticationRequest request, Boolean enforcePassword)
   at Jellyfin.Api.Controllers.UserController.AuthenticateUserByName(AuthenticateUserByName request)
   at lambda_method993(Closure, Object)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ActionMethodExecutor.AwaitableObjectResultExecutor.Execute(ActionContext actionContext, IActionResultTypeMapper mapper, ObjectMethodExecutor executor, Object controller, Object[] arguments)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.<InvokeActionMethodAsync>g__Awaited|12_0(ControllerActionInvoker invoker, ValueTask`1 actionResultValueTask)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.<InvokeNextActionFilterAsync>g__Awaited|10_0(ControllerActionInvoker invoker, Task lastTask, State next, Scope scope, Object state, Boolean isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.Rethrow(ControllerExecutedContextSealed context)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.Next(State& next, Scope& scope, Object& state, Boolean& isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.InvokeInnerFilterAsync()
--- End of stack trace from previous location ---
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.<InvokeNextResourceFilter>g__Awaited|25_0(ResourceInvoker invoker, Task lastTask, State next, Scope scope, Object state, Boolean isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.Rethrow(ResourceExecutedContextSealed context)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.Next(State& next, Scope& scope, Object& state, Boolean& isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.InvokeFilterPipelineAsync()
--- End of stack trace from previous location ---
```

### Error Location
- **Endpoint**: `POST /Users/AuthenticateByName`
- **Error**: `request.App` parameter is null or empty
- **Impact**: Authentication fails for all Apple TV clients

## Infrastructure Configuration

### Nginx Ingress Annotations
```yaml
nginx.ingress.kubernetes.io/proxy-body-size: "0"
nginx.ingress.kubernetes.io/proxy-buffering: "off"
nginx.ingress.kubernetes.io/proxy-connect-timeout: "3600"
nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
nginx.ingress.kubernetes.io/use-forwarded-headers: "true"
nginx.ingress.kubernetes.io/websocket-services: "jellyfin-svc"
```

### Ingress Configuration
- **API Version**: `networking.k8s.io/v1`
- **Ingress Class**: `nginx`
- **TLS**: Enabled (Let's Encrypt)
- **Cloudflare**: DNS only (no proxy, no request modification)

### Service Configuration
- **Port**: 8096
- **Target Port**: 8096
- **Protocol**: TCP

## Steps to Reproduce
1. Configure Jellyfin server behind Nginx Ingress in Kubernetes
2. Access server via HTTPS domain (Cloudflare DNS only)
3. Attempt to authenticate from any Apple TV client (Swiftfin, Streamify, or Infuse)
4. Authentication fails with `request.App` null error

## Expected Behavior
Jellyfin should accept authentication requests from Apple TV clients. The `App` parameter should either be optional, or Jellyfin should provide a default value if it's missing.

## Actual Behavior
Jellyfin throws `ArgumentNullException` when `request.App` is null, preventing authentication from all Apple TV clients.

## Solution

**✅ SOLUCIÓN ENCONTRADA**: Según los comentarios en el issue #15730, la solución es:

**Cambiar `EnableLegacyAuthorization` a `true` en `/config/config/system.xml`**

```xml
<EnableLegacyAuthorization>true</EnableLegacyAuthorization>
```

**Método 1 (Manual)**:
1. Editar el archivo después de que Jellyfin inicie por primera vez
2. Reiniciar el pod

**Método 2 (Automático)**:
- Usar un initContainer para configurar esto automáticamente (ver `docs/JELLYFIN_APPLE_TV_FIX.md`)

⚠️ **Nota de Seguridad**: Habilitar `EnableLegacyAuthorization` es una solución temporal que puede tener implicaciones de seguridad. Se recomienda deshabilitarlo nuevamente cuando los clientes se actualicen.

## Additional Information
- This issue affects **all** Apple TV clients tested, not just one specific client
- The error occurs consistently on every authentication attempt
- Server is accessible via HTTPS and other endpoints work correctly
- Cloudflare is configured as DNS only (no proxy, no request modification)
- Nginx Ingress is configured with `proxy-request-buffering: "off"` to allow body passthrough
- The issue persists across multiple client applications, suggesting a server-side problem
- Server and client are in different countries (Argentina and Spain), but Cloudflare is not proxying requests

## Logs
Full error stack trace is consistently:
```
[ERR] Jellyfin.Api.Middleware.ExceptionMiddleware: Error processing request. URL POST /Users/AuthenticateByName.
System.ArgumentNullException: Value cannot be null. (Parameter 'request.App')
   at Emby.Server.Implementations.Session.SessionManager.AuthenticateNewSessionInternal(AuthenticationRequest request, Boolean enforcePassword)
   at Jellyfin.Api.Controllers.UserController.AuthenticateUserByName(AuthenticateUserByName request)
```

## Related Issues
- **GitHub Issue #15730**: [Jellyfin login does not work from Apple devices](https://github.com/jellyfin/jellyfin/issues/15730)
  - Reported: December 6, 2025
  - Status: Closed (Dec 7, 2025)
  - Same error: `System.ArgumentNullException: Value cannot be null. (Parameter 'request.App')`
  - Affected clients: Apple TV 4K, Infuse on macOS
  - Version: 2025120105

## Checklist
- [x] I have searched existing issues to ensure this is not a duplicate
- [x] Related issue found: [#15730](https://github.com/jellyfin/jellyfin/issues/15730)
- [x] I have tested with the latest stable version of Jellyfin
- [x] I have tested with multiple clients (Swiftfin, Streamify, Infuse)
- [x] I have provided detailed logs and error messages
- [x] I have provided infrastructure configuration details
- [x] I agree to follow Jellyfin's Code of Conduct
