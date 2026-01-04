# Plan: Configure oauth2-proxy with Pocket ID to protect n8n

## Objective

Configure oauth2-proxy as a reverse proxy to protect n8n using Pocket ID as an OIDC provider. Refactor the existing oauth2-proxy structure to use a template/base pattern with service-specific overlays, making it easier to add new protected services in the future.

## Context and Architectural Decision

### Initial Problem

Initially, it was proposed to create an exclusive oauth2-proxy instance for n8n. However, this raised concerns about how to handle multiple services that require oauth2-proxy protection.

### Solution: Template/Base Pattern with Overlays

A template/base pattern with service-specific overlays was chosen, which offers:

1. **Scalability**: Adding new services is just creating a new overlay following the template
2. **Maintainability**: Shared common base (repository, base namespace) facilitates updates
3. **Isolation**: Each service maintains its own configuration and secrets
4. **Clarity**: Clear structure showing which services are protected
5. **Reusability**: Consistent pattern for all protected services

## Architecture

```
Internet → Ingress (n8n.dimarco-server.site) → oauth2-proxy-n8n → n8n Service
```

All access to n8n will go through oauth2-proxy, which will redirect to Pocket ID for OIDC authentication before allowing access.

### Authentication Flow

1. User accesses `https://n8n.dimarco-server.site`
2. Ingress redirects to `oauth2-proxy-n8n` (port 4180)
3. oauth2-proxy checks if there's a valid authentication cookie
4. If no cookie, redirects to Pocket ID OIDC
5. User authenticates in Pocket ID
6. Pocket ID redirects to `https://n8n.dimarco-server.site/oauth2/callback`
7. oauth2-proxy validates the token and creates session cookie
8. oauth2-proxy proxies requests to n8n

## Proposed File Structure

### Refactoring Existing Structure

**Common base** (reusable for all services):
- `infrastructure/controllers/base/oauth2-proxy/namespace.yaml` - Common namespace (already exists)
- `infrastructure/controllers/base/oauth2-proxy/repository.yaml` - Common HelmRepository (already exists)
- `infrastructure/controllers/base/oauth2-proxy/kustomization.yaml` - Common base kustomization (to refactor)

**Services as overlays** (service-specific configuration):

1. **Jellyfin** (refactor existing):
   - `infrastructure/controllers/base/oauth2-proxy/services/jellyfin/release.yaml` - HelmRelease specific to Jellyfin (move from base)
   - `infrastructure/controllers/base/oauth2-proxy/services/jellyfin/kustomization.yaml` - Kustomization that references base + release

2. **n8n** (new):
   - `infrastructure/controllers/base/oauth2-proxy/services/n8n/release.yaml` - HelmRelease specific to n8n
   - `infrastructure/controllers/base/oauth2-proxy/services/n8n/kustomization.yaml` - Kustomization that references base + release

### Final Proposed Structure

```
infrastructure/
├── controllers/
│   ├── base/
│   │   └── oauth2-proxy/
│   │       ├── namespace.yaml          # Common base
│   │       ├── repository.yaml         # Common base
│   │       ├── kustomization.yaml      # Only common base
│   │       └── services/
│   │           ├── jellyfin/
│   │           │   ├── release.yaml
│   │           │   └── kustomization.yaml
│   │           └── n8n/
│   │               ├── release.yaml
│   │               └── kustomization.yaml
│   └── gordito/
│       └── oauth2-proxy/
│           └── kustomization.yaml      # Reference services
└── configs/
    ├── base/
    │   └── oauth2-proxy/
    │       ├── kustomization.yaml      # Reference services
    │       ├── jellyfin/
    │       │   ├── secrets.yaml
    │       │   └── kustomization.yaml
    │       └── n8n/
    │           ├── secrets.yaml
    │           └── kustomization.yaml
    └── gordito/
        └── oauth2-proxy/
            └── kustomization.yaml      # Reference services
```

## Detailed Configuration

### Template/Base Pattern

**Common base** (`infrastructure/controllers/base/oauth2-proxy/`):
- Shared namespace: `oauth2-proxy` (or per service as preferred)
- Shared HelmRepository
- Common values in comments/documentation for reference

**HelmRelease Template** (each service follows this pattern):
- Name: `oauth2-proxy-<service>` (e.g., `oauth2-proxy-n8n`)
- Namespace: `oauth2-proxy-<service>` or shared `oauth2-proxy`
- Service-configurable values:
  - Cookie Name: `_oauth2_proxy_<service>`
  - Redirect URL: `https://<service>.dimarco-server.site/oauth2/callback`
  - Upstream: `http://<service>.<namespace>.svc.cluster.local:<port>/`
  - Existing Secret: `oauth2-proxy-<service>-secrets`
  - Skip Auth Regex: Service-specific configuration

