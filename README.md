# Purpose
Simple docker based heartbeat. Calling REST service (alive) will restart the timer. Once the timer has terminated (the timer has no more been restarted) then send an email to the specified sender (using the supplied credentials). Currently only gmail is supported.

# Developement workflow
Push feature branch to github. CircleCI gets trigger, compiles and executes all tests. After merging the branch to master, CircleCI will compile, execute tests and if all went ok, creates a new docker image and deploys it to GKE (Google Cloud / Kubernetes Engine).

# Configuration
## CircleCI
Set these environment variables:

Key | Description
---|---
GCLOUD_SERVICE_KEY | JSON string containing the GKE credentials, used to login to GKE from CircleCI.
GOOGLE_CLUSTER_NAME | [See GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/managing-clusters)
GOOGLE_COMPUTE_ZONE | [See GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/managing-clusters)
GOOGLE_PROJECT_ID | [See GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/managing-clusters)
PROJECT_NAME | Name of the project. Will be used for the docker image name, GKE container name.

## GKE
Configuration attributes for Google Kubernetes Engine.
Key | Description
--- | ---
HEALTH_CHECK_TIME | How long should the app wait until it sends a 'not alive' message.
EMAIL_SENDER | GMail sender adress
EMAIL_SENDER_PASSWORD | GMail  sender password
SMTP_SERVER | Gmail sender server
EMAIL_RECEIVER | Receiver adress
* Remark: only GMail suported at the momemnt

## Docker
the 'Dockerfile' uses the image 'dalaymabboux/haskellnet' to build the app (uses [multistage build](https://docs.docker.com/develop/develop-images/multistage-build/)).
The 'dalaymabboux/haskellnet' image contains all the necessary modules already, so once this image is installed the 'Dockerfile' doesn't need to install them anymore (faster)

# Build docker images by hand
## Build base docker image "dalaymabboux/haskellnet"
```shell
docker build -t dalaymabboux/haskellnet:v1.0 -f HaskellNet_Dockerfile .
docker push dalaymabboux/haskellnet:v1.0
docker build -t gcr.io/warms-watchdog/warms-watchdog:v1.0 .
```
## Setup environment variables
Create a file named gke_secret.env and add these attributes:

```
SMTP_SERVER=your smtp server
EMAIL_SENDER=the sender email adress
EMAIL_SENDER_PASSWORD=the sender email password
EMAIL_RECEIVER=the receiver email adress
```
### Run the docker image locally
```
docker run --env-file gke_secret.env -p 3000:3000 gcr.io/warms-watchdog/warms-watchdog:v1.0
```

# GKE commands
Set secrets:
> kubectl create secret generic warms-credentials --from-env-file gke_secret.env

Connect to cluster:
> gcloud container clusters get-credentials standard-cluster-1 --zone europe-west1-b
> gcloud auth application-default login

Delete the currently deployed version
> kubectl delete -f deployment.yml

Push to Google registry:
> gcloud docker -- push gcr.io/warms-watchdog/warms-watchdog:v1.0

Deploy it:
> kubectl create -f deployment.yml --save-config

Check log:
> kubectl get pods
> kubectl logs -f <pod-id>
