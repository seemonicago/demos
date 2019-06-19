##About Velero

https://velero.io/docs/v1.0.0/about/

 - What is it?
 - How does it work?
 - What are the limitations?

##Demo

###Prerequisites

 * wget
 * kubectl
 * virtualbox (or other hypervisor)
 * minikube

####Create minikube clusters

> Note: Two separate minikube clusters are required.
> Use the profile option to name each cluster uniquely.
> For this demo, the clusters are named 'earth' and 'mars'

`minikube start -p earth`
`minikube start -p mars`

Enable ingress on the 'earth' cluster
`minikube addons enable ingress -p earth`

###Installation

On the 'earth' cluster, install velero locally using minikube.

`kubectl config use-context earth`

####Install Minio

Create credentials file

```
cat >credentials-velero <<EOL
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123
EOL
```

Get the minio deployment yaml
```
wget https://raw.githubusercontent.com/heptio/velero/master/examples/minio/00-minio-deployment.yaml
```

Change ClusterIP to NodePort
```
sed -i '' -e 's/ClusterIP/NodePort/' 00-minio-deployment.yaml
```

Create deployment
`kubectl apply -f 00-minio-deployment.yaml` 

Get publicURL
```
export PUBLIC_URL=$(minikube service minio --namespace=velero --url -p earth)
```

Verify publicURL
```echo $PUBLIC_URL```

Open minio in browser


####Install Velero

Run install command

```
velero install \
    --provider aws \
    --bucket velero \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc:9000,publicUrl=$PUBLIC_URL
```

> Note: Check for the publicUrl in config spec
> `kubectl edit backupstoragelocation default -n velero` 

 Verify deployment

```
kubectl get deployment -n velero
kubectl get pods -n velero
velero get backups
velero get restores
velero help
```

###Single Cluster Backup & Restore

####Deploy an app

Create deployment
`kubectl create -f base.yaml`

Verify deployment
```
kubectl get ns
kubectl get deployments -n nginx-example
kubectl get svc -n nginx-example
````

Create backup
`velero backup create nginx-backup --selector app=nginx`

View backup
`velero describe backup nginx-backup`

Create scheduled backup
`velero schedule create nginx-daily --schedule="0 1 * * *" --selector app=nginx`

Verify backup and scheduled backup
`velero get backups`
`velero get schedules`

Delete namespace
`kubectl delete ns nginx-example`

Verify deletion
```
kubectl get deployments --namespace=nginx-example
kubectl get services --namespace=nginx-example
kubectl get namespace/nginx-example
```

Restore from backup
`velero create restore --from-backup nginx-backup` 

Verify restore created
`velero get restores`

Verify deployment has been restored
```
kubectl get deployments --namespace=nginx-example
kubectl get services --namespace=nginx-example
kubectl get namespace/nginx-example
```

### Cluster migration

Set context to 'mars' cluster
`kubectl config use-context mars`

Show current namespaces to validate no velero or nginx-backup
```
velero get backups
kubectl get ns
```

Install velero (without minio)
```
velero install \
    --provider aws \
    --bucket velero \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=$PUBLIC_URL
```

View backups
`velero get backups`

Create restore from backup in 'earth' cluster
`velero restore create --from-backup nginx-backup`

Verify resources
```
kubectl get ns
kubectl get deploy -n nginx-example
kubectl get svc -n nginx-example
```
