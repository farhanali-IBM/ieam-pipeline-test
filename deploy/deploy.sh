#!/bin/bash

DEPLOY_DIR="/ocp-tools/ieam-edge-cluster-demo/deploy"
. ~/env.sh

APP_IMAGE_BASE=$1
IMAGE_VERSION=$2
APP_IMAGE=$APP_IMAGE_BASE:$IMAGE_VERSION
OPERATOR_IMAGE_BASE="docker.io/appimage/ieam-edge-operator"
OPERATOR_IMAGE=$OPERATOR_IMAGE_BASE:$IMAGE_VERSION

cd $DEPLOY_DIR && git stash && git pull
cd config/manager && kustomize edit set image controller="$OPERATOR_IMAGE" && cd ../..
sed -i -e "s|{{APP_IMAGE_BASE}}|$APP_IMAGE_BASE|" config/samples/demo.yaml
sed -i -e "s|{{IMAGE_VERSION}}|$IMAGE_VERSION|" config/samples/demo.yaml

# Update Version in horizon/hzn.json if you make ANY change
mv horizon/hzn.json /tmp/hzn.json
jq --arg IMAGE_VERSION "$IMAGE_VERSION" '.MetadataVars.SERVICE_VERSION |= $IMAGE_VERSION' /tmp/hzn.json > horizon/hzn.json

make docker-build docker-push IMG=$OPERATOR_IMAGE

rm operator.tar.gz & rm -rf deploy && mkdir -p deploy
kustomize build config/default > deploy/kustomize_manifests_operator.yaml
tar -C deploy -czf operator.tar.gz . && rm -rf deploy

hzn exchange service publish -f $DEPLOY_DIR/horizon/service.definition.json --overwrite
HZN_POLICY_NAME="ceorg/policy-store-customer-offers"
hzn exchange deployment removepolicy -f $HZN_POLICY_NAME
sleep 10
hzn exchange deployment addpolicy -f $DEPLOY_DIR/horizon/service.policy.json $HZN_POLICY_NAME
# hzn exchange deployment updatepolicy -f $DEPLOY_DIR/horizon/service.policy.json $HZN_POLICY_NAME

