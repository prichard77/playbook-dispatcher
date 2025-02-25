#!/bin/bash
# --------------------------------------------
# Options that must be configured by app owner
# --------------------------------------------
APP_NAME="playbook-dispatcher"  # name of app-sre "application" folder this component lives in
COMPONENT_NAME="playbook-dispatcher"  # name of app-sre "resourceTemplate" in deploy.yaml for this component
IMAGE="quay.io/cloudservices/playbook-dispatcher"
IQE_CJI_TIMEOUT="30m"
REF_ENV="insights-stage"

# Install bonfire repository/initialize
CICD_URL=https://raw.githubusercontent.com/RedHatInsights/bonfire/master/cicd
curl -s $CICD_URL/bootstrap.sh > .cicd_bootstrap.sh && source .cicd_bootstrap.sh

# Build Playbook Dispatcher image based on the latest commit
source $CICD_ROOT/build.sh

# Execute unit tests
#source $APP_ROOT/unit_test.sh

# Deploy the new image to an ephemeral environment
source $CICD_ROOT/deploy_ephemeral_env.sh

# Run Playbook Dispatcher isolated tests
IQE_PLUGINS="playbook-dispatcher"
IQE_MARKER_EXPRESSION="smoke"
source $CICD_ROOT/cji_smoke_test.sh

# Re-deploy Playbook Dispatcher to an ephemeral environment, this time enabling the communication with Cloud Connector
bonfire deploy playbook-dispatcher cloud-connector \
    --source=appsre \
    --ref-env ${REF_ENV} \
    --set-template-ref ${COMPONENT_NAME}=${GIT_COMMIT} \
    --set-image-tag ${IMAGE}=${IMAGE_TAG} \
    --namespace ${NAMESPACE} \
    --timeout ${DEPLOY_TIMEOUT} \
    --set-parameter playbook-dispatcher/CLOUD_CONNECTOR_IMPL=impl

# Run RHC Contract integration tests
COMPONENT_NAME="cloud-connector"
IQE_PLUGINS="rhc-contract"
IQE_IMAGE_TAG="rhc-contract"
source $CICD_ROOT/cji_smoke_test.sh
