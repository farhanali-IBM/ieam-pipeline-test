#!/bin/bash

DEPLOY_DIR="/home/ieam-1/nginx-app/texas/ieam-pipeline-test/deploy"
. ~/env.sh

APP_IMAGE_BASE=$1
IMAGE_VERSION=$2
APP_IMAGE=$APP_IMAGE_BASE:$IMAGE_VERSION
OPERATOR_IMAGE_BASE="farhanali89/operator"
OPERATOR_IMAGE=$OPERATOR_IMAGE_BASE:$IMAGE_VERSION
OPERATOR_BRANCH="texas"
POLICY_CONSTRAINTS="state == $OPERATOR_BRANCH"
HZN_POLICY_NAME="ieam-org/policy-nginx-operator"

cd $DEPLOY_DIR && git stash && git pull origin $OPERATOR_BRANCH
cd config/manager && kustomize edit set image controller="$OPERATOR_IMAGE" && cd ../..
sed -i -e "s|{{APP_IMAGE_BASE}}|$APP_IMAGE_BASE|" config/samples/demo.yaml
sed -i -e "s|{{IMAGE_VERSION}}|$IMAGE_VERSION|" config/samples/demo.yaml

echo "print all variables to screen....." 
echo "Image version = $IMAGE_VERSION"
echo "Horizon Deployment Policy Name = $HZN_POLICY_NAME"
echo "Branch = $OPERATOR_BRANCH"


oc login --token=sha256~HOWAg09F0OoFh2l0O6fR072P-o41FRa3KgnzOnzuTIw --server=https://c118-e.us-south.containers.cloud.ibm.com:32473

#update node properties
kubectl exec -it agent-58c84d66d4-jjb65 -- curl -X POST -H "Content-Type: application/json" -d '{"properties": [ {"name": "state", "value": "texas" } ]}' http://localhost:8510/node/policy


# Update Version in horizon/hzn.json if you make ANY change
mv horizon/hzn.json /tmp/hzn.json
jq --arg IMAGE_VERSION "$IMAGE_VERSION" '.MetadataVars.SERVICE_VERSION |= $IMAGE_VERSION' /tmp/hzn.json > horizon/hzn.json

# Update service.policy.json policy contraints
mv ./horizon/service.policy.json /tmp/service.policy.json
jq --arg Policy_constraints "$POLICY_CONSTRAINTS" '.constraints[0] |= $Policy_constraints' /tmp/service.policy.json > horizon/service.policy.json

#add image version variable to env.sh and update deploy.yaml template
echo "export IMAGE_VERSION=$IMAGE_VERSION\n" >> ~/env.sh
echo "running make source..."
make source


#build operator
make docker-build docker-push IMG=$OPERATOR_IMAGE

#create CRD file and zip it for ieam
rm operator.tar.gz & rm -rf deploy && mkdir -p deploy
kustomize build config/default > deploy/kustomize_manifests_operator.yaml
tar -C deploy -czf operator.tar.gz . && rm -rf deploy

#deploy ieam service
hzn exchange service publish -f $DEPLOY_DIR/horizon/service.definition.json --overwrite

#remove existing deployment policy 
hzn exchange deployment removepolicy -f $HZN_POLICY_NAME
sleep 10

#deploy new deployment policy
hzn exchange deployment addpolicy -f $DEPLOY_DIR/horizon/service.policy.json $HZN_POLICY_NAME
# hzn exchange deployment updatepolicy -f $DEPLOY_DIR/horizon/service.policy.json $HZN_POLICY_NAME

git add --all && git commit -m "updating repo" && git push -u origin $OPERATOR_BRANCH
oc logout