### HelmRelease Configuration for n8n

The oauth2-proxy-n8n HelmRelease will include:

- **Provider**: `oidc` (Pocket ID)
- **Cookie Name**: `_oauth2_proxy_n8n` (specific to n8n)
- **Redirect URL**: `https://n8n.dimarco-server.site/oauth2/callback`
- **Cookie Domain**: `.dimarco-server.site`
- **Upstream**: `http://n8n.n8n.svc.cluster.local:5678/` (n8n service)
- **Reverse Proxy Mode**: `true`
- **Skip Auth**: `skipAuthRegex` will not be configured as all authentication must go through oauth2-proxy
- **Scopes**: `openid email profile`
- **Existing Secret**: `oauth2-proxy-n8n-secrets` (created by ExternalSecret)
- **Namespace**: `oauth2-proxy-n8n` (to isolate per service)

### ExternalSecret Configuration

**Per-service pattern**: Each service has its own ExternalSecret in `infrastructure/configs/base/oauth2-proxy/<service>/`

**ExternalSecret for n8n** will read from Infisical:

- `/pocket-id/n8n/client_id` → `client_id`
- `/pocket-id/n8n/client_secret` → `client_secret`
- `/pocket-id/n8n/oidc_issuer_url` → `oidc_issuer_url`
- `/oauth2-proxy/n8n/cookie_secret` → `cookie_secret`

**ExternalSecret Namespace**: `oauth2-proxy-n8n` (same as HelmRelease)

### Ingress Update

The n8n Ingress will change the backend from:
- `service: n8n, port: http` 

To:
- `service: oauth2-proxy-n8n, namespace: oauth2-proxy-n8n, port: 4180`

## Files to Create/Modify

### New Files

1. **Infrastructure Controllers - Refactored Base**
   - `infrastructure/controllers/base/oauth2-proxy/services/` - Directory for services
   - `infrastructure/controllers/base/oauth2-proxy/services/jellyfin/release.yaml` - Move from `base/oauth2-proxy/release.yaml`
   - `infrastructure/controllers/base/oauth2-proxy/services/jellyfin/kustomization.yaml` - New kustomization for Jellyfin
   - `infrastructure/controllers/base/oauth2-proxy/services/n8n/release.yaml` - HelmRelease for n8n
   - `infrastructure/controllers/base/oauth2-proxy/services/n8n/kustomization.yaml` - Kustomization for n8n

2. **Infrastructure Configs - Maintain per-service structure**
   - `infrastructure/configs/base/oauth2-proxy/jellyfin/secrets.yaml` - Move from `base/oauth2-proxy/secrets.yaml`
   - `infrastructure/configs/base/oauth2-proxy/jellyfin/kustomization.yaml` - Kustomization for Jellyfin secrets
   - `infrastructure/configs/base/oauth2-proxy/n8n/secrets.yaml` - ExternalSecret for n8n
   - `infrastructure/configs/base/oauth2-proxy/n8n/kustomization.yaml` - Kustomization for n8n secrets

3. **Documentation**
   - `docs/OAUTH2_PROXY_N8N_POCKETID.md` - n8n-specific documentation
   - `docs/OAUTH2_PROXY_ARCHITECTURE.md` - Document the template/base pattern for adding new services

### Files to Modify

1. `apps/base/n8n/networking.yaml` - Update Ingress to point to oauth2-proxy-n8n
2. `infrastructure/controllers/base/oauth2-proxy/release.yaml` - Move to `services/jellyfin/release.yaml` and create template
3. `infrastructure/controllers/base/oauth2-proxy/kustomization.yaml` - Refactor to only include common base
4. `infrastructure/configs/base/oauth2-proxy/secrets.yaml` - Move to `jellyfin/secrets.yaml`
5. `infrastructure/configs/base/oauth2-proxy/kustomization.yaml` - Update to reference services
6. `infrastructure/controllers/gordito/oauth2-proxy/kustomization.yaml` - Update to include services
7. `infrastructure/configs/gordito/oauth2-proxy/kustomization.yaml` - Update to include services

## Prerequisites

### Pocket ID Configuration

Before deploying, an OIDC application must be created in Pocket ID:

- **Redirect URI**: `https://n8n.dimarco-server.site/oauth2/callback`
- **Scopes**: `openid`, `email`, `profile`
- Obtain `client_id`, `client_secret`, and `oidc_issuer_url`

### Secrets in Infisical

The following secrets must exist in Infisical before deployment:

- `/pocket-id/n8n/client_id`
- `/pocket-id/n8n/client_secret`
- `/pocket-id/n8n/oidc_issuer_url`
- `/oauth2-proxy/n8n/cookie_secret` (generate with `openssl rand -base64 32`)

