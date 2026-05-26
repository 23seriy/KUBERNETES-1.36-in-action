# Volume Group Snapshots (Stable)

## Overview

Kubernetes 1.36 graduates Volume Group Snapshots to General Availability (GA). This feature allows you to take crash-consistent snapshots across multiple PersistentVolumeClaims simultaneously, essential for multi-volume applications and disaster recovery.

## 🎯 Key Benefits

- **Crash Consistency**: All volumes snapped at the same point in time
- **Multi-Volume Applications**: Perfect for databases with separate data and log volumes
- **Disaster Recovery**: Restore entire application state consistently
- **Performance**: More efficient than individual volume snapshots

## 📋 Prerequisites

- Kubernetes v1.36+ cluster
- CSI driver that supports volume group snapshots
- VolumeGroupSnapshot CRDs installed
- Sufficient storage capacity for snapshots

## 🚀 Quick Start

### 1. Install Volume Group Snapshot CRDs

```bash
# Install the required CRDs
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v6.3.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v6.3.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v6.3.0/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v6.3.0/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshots.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v6.3.0/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshotcontents.yaml
```

### 2. Create VolumeGroupSnapshotClass

```yaml
# volumegroupsnapshotclass.yaml
apiVersion: groupsnapshot.storage.k8s.io/v1
kind: VolumeGroupSnapshotClass
metadata:
  name: csi-hostpath-group-snapclass
driver: hostpath.csi.k8s.io  # Replace with your CSI driver
deletionPolicy: Delete
parameters:
  # Driver-specific parameters
  compression: "true"
  encryption: "false"
```

### 3. Deploy Multi-Volume Application

```yaml
# multi-volume-app.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-data-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-logs-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database
  namespace: default
spec:
  serviceName: database
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: database
        image: postgres:15
        env:
        - name: POSTGRES_PASSWORD
          value: "secretpassword"
        - name: POSTGRES_DB
          value: "myapp"
        ports:
        - containerPort: 5432
          name: postgres
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        - name: logs
          mountPath: /var/log/postgresql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
      storageClassName: standard
  - metadata:
      name: logs
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 5Gi
      storageClassName: standard
```

### 4. Create Volume Group Snapshot

```yaml
# database-group-snapshot.yaml
apiVersion: groupsnapshot.storage.k8s.io/v1
kind: VolumeGroupSnapshot
metadata:
  name: database-group-snapshot
  namespace: default
spec:
  volumeGroupSnapshotClassName: csi-hostpath-group-snapclass
  source:
    selector:
      matchLabels:
        app: database  # This will select all PVCs for the database
```

## 📊 Advanced Examples

### Time-Based Snapshot Schedule

```yaml
# scheduled-group-snapshot.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: database-snapshot-cronjob
  namespace: default
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: snapshot-creator
            image: bitnami/kubectl:latest
            command:
            - /bin/sh
            - -c
            - |
              TIMESTAMP=$(date +%Y%m%d-%H%M%S)
              cat <<EOF | kubectl apply -f -
              apiVersion: groupsnapshot.storage.k8s.io/v1
              kind: VolumeGroupSnapshot
              metadata:
                name: database-group-snapshot-${TIMESTAMP}
                namespace: default
              spec:
                volumeGroupSnapshotClassName: csi-hostpath-group-snapclass
                source:
                  selector:
                    matchLabels:
                      app: database
              EOF
          restartPolicy: OnFailure
```

### Selective Volume Group Snapshot

```yaml
# selective-group-snapshot.yaml
apiVersion: groupsnapshot.storage.k8s.io/v1
kind: VolumeGroupSnapshot
metadata:
  name: selective-database-snapshot
  namespace: default
spec:
  volumeGroupSnapshotClassName: csi-hostpath-group-snapclass
  source:
    persistentVolumeClaims:
    - name: database-data-pvc
    - name: database-logs-pvc
```

