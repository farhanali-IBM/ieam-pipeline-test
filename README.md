# ieam-edge-cluster-demo
- [ieam-edge-cluster-demo](#ieam-edge-cluster-demo)
  - [Pre-Requisites](#pre-requisites)
  - [Setting up Linux VM](#setting-up-linux-vm)
  - [Installing OpenShift Pipelines](#installing-openshift-pipelines)
  - [Setting up Namespace](#setting-up-namespace)
  - [Creating the Pipeline](#creating-the-pipeline)
  - [Adding Webhook to Git Repository](#adding-webhook-to-git-repository)

## Pre-Requisites
1. IBM Edge Application Manager Hub (`v4.5`) w/ IEAM Agent installed on a Cluster
2. OpenShift Cluster v4.10+
3. Linux VM with ssh access and the following tools installed:
   1. [Docker](https://docs.docker.com/engine/install/)
   2. [Horizon CLI](https://www.ibm.com/docs/en/eam/4.5?topic=cli-installing-hzn)
   3. [jq](https://jqlang.github.io/jq/download/)
   4. [git](https://git-scm.com/download/)
   5. [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)
4. Fork the [IEAM Edge Cluster Demo](https://github.com/Client-Engineering-Industry-Squad-1/ieam-edge-cluster-demo) repository
5. Public container image repository
   * The demo uses DockerHub

## Setting up Linux VM
* Clone your forked Git repository of IEAM Edge Cluster Demo in the Linux VM using SSH
  * `git clone <YOUR_FORKED_IEAM_EDGE_CLUSTER_DEMO_REPO`
* Create a `env.sh` file in user home (`~`) directory based on the `example-env.sh` file in this project
  * Make sure your `agent-install.crt` file is saved in the VM and set the variable `HZN_MGMT_HUB_CERT_PATH` to the file path of the crt
* Ensure user can run commands without sudo
  * Run `docker ps`
    * If you get a `Got permission denied while trying to connect to the Docker daemon socket...` error, then follow instructions in this [document](https://docs.docker.com/engine/install/linux-postinstall/)
* Log into the image registry where you will be pushing your operator and app images
  * `docker login <YOUR_IMAGE_REGISTRY> -u <USERNAME>`

## Installing OpenShift Pipelines
* Install OpenShift Pipelines using the Operator by following the [official documentation](https://docs.openshift.com/container-platform/4.11/cicd/pipelines/installing-pipelines.html#op-installing-pipelines-operator-in-web-console_installing-pipelines)

## Setting up Namespace
1. Create a namespace called `ieam-demo`
2. Create an image pull Secret called `docker-registry` for the container registry where the application and operator image will be pulled

## Creating the Pipeline
1. Log into the OpenShift cluster where OpenShift Pipelines is installed
2. Create a namespace called `openshift-pipelines`. We will be using this namespace for all other steps.
3. Create an image pull Secret called `docker-registry` where the application and operator image will be uploaded
  * Should be the same login info created in [Setting up Namespace](#setting-up-namespace)
4. Add the secret to the `pipeline` Service Account
5. Create a key/value secret called `remote-ssh-secret` to connect to the Linux VM
   * The key is `privatekey` and the value is your private key content (i.e. Starts with `-----BEGIN RSA PRIVATE KEY-----`)
6. Log into your cluster via oc cli
7. Switch to `openshift-pipelines` namespace
    * `oc project openshift-pipelines`
8. Create pvc for the workspace
   1. Update the `storageClassName` in `pipeline/pvc.yaml`
   2. `oc apply -f pipeline/pvc.yaml`
9. Create task for remote-ssh
    * `oc apply -f pipeline/task.yaml`
10. Create pipeline
    1. Update the default values for the following in `pipeline/pipeline.yaml`
      1. `fetch-repository` task:
        * `GIT_REPO` -> URL to the forked Github repo
        * `IMAGE_BASE` -> Container registry image path to the app
      2. `publish-service` task:
        * `HOST` -> Host of Linux VM
        * `USERNAME` -> User to login with
        * `PORT` -> SSH port
    2. `oc apply -f pipeline/pipeline.yaml`
11. Create trigger
    1. Update the default values for the following in `pipeline/trigger.yaml` under `TriggerTemplate`
        * `GIT_REPO` -> URL to the forked Github repo
        * `IMAGE_BASE` -> Container registry image path to the app
    2. `oc apply -f pipeline/trigger.yaml`

## Adding Webhook to Git Repository
1. Log into OpenShift and in the left Navigation Panel, expand `Pipelines` and click on `Triggers`
2. Click on the `EventListeners` tab
3. Choose the `event-listener-ieam-edge-pipeline`
4. Copy the `URL` link shown on the screen
5. Log into Github and navigate to your forked repository
6. Click on the `Settings` tab -> `Webhooks`
7. Click on the `Add webhook` button and enter the following in the form:
   * `Payload URL`: Paste the `URL` link obtained from the EventListener
   * `Content type`: `application/json`
   * Select `Let me select individual events.` option and make sure only `Releases` is selected
8. Save the form by clicking on `Add webhook` button at the bottom
9. To trigger the pipeline, create a new release in Github
   * **NOTE**: Whatever `tag` you choose, will be the tag for the app and operator container image which will be referenced in your Container Registry# ieam-walgreens
# ieam-walgreens
# ieam-pipeline-test