## Implementation Steps

### Phase 1: Refactor Existing Structure

1. Create branch `feature/oauth2-proxy-n8n-pocketid`
2. Create directory `infrastructure/controllers/base/oauth2-proxy/services/`
3. Move `infrastructure/controllers/base/oauth2-proxy/release.yaml` → `infrastructure/controllers/base/oauth2-proxy/services/jellyfin/release.yaml`
4. Create `infrastructure/controllers/base/oauth2-proxy/services/jellyfin/kustomization.yaml` that references base + release
5. Update `infrastructure/controllers/base/oauth2-proxy/kustomization.yaml` to only include namespace and repository
6. Create directory `infrastructure/configs/base/oauth2-proxy/jellyfin/`
7. Move `infrastructure/configs/base/oauth2-proxy/secrets.yaml` → `infrastructure/configs/base/oauth2-proxy/jellyfin/secrets.yaml`
8. Create `infrastructure/configs/base/oauth2-proxy/jellyfin/kustomization.yaml`
9. Update `infrastructure/configs/base/oauth2-proxy/kustomization.yaml` to reference services
10. Update `infrastructure/controllers/gordito/oauth2-proxy/kustomization.yaml` to reference services
11. Update `infrastructure/configs/gordito/oauth2-proxy/kustomization.yaml` to reference services

### Phase 2: n8n Configuration

12. Create `infrastructure/controllers/base/oauth2-proxy/services/n8n/release.yaml` with n8n configuration
13. Create `infrastructure/controllers/base/oauth2-proxy/services/n8n/kustomization.yaml`
14. Create `infrastructure/configs/base/oauth2-proxy/n8n/secrets.yaml` with ExternalSecret
15. Create `infrastructure/configs/base/oauth2-proxy/n8n/kustomization.yaml`
16. Update kustomizations to include n8n
17. Update `apps/base/n8n/networking.yaml` to point to oauth2-proxy-n8n

### Phase 3: Documentation

18. Create `docs/OAUTH2_PROXY_N8N_POCKETID.md` with n8n-specific instructions
19. Create/update `docs/OAUTH2_PROXY_ARCHITECTURE.md` documenting the template/base pattern for adding new services

## Research Conducted

### Current oauth2-proxy Configuration

The existing oauth2-proxy configuration for Jellyfin was investigated:

- **Location**: `infrastructure/controllers/base/oauth2-proxy/`
- **Current pattern**: Single instance with Jellyfin-specific configuration
- **Secrets**: ExternalSecret in `infrastructure/configs/base/oauth2-proxy/secrets.yaml`
- **Ingress**: Jellyfin Ingress points to `service: oauth2-proxy, namespace: oauth2-proxy, port: 4180`

### Current n8n Configuration

- **Service**: `n8n` in namespace `n8n`, port `5678`
- **Ingress**: Currently points directly to `service: n8n, port: http`
- **Existing OIDC**: n8n already has OIDC configuration in its secrets (using Authentik)
- **Objective**: Add oauth2-proxy as authentication proxy in front of n8n

### External Secrets Patterns

How ExternalSecrets are configured with Infisical was reviewed:
- They use a `ClusterSecretStore` named `infisical`
- Pattern: `refreshInterval: 1h`, `secretStoreRef: {name: infisical, kind: ClusterSecretStore}`
- Secrets are mapped from Infisical paths to Kubernetes Secret keys

### Shared vs Separate Instance Considerations

Whether oauth2-proxy can handle multiple services in one instance was investigated:
- oauth2-proxy can have multiple upstreams, but routing is primarily based on path
- For different subdomains/services, each needs its own `redirectURL` and cookie configuration
- **Decision**: Use separate instances per service with template/base pattern for scalability

## Important Notes

1. **n8n already has OIDC**: n8n already has OIDC configuration with Authentik, but we want to use oauth2-proxy as an authentication proxy in front of n8n. This provides an additional security layer and unification.

2. **No bypass for native clients**: Unlike Jellyfin which has `skipAuthRegex` for native clients, n8n does not require bypass - all authentication must go through oauth2-proxy.

3. **Namespace per service**: Using `oauth2-proxy-<service>` as namespace is recommended to isolate each instance, although a shared `oauth2-proxy` namespace can also be used.

4. **Shared cookie domain**: Cookies use `.dimarco-server.site` to share authentication between subdomains if needed.

## References

- Existing documentation: `docs/OAUTH2_PROXY_JELLYFIN_POCKETID.md`
- Current Jellyfin configuration: `infrastructure/controllers/base/oauth2-proxy/release.yaml`
- ClusterSecretStore: `infrastructure/configs/base/external-secrets/cluster-secret-store.yaml`
