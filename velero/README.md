# Velero demo instructions

This is a walk-through of a local Kubernetes cluster backup and restore using [Velero](https://velero.io).

Tasks:  
a) Backup and restore within a single cluster  
b) Migration: Backup in one cluster and restore in a separate cluster.

This is based on Velero's [quick start guide](https://velero.io/docs/v1.0.0/get-started)

Time to complete: ~15 minutes (If prequisities have already been installed).

### References

[Velero Docs](https://velero.io/docs)

### Talking Points for presneting this at an event

 - What is Velero?
 - How does it work?
 - What are the benefits and limitations?

## Demo

> Note: These instructions are for OSX.

### Prerequisites

 * wget
 * [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
 * [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
 * [velero](https://velero.io/docs/v1.0.0/get-started/) (client) `brew install velero`

### Minikube Setup

Two separate minikube clusters are required.
Use the profile option to name each cluster uniquely.
For this demo, the clusters are named 'earth' and 'mars'

1. Create cluster "earth"
   `minikube start -p earth`

2. Create cluster "mars"
   `minikube start -p mars`

3. Enable ingress on cluster "earth"
  `minikube addons enable ingress -p earth`

> Note: To switch between clusters, use the following command:
  `kubectl config use-context ${PROFILE_NAME}`

### Install Minio
Velero requires an object store prior to installation.

1. Set `kubectl` to use cluster "earth"

   `kubectl config use-context earth`

2. Create credentials file
```
cat >credentials-velero <<EOL
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123
EOL
```

3. Get the minio deployment yaml
```
wget https://raw.githubusercontent.com/heptio/velero/master/examples/minio/00-minio-deployment.yaml
```

4. Change ClusterIP to NodePort
```
sed -i '' -e 's/ClusterIP/NodePort/' 00-minio-deployment.yaml
```

5. Create deployment
```
kubectl apply -f 00-minio-deployment.yaml
```

6. Get publicURL
```
export PUBLIC_URL=$(minikube service minio --namespace=velero --url -p earth)
```

7. Verify publicURL
```
echo $PUBLIC_URL
```

8. Open minio in browser using the URL is the previous step


### Install Velero
Now that minio is running, velero can be installed.

1. Run install command for cluster "earth"

```
velero install \
    --provider aws \
    --bucket velero \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc:9000,publicUrl=$PUBLIC_URL
```

> Note: Validate the publicUrl in config spec
> `kubectl edit backupstoragelocation default -n velero` 

2. Verify deployment

```
kubectl get deployment -n velero
kubectl get pods -n velero
velero get backups
velero get restores
velero help
```

### Demo 1: Single Cluster Backup & Restore
Deploy a basic nginx app with a few resources, create a backup, delete the deployment, and restore from backup.

#### Deploy an app

1. Retrieve the deployment yaml file

```
wget https://raw.githubusercontent.com/seemonicago/demos/master/velero/exploration.yaml
```

2. Create deployment
```
kubectl create -f exploration.yaml
```

3. Verify deployment
```
kubectl get ns
kubectl get deployments -n nasa
kubectl get svc -n nasa
````

4. Create backup
```
velero backup create curiosity-backup --selector rover=curiosity
```

5. View backup
```
velero describe backup curiosity-backup
```

6. Create scheduled backup
```
velero schedule create curiosity-daily --schedule="0 1 * * *" --selector rover=curiosity
```

7. Verify backup and scheduled backup
```
velero get backups
velero get schedules
```

8. Delete namespace
```
kubectl delete ns nasa
```

9. Verify deletion
```
kubectl get deployments --namespace=nasa
kubectl get services --namespace=nasa
kubectl get namespace/nasa
```

10. Restore from backup
```
velero create restore --from-backup curiosity-backup
```

11. Verify restore created
```
velero get restores
```

12. Verify deployment has been restored
```
kubectl get deployments --namespace=nasa
kubectl get services --namespace=nasa
kubectl get namespace/nasa
```
13. Show minio in browser


### Demo 2: Cluster Migration

Now, we'll demonstrate a cluster migration, or using a backup from one cluster to restore it to another cluster.
To do this, we need to deploy velero in the "mars" cluster points to minio in the "earth" cluster.
Note that there will be no minio object storage running in the "mars" cluster.

1. Set context to 'mars' cluster
```
kubectl config use-context mars
```

2. Show current namespaces to validate no velero or curiosity-backup
```
velero get backups
kubectl get ns
```

3. Install velero (without minio)
```
velero install \
    --provider aws \
    --bucket velero \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=$PUBLIC_URL
```

4. View backups
```
velero get backups
```

5. Create restore from backup in 'earth' cluster
```
velero restore create --from-backup curiosity-backup
```

6. Verify resources
```
kubectl get ns
kubectl get deploy -n nasa
kubectl get svc -n nasa
```

7. Cleanup

```
minikube stop -p earth
minikube stop -p mars
```
