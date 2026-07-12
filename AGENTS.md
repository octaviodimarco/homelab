# AGENTS.md

## Purpose
- This repository is the GitOps source of truth for a multi-cluster homelab managed with Flux CD.
- Prefer small, declarative changes that preserve the current cluster/app separation.

## Repository Map
- `clusters/`: Flux entrypoints per cluster. Keep these files thin and focused on top-level wiring.
- `apps/base/`: reusable base manifests for applications.
- `apps/gordito/`: cluster-specific overlays and patches for app workloads.
- `infrastructure/controllers/`: operators/controllers installs, split into `base/` and cluster overlays.
- `infrastructure/configs/`: cluster config for shared infrastructure components.
- `monitoring/`: monitoring controllers and Grafana-related configuration.
- `databases/data/`: database manifests for the `data` cluster.
- `scripts/`: operational helper scripts.
- `backups/`: backup notes and procedures.

## Editing Rules
- Follow the existing Kustomize layout: put reusable manifests in `base/` and cluster-specific differences in cluster folders.
- Do not duplicate full manifests when a patch or overlay is enough.
- Keep resource names, namespaces, and paths consistent with the existing app or controller directory.
- Preserve YAML style already used in surrounding files.
- Keep comments concise and only where they add operational context.

## Flux and Kustomize Guidelines
- When adding a new app, wire it from the relevant cluster `kustomization.yaml` and keep the base self-contained.
- When adding infrastructure components, update both controller and config layers if the component needs both.
- Keep cluster-level Flux `Kustomization` objects simple: source, path, interval, prune, retry, timeout.
- Prefer one concern per manifest file when it matches the current repo pattern (`deployment.yaml`, `networking.yaml`, `storage.yaml`, `secrets.yaml`, etc.).

## Secrets and Safety
- Never commit plaintext secrets or credentials.
- Preserve the existing External Secrets / Infisical approach for secret material.
- Be careful with storage classes, ingress, DNS, and certificate changes because they affect live homelab services.
- Avoid destructive changes to existing workloads unless explicitly requested.

## Validation
- For manifest changes, validate the affected `kustomization.yaml` structure and references before finishing.
- If local tools are available, prefer targeted checks such as `kubectl kustomize <path>` or `kustomize build <path>` on changed overlays/bases.
- For script changes, keep shell scripts POSIX/Bash-friendly and preserve `set -euo pipefail` when already present.

## Workflow
- Start by reading the nearest `kustomization.yaml` files related to the change.
- Trace how a resource flows from `clusters/` to overlays and then to `base/` before refactoring.
- Keep changes scoped to the user request; do not reorganize unrelated directories.
- Update `README.md` only when the repo structure, deployed services list, or operating procedures materially change.
