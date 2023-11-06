export HZN_EXCHANGE_URL=
export HZN_FSS_CSSURL=
export HZN_ORG_ID=
export HZN_EXCHANGE_USER_AUTH=
export HZN_DEVICE_ID=
## Update value below
export HZN_AGENT_PORT=
export AGENT_NAMESPACE=
export HZN_MGMT_HUB_CERT_PATH=

# https://sdk.operatorframework.io/docs/building-operators/ansible/quickstart/
operator-sdk init --domain example.com --plugins helm

operator-sdk create api --group demo --version v1alpha1 --kind Nginx

# TODO: Add "imagePullPolicy: Always" to config/manager/manager.yaml
# TODO: Can update replica count "spec:" in sample app in config/samples
# TODO: Update image in sample app in config/samples/
# TODO: Create a Route helm chart template and append config/rbac/role.yaml to with the following:
```
# Permission to create routes
- apiGroups:
  - route.openshift.io
  resources:
  - routes
  - routes/custom-host
  verbs:
  - get
  - list
  - watch
  - patch
  - update
  - create
  - delete
```

export OPERATOR_IMAGE_PATH=""
cd config/manager && kustomize edit set image controller="${OPERATOR_IMAGE_PATH}" && cd ../..

# TODO: Update Version in MakeFile if you update OPERATOR image version in yaml

# TODO: Update Version in horizon/hzn.json if you make ANY change

make docker-build docker-push

rm operator.tar.gz && rm -rf deploy
mkdir deploy
kustomize build config/default > deploy/kustomize_manifests_operator.yaml
tar -C deploy -czf operator.tar.gz .

hzn dev service new -V 1.0.0 -s sample-app -c cluster

# TODO: Update horizon/service.definition.json to "operatorYamlArchive": "../operator.tar.gz"
# TODO: Can update horizon/hzn.json "SERVICE_NAME"

# rm operator.tar.gz && tar -czf operator.tar deploy && gzip operator.tar 
hzn exchange service publish -f horizon/service.definition.json

# TODO: Update Version below
export HZN_POLICY_NAME=""
hzn exchange deployment addpolicy -f horizon/service.policy.json $HZN_POLICY_NAME
