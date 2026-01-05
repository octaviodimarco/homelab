# Problemas Identificados en la Configuración de Jellyfin

## Resumen Ejecutivo

La configuración actual de Jellyfin tiene **inconsistencias críticas** que hacen que el deployment sea frágil y algunos health checks fallen. El agente ha creado una configuración que mezcla puertos incorrectamente.

## Problemas Críticos Encontrados

### 1. ❌ INCONSISTENCIA CRÍTICA: Health Checks con Puertos Incorrectos

**Ubicación**: `deployment.yaml` líneas 98-126

**Problema**: Los health checks están mezclando puertos incorrectamente:

- **Línea 98**: Contenedor Jellyfin declara `containerPort: 8096` con nombre "http"
- **Línea 103**: `livenessProbe` apunta al puerto **8096** ⚠️ **INCORRECTO**
- **Línea 112**: `readinessProbe` apunta al puerto **8097** ✅ CORRECTO
- **Línea 121**: `startupProbe` apunta al puerto **8097** ✅ CORRECTO

**Análisis**:
- El initContainer configura Jellyfin para escuchar en **8097** (línea 44-81)
- El livenessProbe intenta conectarse a **8096**, donde Jellyfin NO está escuchando
- Esto causará que el livenessProbe **falle siempre**, haciendo que Kubernetes reinicie el pod constantemente

**Impacto**: El pod de Jellyfin será reiniciado constantemente debido a livenessProbe failures.

### 2. ❌ Declaración de Puerto Incorrecta

**Ubicación**: `deployment.yaml` línea 98-99

**Problema**: 
- El contenedor declara `containerPort: 8096` pero Jellyfin está configurado para escuchar en **8097**
- Esto es confuso y no refleja la realidad de dónde Jellyfin está escuchando

### 3. ⚠️ InitContainer Frágil

**Ubicación**: `deployment.yaml` líneas 17-91

**Problema**: El initContainer `configure-jellyfin-port` intenta modificar el archivo `system.xml` de Jellyfin antes de que el contenedor principal inicie.

**Issues específicos**:
- **Primera ejecución**: Si Jellyfin nunca se ha ejecutado antes, el archivo `/config/config/system.xml` no existirá. El initContainer espera hasta 60 segundos y luego falla con error (línea 36-38).
- **Sobrescritura**: Incluso si el archivo existe y se modifica correctamente, Jellyfin podría sobrescribir el archivo al iniciar, dependiendo del orden de ejecución.
- **Complejidad innecesaria**: La lógica para insertar/modificar el XML es compleja y propensa a errores (buscar tags, insertar líneas con head/tail, etc.).

**Código problemático**:
```yaml
initContainers:
  - name: configure-jellyfin-port
    # Script complejo que modifica system.xml para cambiar puerto a 8097
    # Falla si el archivo no existe (primera ejecución)
```

### 4. ✅ Configuración Correcta (Para Referencia)

Estos elementos están correctos:
- **Nginx sidecar** (línea 144): Escucha en puerto 8096 ✅
- **Nginx config** (línea 48): Hace proxy a `127.0.0.1:8097` ✅
- **Service** (networking.yaml línea 12): `targetPort: 8096` (apunta al sidecar nginx) ✅
- **readinessProbe y startupProbe**: Apuntan a 8097 (donde realmente está Jellyfin) ✅

## Arquitectura Actual (Confusa)

```
Internet → Ingress → Service (8096) → Nginx Sidecar (8096) → Jellyfin (8097)
                                                              ↑
                                                         (según initContainer)

Health Checks:
- livenessProbe → 8096 ❌ (INCORRECTO - Jellyfin no está aquí)
- readinessProbe → 8097 ✅ (CORRECTO)
- startupProbe → 8097 ✅ (CORRECTO)
```

## Soluciones Propuestas

### Solución Rápida (Corrección Mínima)

**Cambiar solo el livenessProbe para que apunte a 8097**:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8097  # Cambiar de 8096 a 8097
```

**También corregir la declaración del puerto del contenedor**:

```yaml
ports:
  - containerPort: 8097  # Cambiar de 8096 a 8097 (o eliminar si no se usa)
    name: http-internal
```

### Solución Recomendada (Simplificación Completa) ⭐

**Eliminar el initContainer y simplificar la arquitectura**:

1. **Eliminar el initContainer completamente**
2. **Dejar que Jellyfin escuche en su puerto por defecto (8096)**
3. **Cambiar el sidecar nginx para que escuche en 8097 y haga proxy a 8096**
4. **Actualizar el Service para que apunte a 8097 (el sidecar nginx)**
5. **Actualizar todos los health checks para que apunten a 8096 (Jellyfin directo)**

**Ventajas**:
- Elimina el punto de fallo del initContainer
- Simplifica la configuración
- Mantiene la funcionalidad del sidecar nginx (script Lua para Apple TV)
- Jellyfin usa su puerto por defecto (más estándar)
- Todos los health checks funcionan correctamente

**Desventajas**:
- Requiere cambios en el Service, nginx config y health checks

## Orden de Prioridad para Corrección

1. **URGENTE**: Corregir el livenessProbe (puerto 8096 → 8097) - Sin esto el pod se reiniciará constantemente
2. **IMPORTANTE**: Corregir o eliminar la declaración de containerPort 8096
3. **RECOMENDADO**: Simplificar eliminando el initContainer

## Estado Actual

El código actual **NO funcionará correctamente** debido a:
- El livenessProbe fallará siempre (apunta al puerto incorrecto)
- Esto causará reinicios constantes del pod
- El initContainer es frágil y fallará en primera ejecución
