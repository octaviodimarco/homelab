# Guía de Uso de Grafana

## ⚡ Inicio Rápido

1. **Accede a**: `https://grafana.dimarco-server.site`
2. **Login**: Usuario `admin`, contraseña desde el secret:
   ```bash
   kubectl get secret grafana-admin-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
   ```
3. **Configura Prometheus**: Configuration → Data Sources → Add → Prometheus
   - URL: `http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090`
4. **Importa un dashboard**: Dashboards → Import → ID `1860` (Node Exporter)

## 📍 Acceso a Grafana

Tu Grafana está configurado y accesible en:
- **URL**: `https://grafana.dimarco-server.site`
- **Namespace**: `monitoring`
- **Puerto**: 3000 (expuesto vía Ingress)

## 🔐 Primer Acceso

1. **Abrir el navegador** y acceder a: `https://grafana.dimarco-server.site`

2. **Credenciales por defecto**:
   - **Usuario**: `admin` (configurado en el ExternalSecret)
   - **Contraseña**: Se obtiene del secret de Kubernetes desde Infisical
   
   Para obtener la contraseña:
   ```bash
   kubectl get secret grafana-admin-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
   ```

3. **Primer inicio**: Grafana te pedirá cambiar la contraseña (recomendado)

## 🎯 Pasos Iniciales

### 1. Configurar Prometheus como Data Source

Grafana necesita conectarse a Prometheus para mostrar métricas:

1. **Ir a**: Configuration (⚙️) → Data Sources → Add data source
2. **Seleccionar**: Prometheus
3. **URL**: `http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090`
   - Este es el nombre por defecto del servicio de Prometheus en el chart kube-prometheus-stack
   - Si no funciona, encuentra el nombre real ejecutando:
     ```bash
     kubectl get svc -n monitoring | grep prometheus
     ```
     Y usa el formato: `http://<nombre-del-servicio>.monitoring.svc.cluster.local:9090`
4. **Access**: Server (default)
5. **Click**: Save & Test
   - Deberías ver un mensaje verde: "Data source is working"

### 2. Explorar Métricas Existentes

1. **Explorer** (icono de brújula 🧭 en el menú lateral):
   - Permite hacer queries a Prometheus
   - Prueba queries como:
     - `up` - Muestra todos los targets
     - `node_cpu_seconds_total` - CPU usage
     - `container_memory_usage_bytes` - Uso de memoria

### 3. Importar Dashboards Pre-configurados

Grafana tiene dashboards oficiales que puedes importar:

1. **Ir a**: Dashboards (📊) → Import
2. **Buscar por ID** en [grafana.com/dashboards](https://grafana.com/dashboards):
   
   **Dashboards Recomendados**:
   - **Node Exporter Full** (ID: `1860`) - Métricas del sistema
   - **Kubernetes Cluster Monitoring** (ID: `7249`) - Métricas del cluster
   - **Kubernetes Pod Monitoring** (ID: `6417`) - Métricas de pods
   - **cAdvisor** (ID: `14282`) - Métricas de contenedores

3. **Seleccionar** Prometheus como data source
4. **Click**: Import

### 4. Crear tu Primer Dashboard

1. **Ir a**: Dashboards → New → New Dashboard
2. **Click**: Add visualization
3. **Seleccionar** Prometheus como data source
4. **Panel de Query**:
   - En "Metrics browser" escribe tu query (ej: `up`)
   - Ajusta el formato (Time series, Table, etc.)
5. **Panel Options**:
   - Cambia el título del panel
   - Ajusta colores y formato
6. **Save**: Click en Save dashboard (arriba a la derecha)

## 📊 Conceptos Clave

### Panels (Paneles)
- Cada gráfico/tabla en un dashboard es un "panel"
- Puedes tener múltiples panels en un dashboard

### Queries de Prometheus
Grafana usa PromQL (Prometheus Query Language). Ejemplos comunes:

```promql
# CPU usage promedio
rate(container_cpu_usage_seconds_total[5m])

# Memoria usada
container_memory_usage_bytes

# Uptime del cluster
up

# Requests por segundo
rate(http_requests_total[5m])

# Pods corriendo por namespace
count by (namespace) (kube_pod_info)

# Health Checks - Estado de readiness
kube_pod_container_status_ready

# Health Checks - Restarts de containers
kube_pod_container_status_restarts_total

# Health Checks - Estado del pod
kube_pod_status_phase
```

### Variables de Dashboard
Puedes crear variables para hacer dashboards dinámicos:
- Variables tipo "label_values" para seleccionar namespaces, pods, etc.
- Acceso desde queries: `$variable_name`

## 🔍 Explorar tu Cluster

### Ver Pods y su Estado
1. **Explorer** → Query: `kube_pod_info`
2. **Visualización**: Table
3. **Filtros**: Añade filtros por namespace, pod, etc.

### Monitorear Aplicaciones Específicas
Para tus apps (Jellyfin, n8n, etc.), busca métricas como:
- CPU: `rate(container_cpu_usage_seconds_total{pod=~"jellyfin.*"}[5m])`
- Memoria: `container_memory_usage_bytes{pod=~"jellyfin.*"}`
- Restart: `kube_pod_container_status_restarts_total`

## 🏥 Monitorear Health Checks de tus Servicios

**¡Sí!** Grafana es muy útil para ver el estado de los health checks de tus servicios. Kubernetes expone métricas sobre el estado de pods, containers y sus probes (liveness, readiness, startup).

### Estado General de Pods por Namespace

**Query para ver pods corriendo vs no corriendo:**
```promql
# Pods por estado (Running, Pending, Failed, etc.)
sum by (namespace, phase) (kube_pod_status_phase)
```

**Visualización**: Stat o Bar chart
- Muestra cuántos pods están en cada estado por namespace

### Estado de Readiness (Readiness Probes)

**Query para ver qué pods están "ready":**
```promql
# Pods listos vs no listos por namespace
sum by (namespace) (kube_pod_container_status_ready{namespace="default"})
```

**Para un servicio específico:**
```promql
# Estado de readiness de tus apps
kube_pod_container_status_ready{pod=~"jellyfin.*|n8n.*|linkding.*"}
```

**Visualización**: Table o Stat
- `1` = Ready (saludable)
- `0` = Not Ready (problemas)

### Restarts de Containers (Indicador de Problemas)

**Query para ver contenedores que han reiniciado:**
```promql
# Número total de restarts por pod
sum by (namespace, pod) (kube_pod_container_status_restarts_total{namespace="default"})
```

**Para detectar problemas (pods con muchos restarts):**
```promql
# Pods con más de 5 restarts
sum by (namespace, pod) (kube_pod_container_status_restarts_total) > 5
```

**Visualización**: Table o Time series
- Si un pod tiene muchos restarts, significa que está fallando los health checks

### Estado de Condiciones del Pod

**Query completa para ver todas las condiciones:**
```promql
# Condiciones del pod (Ready, Initialized, PodScheduled, etc.)
kube_pod_status_condition{condition="Ready", status="true"}
```

**Para ver pods NO listos:**
```promql
# Pods que NO están ready
kube_pod_status_condition{condition="Ready", status="false"}
```

**Visualización**: Table con filtros
- Muestra qué pods tienen problemas y por qué

### Dashboard de Health Checks Recomendado

**Crear un dashboard simple:**

1. **Panel 1: Estado de Pods (Stat)**
   - Query: `sum by (phase) (kube_pod_status_phase{namespace="default"})`
   - Title: "Pod Status"
   - Muestra: Running, Pending, Failed

2. **Panel 2: Readiness por App (Table)**
   - Query: `kube_pod_container_status_ready{pod=~"jellyfin.*|n8n.*|linkding.*|memos.*"}`
   - Title: "Service Readiness"
   - Muestra: 1 (ready) o 0 (not ready)

3. **Panel 3: Restarts (Time Series)**
   - Query: `sum by (pod) (increase(kube_pod_container_status_restarts_total[1h]))`
   - Title: "Container Restarts (Last Hour)"
   - Muestra: Tendencias de reinicios

4. **Panel 4: Pods No Ready (Alert)**
   - Query: `kube_pod_status_condition{condition="Ready", status="false"}`
   - Title: "Pods Not Ready"
   - Thresholds: Verde si = 0, Rojo si > 0

### Queries Específicas para tus Servicios

**Jellyfin:**
```promql
# Estado de readiness
kube_pod_container_status_ready{pod=~"jellyfin.*"}
# Restarts
sum by (pod) (kube_pod_container_status_restarts_total{pod=~"jellyfin.*"})
```

**n8n:**
```promql
# Estado de readiness
kube_pod_container_status_ready{pod=~"n8n.*"}
# Restarts
sum by (pod) (kube_pod_container_status_restarts_total{pod=~"n8n.*"})
```

### Interpretación de Resultados

- **Ready = 1**: ✅ Health check pasando, servicio funcionando
- **Ready = 0**: ❌ Health check fallando, servicio no está respondiendo correctamente
- **Restarts > 0**: ⚠️ El pod ha reiniciado (puede ser por liveness probe fallando)
- **Phase = Failed**: 🔴 Pod falló completamente
- **Phase = Pending**: ⏳ Pod esperando recursos o errores de scheduling

### Nota Importante

Grafana muestra las **métricas de Kubernetes** sobre health checks (estado de pods, readiness, restarts), pero **no muestra directamente los resultados de las HTTP calls** a tus endpoints `/health` o `/healthz`.

Si quieres monitorear los health checks HTTP directamente, necesitarías:
1. Que tus apps expongan métricas Prometheus con el estado del health check
2. O usar Blackbox Exporter para hacer probes HTTP externos

## 🎨 Personalización

### Temas
1. **Preferences** (perfil usuario, abajo a la izquierda)
2. **Theme**: Light / Dark / System

### Alertas (Opcional)
1. **Alerting** (📢) → Alert rules → New alert rule
2. Configura condiciones (ej: CPU > 80% por 5 minutos)
3. Define notificaciones (email, Slack, etc.)

## 🚀 Tips Útiles

1. **Time Range**: Usa el selector de tiempo (arriba a la derecha) para ver períodos específicos
2. **Refresh**: Configura auto-refresh (⏱️) para actualización automática
3. **Annotations**: Añade anotaciones para marcar eventos (deployments, restarts, etc.)
4. **Sharing**: Puedes compartir dashboards como JSON o crear links públicos
5. **Favorites**: Marca dashboards favoritos con la estrella ⭐

## 📚 Recursos Adicionales

- **Prometheus Queries**: [promlens.com](https://promlens.com/) - Editor interactivo de PromQL
- **Dashboards**: [grafana.com/dashboards](https://grafana.com/dashboards)
- **Documentación**: [grafana.com/docs](https://grafana.com/docs/)

## 🔧 Troubleshooting

### No veo métricas
- Verifica que Prometheus esté corriendo: `kubectl get pods -n monitoring`
- Verifica la conexión del data source: Configuration → Data Sources → Prometheus → Test

### No encuentro una métrica específica
- Usa el Explorer para buscar métricas disponibles
- En Prometheus directamente: `http://prometheus-service:9090/graph`
- Lista de métricas: `{__name__=~".*"}` en Prometheus

### Dashboard no se actualiza
- Verifica el intervalo de scrape en Prometheus
- Ajusta el refresh rate del dashboard
- Revisa el time range seleccionado

