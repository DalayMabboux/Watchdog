# Watchdog

## CircleCi setup
* Set these environment variables
GCLOUD_SERVICE_KEY
GOOGLE_CLUSTER_NAME
GOOGLE_COMPUTE_ZONE
GOOGLE_PROJECT_ID
PROJECT_NAME

## Build base docker image "dalaymabboux/haskellnet"
```shell
docker build -t dalaymabboux/haskellnet:v1.0 -f HaskellNet_Dockerfile .
docker push dalaymabboux/haskellnet:v1.0
docker build -t gcr.io/warms-watchdog/warms-watchdog:v1.0 .
```

# Run docker
## Setup environment variables
Create a file named gke_secret.env and add these attributes:
SMPT_SERVER=
EMAIL_SENDER=
EMAIL_SENDER_PASSWORD=
EMAIL_RECEIVER=

## Run the docker image locally
docker run --env-file gke_secret.env   -p 3000:3000 gcr.io/warms-watchdog/warms-watchdog:v1.0

# GKE commands
Set secrets:
  kubectl create secret generic warms-credentials --from-file gke_secret.env

Build docker image locally:
  docker build -t gcr.io/warms-watchdog/warms-watchdog:v1.0 .

Connect to cluster:
  gcloud container clusters get-credentials standard-cluster-1 --zone europe-west1-b
  gcloud auth application-default login

If there is already a deployed version, delete it:
  kubectl delete -f  deployment.yml

Push to Google registry:
  gcloud docker -- push gcr.io/warms-watchdog/warms-watchdog:v1.0

Deploy it:
  kubectl create -f deployment.yml --save-config

Check log:
  kubectl get pods
  kubectl logs -f <pod-id>