### Restore from Group Snapshot

```yaml
# restore-from-group-snapshot.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-data-pvc-restored
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
  dataSource:
    name: database-group-snapshot  # Name of the group snapshot
    kind: VolumeGroupSnapshot
    apiGroup: groupsnapshot.storage.k8s.io/v1
    volumeGroupSnapshotName: database-group-snapshot
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-logs-pvc-restored
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
  dataSource:
    name: database-group-snapshot
    kind: VolumeGroupSnapshot
    apiGroup: groupsnapshot.storage.k8s.io/v1
    volumeGroupSnapshotName: database-group-snapshot
```

## 🔍 Verification and Monitoring

### Check Group Snapshot Status

```bash
# List all group snapshots
kubectl get volumegroupsnapshots

# Get detailed information
kubectl describe volumegroupsnapshot database-group-snapshot

# Check snapshot contents
kubectl get volumegroupsnapshotcontents
```

### Monitor Snapshot Progress

```bash
# Watch snapshot creation progress
watch kubectl get volumegroupsnapshots -o wide

# Check individual volume snapshots created
kubectl get volumesnapshots -l groupsnapshot.storage.k8s.io/volumegroupsnapshotname=database-group-snapshot
```

### Validate Snapshot Consistency

```bash
# Verify all volumes are included
kubectl describe volumegroupsnapshot database-group-snapshot | grep "Volume Snapshot Reference"

# Check creation timestamps (should be identical)
kubectl get volumesnapshots -l groupsnapshot.storage.k8s.io/volumegroupsnapshotname=database-group-snapshot -o custom-columns=NAME:.metadata.name,CREATION:.metadata.creationTimestamp
```

## 📈 Use Case Examples

### Multi-Database Cluster

```yaml
# Multi-database cluster group snapshot
apiVersion: groupsnapshot.storage.k8s.io/v1
kind: VolumeGroupSnapshot
metadata:
  name: cluster-database-snapshot
  namespace: production
spec:
  volumeGroupSnapshotClassName: enterprise-storage-snapclass
  source:
    selector:
      matchLabels:
        component: database
        environment: production
```

### Application Stack Backup

```yaml
# Full application stack (database + cache + files)
apiVersion: groupsnapshot.storage.k8s.io/v1
kind: VolumeGroupSnapshot
metadata:
  name: appstack-backup
  namespace: ecommerce
spec:
  volumeGroupSnapshotClassName: premium-snapclass
  source:
    selector:
      matchLabels:
        app.kubernetes.io/part-of: ecommerce-platform
```

## ⚠️ Important Notes

- All volumes in the group must be managed by the same CSI driver
- Snapshot creation time depends on the total size of all volumes
- Group snapshots are crash-consistent, not application-consistent
- Consider quiescing applications before snapshot for data consistency

## 🛠️ Troubleshooting

### Common Issues

1. **Group Snapshot Fails to Create**
   ```bash
   # Check if CSI driver supports group snapshots
   kubectl get csidriver
   kubectl describe csidriver <driver-name>
   ```

2. **Some Volumes Not Included**
   ```bash
   # Verify volume labels match selector
   kubectl get pvc --show-labels
   
   # Check if volumes are bound
   kubectl get pvc -o wide
   ```

3. **Restore Fails**
   ```bash
   # Check if snapshot class exists
   kubectl get volumegroupsnapshotclass
   
   # Verify storage class compatibility
   kubectl describe volumegroupsnapshot <snapshot-name>
   ```

## 📚 Additional Resources

- [KEP #3476: Volume Group Snapshots](https://kep.k8s.io/3476)
- [CSI Group Snapshot Documentation](https://kubernetes-csi.github.io/docs/group-snapshot-restore-feature.html)
- [Volume Snapshot Documentation](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)

---

**Volume Group Snapshots provide enterprise-grade backup capabilities for multi-volume applications, ensuring data consistency across all storage layers.**
