# Resource Health Status (Beta)

## Overview

Kubernetes 1.36 promotes Resource Health Status to Beta, providing native hardware health reporting directly visible in `kubectl describe pod`. This feature helps diagnose Pod crashes caused by hardware failures without requiring external monitoring tools.

## 🎯 Key Benefits

- **Hardware Visibility**: Direct visibility into device health from kubectl
- **Faster Troubleshooting**: Identify hardware issues vs application problems
- **Automated Recovery**: Controllers can respond to hardware failures
- **Unified Interface**: Works with traditional plugins and DRA framework

## 📋 Prerequisites

- Kubernetes v1.36+ cluster
- ResourceHealthStatus feature gate enabled
- Compatible CSI drivers or device plugins
- Cluster admin permissions

## 🚀 Quick Start

### 1. Enable Feature Gate

```bash
# Enable for kubelet
--feature-gates=ResourceHealthStatus=true

# Enable for kube-controller-manager
--feature-gates=ResourceHealthStatus=true
```

### 2. Deploy Application with Hardware Resources

```yaml
# gpu-workload.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ml-training-pod
  namespace: default
spec:
  containers:
  - name: ml-trainer
    image: pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime
    command:
    - python
    - -c
    - |
      import torch
      print(f"CUDA available: {torch.cuda.is_available()}")
      if torch.cuda.is_available():
          print(f"GPU count: {torch.cuda.device_count()}")
          print(f"Current device: {torch.cuda.current_device()}")
      
      # Simulate ML training workload
      import time
      for i in range(10):
          print(f"Training step {i+1}/10")
          time.sleep(5)
      
      print("Training completed!")
    resources:
      requests:
        nvidia.com/gpu: 1
        memory: "8Gi"
        cpu: "2"
      limits:
        nvidia.com/gpu: 1
        memory: "16Gi"
        cpu: "4"
    volumeMounts:
    - name: data-volume
      mountPath: /data
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: ml-data-pvc
  restartPolicy: OnFailure
```

### 3. Create Supporting Resources

```yaml
# supporting-resources.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ml-data-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: ssd-storage
---
# Example with multiple device types
apiVersion: v1
kind: Pod
metadata:
  name: multi-device-pod
  namespace: default
spec:
  containers:
  - name: compute-container
    image: ubuntu:22.04
    command:
    - bash
    - -c
    - |
      echo "Checking device health..."
      while true; do
        echo "Device check at $(date)"
        sleep 30
      done
    resources:
      requests:
        nvidia.com/gpu: 1
        example.com/fpga: 1
        memory: "4Gi"
      limits:
        nvidia.com/gpu: 1
        example.com/fpga: 1
        memory: "8Gi"
  restartPolicy: Always
```

## 📊 Monitoring Device Health

### Check Pod with Device Health Status

```bash
# Deploy the workload
kubectl apply -f gpu-workload.yaml

# Wait for pod to be running
kubectl wait --for=condition=Ready pod/ml-training-pod --timeout=300s

# Check device health status
kubectl describe pod ml-training-pod
```

**Expected Output:**
```
Name:         ml-training-pod
Namespace:    default
Status:       Running
...
Status:
  Allocated Resources:
    example.com/fpga:  1
    memory:            8Gi
    nvidia.com/gpu:    1
  Allocated Resources Status:
    example.com/fpga:
      Device: fpga-0
      Status: Healthy
      Last HealthProbeTime: 2026-05-20T14:30:00Z
    nvidia.com/gpu:
      Device: gpu-0
      Status: Healthy
      Last HealthProbeTime: 2026-05-20T14:30:00Z
...
```

### Simulate Hardware Failure

```yaml
# simulate-failure.yaml
apiVersion: v1
kind: Pod
metadata:
  name: failure-simulator
  namespace: default
spec:
  containers:
  - name: simulator
    image: alpine:3.18
    command:
    - /bin/sh
    - -c
    - |
      echo "Simulating device failure..."
      # This would typically be done by the device plugin/CSI driver
      # Here we're just demonstrating the monitoring setup
      sleep 3600
    securityContext:
      privileged: true
  restartPolicy: Never
```

## 🔍 Advanced Examples

### Custom Device Health Monitoring

```yaml
# custom-device-plugin.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: custom-device-plugin
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: custom-device-plugin
  template:
    metadata:
      labels:
        name: custom-device-plugin
    spec:
      tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      containers:
      - name: device-plugin
        image: your-registry/custom-device-plugin:v1.36.0
        command:
        - ./device-plugin
        - --health-monitoring=true
        - --health-check-interval=30s
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        volumeMounts:
        - name: device-plugin
          mountPath: /var/lib/kubelet/device-plugins
        - name: pod-resources
          mountPath: /var/lib/kubelet/pod-resources
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      volumes:
      - name: device-plugin
        hostPath:
          path: /var/lib/kubelet/device-plugins
      - name: pod-resources
        hostPath:
          path: /var/lib/kubelet/pod-resources
```

### Health Status Monitoring Dashboard

```yaml
# health-monitor.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: device-health-monitor
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: device-health-monitor
  template:
    metadata:
      labels:
        app: device-health-monitor
    spec:
      serviceAccountName: health-monitor-sa
      containers:
      - name: monitor
        image: bitnami/kubectl:latest
        command:
        - /bin/sh
        - -c
        - |
          while true; do
            echo "=== Device Health Report $(date) ==="
            
            # Get all pods with allocated resources
            kubectl get pods -A -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,STATUS:.status.phase > /tmp/pods.txt
            
            while IFS= read -r line; do
              if [[ "$line" != *"NAME"* ]]; then
                pod_name=$(echo "$line" | awk '{print $1}')
                namespace=$(echo "$line" | awk '{print $2}')
                
                echo "Checking pod: $namespace/$pod_name"
                kubectl describe pod "$pod_name" -n "$namespace" | grep -A 10 "Allocated Resources Status" || echo "No device health info"
              fi
            done < /tmp/pods.txt
            
            echo "=== End Report ==="
            sleep 60
          done
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: health-monitor-sa
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: health-monitor-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "describe"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: health-monitor-binding
subjects:
- kind: ServiceAccount
  name: health-monitor-sa
  namespace: monitoring
roleRef:
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
  name: health-monitor-role
```

## 📈 Integration with Monitoring Systems

### Prometheus Metrics Export

```yaml
# health-metrics-exporter.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: health-metrics-script
  namespace: monitoring
data:
  export-metrics.sh: |
    #!/bin/bash
    
    echo "# HELP k8s_device_health_status Device health status (1=healthy, 0=unhealthy, -1=unknown)"
    echo "# TYPE k8s_device_health_status gauge"
    
    # Get all pods with device allocations
    kubectl get pods -A -o json | jq -r '.items[] | select(.status.allocatableResourcesStatus != null) | 
      "\(.metadata.namespace) \(.metadata.name) \(.status.allocatableResourcesStatus | to_entries[] | "\(.key) \(.value.status // "Unknown")")"' | 
    while read -r namespace pod device status; do
      case "$status" in
        "Healthy") value=1 ;;
        "Unhealthy") value=0 ;;
        *) value=-1 ;;
      esac
      echo "k8s_device_health_status{namespace=\"$namespace\",pod=\"$pod\",device=\"$device\"} $value"
    done
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-metrics-exporter
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: health-metrics-exporter
  template:
    metadata:
      labels:
        app: health-metrics-exporter
    spec:
      serviceAccountName: metrics-exporter-sa
      containers:
      - name: exporter
        image: bitnami/kubectl:latest
        command:
        - /bin/sh
        - -c
        - |
          while true; do
            /scripts/export-metrics.sh | nc -l -p 8080 -q 1 &
            sleep 30
          done
        volumeMounts:
        - name: scripts
          mountPath: /scripts
          readOnly: true
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        ports:
        - containerPort: 8080
          name: metrics
      volumes:
      - name: scripts
        configMap:
          name: health-metrics-script
          defaultMode: 0755
---
apiVersion: v1
kind: Service
metadata:
  name: health-metrics-exporter
  namespace: monitoring
  labels:
    app: health-metrics-exporter
spec:
  ports:
  - port: 8080
    targetPort: 8080
    name: metrics
  selector:
    app: health-metrics-exporter
```

## ⚠️ Important Notes

- **Beta Feature**: API may change but is stabilizing
- **Driver Support**: Requires device plugins/CSI drivers that support health reporting
- **Performance**: Minimal performance impact on pod scheduling
- **Scope**: Only reports on allocated devices, not available devices

## 🛠️ Troubleshooting

### Common Issues

1. **No Health Status Visible**
   ```bash
   # Check if feature gate is enabled
   kubectl get nodes -o yaml | grep feature-gates
   
   # Verify device plugin supports health reporting
   kubectl logs -n kube-system -l name=device-plugin
   ```

2. **Health Status Always Unknown**
   ```bash
   # Check device plugin health
   kubectl get pods -n kube-system -l name=device-plugin
   
   # Verify driver compatibility
   kubectl get csidriver
   ```

3. **Performance Issues**
   ```bash
   # Monitor kubelet metrics
   kubectl get --raw "/metrics" | grep device_health
   
   # Check health check frequency
   kubectl describe node <node-name> | grep -i health
   ```

## 📚 Additional Resources

- [KEP #4680: Resource Health Status](https://kep.k8s.io/4680)
- [Device Plugin Documentation](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/)
- [CSI Driver Documentation](https://kubernetes-csi.github.io/docs/)

---

**Resource Health Status brings hardware monitoring into the native Kubernetes experience, enabling faster troubleshooting and more reliable infrastructure operations.**
