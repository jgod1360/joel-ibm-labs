#!/usr/bin/env bash

COGNOS_PROJECT=cognos
CP4D_PROJECT="cp4d"
OC_MARKETPLACE="openshift-marketplace"
COMM_SRVC_PROJECT="ibm-common-services"
APPROVAL_TYPE="Automatic"

export IBM_ENTITLEMENT_KEY="eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJQk0gTWFya2V0cGxhY2UiLCJpYXQiOjE2NjE3Mzg0NjksImp0aSI6ImM2Njg5NjM4MzRmZjQzZjVhYzliMjc4MzlkOGYyZDAzIn0.Rorixjs0LRdvTBi0AcfCM0t2eBxqGwOEwg6HPtz3N1g"
export IBM_ENTITLEMENT_USER=cp
export IBM_ENTITLEMENT_SERVER=cp.icr.io

echo

#if $(mkdir ./temp) == "mkdir: temp: File exists":
#then
#  echo "already exists ..."
#fi
#
#
#
#echo "Creating an environment variable that points to a temporary directory on your workstation ..."
#export WORK_ROOT=$HOME/temp/work
#echo
#
#echo "Downloading the pull secret to the temporary directory"
#oc get secret/pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}' > ${WORK_ROOT}/global_pull_secret.cfg
#echo
#
#echo "Adding the new pull secret to the local copy of the global_pull_secret.cfg file ..."
#oc registry login --registry="${IBM_ENTITLEMENT_SERVER}" --auth-basic="${IBM_ENTITLEMENT_USER}:${IBM_ENTITLEMENT_KEY}" --to=${WORK_ROOT}/global_pull_secret.cfg
#echo
#
#echo "Updating the global pull secret on your cluster ..."
#oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=${WORK_ROOT}/global_pull_secret.cfg
#echo
#
#echo "Getting the status of the nodes ..."
#oc get nodes
#echo
#
#echo "Confirming that the environment variable is set ..."
#echo "${PRIVATE_REGISTRY_LOCATION}"
#echo
#
#echo "Creating and image content source policy ..."
#cat <<EOF |oc apply -f -
#apiVersion: operator.openshift.io/v1alpha1
#kind: ImageContentSourcePolicy
#metadata:
#  name: cloud-pak-for-data-mirror
#spec:
#  repositoryDigestMirrors:
#  - mirrors:
#    - ${PRIVATE_REGISTRY_LOCATION}/cpopen/cpfs
#    source: icr.io/cpopen/cpfs
#  - mirrors:
#    - ${PRIVATE_REGISTRY_LOCATION}/cp
#    source: cp.icr.io/cp
#  - mirrors:
#    - ${PRIVATE_REGISTRY_LOCATION}/cp/cpd
#    source: cp.icr.io/cp/cpd
#  - mirrors:
#    - ${PRIVATE_REGISTRY_LOCATION}/cpopen
#    source: icr.io/cpopen
#  - mirrors:
#    - ${PRIVATE_REGISTRY_LOCATION}/db2u
#    source: icr.io/db2u
#  - mirrors:
#    - ${PRIVATE_REGISTRY_LOCATION}/guardium-insights
#    source: icr.io/guardium-insights
#EOF
#echo
#
#echo "Verifying that the image content source policy was created ..."
#oc get imageContentSourcePolicy
#echo
#
#echo "Getting the status of the nodes ..."
#oc get nodes
#echo

#echo "Install Cloud Pak for Data ..."
#
#cd ./../cp4d
#./install_cp4d.sh

#echo "Creating Cognos project: ${COGNOS_PROJECT} ..."
#oc new-project ${COGNOS_PROJECT}
#echo
#echo

cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-operator-catalog
  namespace: ${OC_MARKETPLACE}
spec:
  displayName: "IBM Operator Catalog"
  publisher: IBM
  sourceType: grpc
  image: icr.io/cpopen/ibm-operator-catalog:latest
  updateStrategy:
    registryPoll:
      interval: 45m
EOF

echo

##  installPlanApproval: Automatic

echo "Verify the IBM Operator Catalog was successfully created:"
oc get catalogsource -n ${CP4D_PROJECT}
echo

echo "Verify that ibm-operator-catalog is READY: "
oc get catalogsource -n ${CP4D_PROJECT} ibm-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}'
echo

echo "Creating a CAService custom resource to install Cognos Analytic ..."
cat <<EOF |oc apply -f -
apiVersion: "ca.cpd.ibm.com/v1"
kind: "CAService"
metadata:
  name: "ca-addon-cr"
  namespace: ${CP4D_PROJECT}
spec:
  installPlanApproval: Automatic
  license:
    accept: true
    license: Enterprise
  storage_class: "ibmc-block-retain-gold"
  namespace: ${CP4D_PROJECT}
  version: "4.5.3"
EOF

sleep 50

ca_srvc_result=$(oc get CAService ca-addon-cr -o jsonpath='{.status.caAddonStatus} {"\n"}')
checking=true
echo "Getting the status of Cognos Analytics (ca-addon-cr):"
while [[ $checking ]]
do
  if [[ $ca_srvc_result == "READY" ]]
  then
    echo "Cognos Analytics (ca-addon-cr) is READY"
    echo "${ca_srvc_result}"
    checking=false
  else
    echo "$ca_srvc_result"
    sleep 20
    continue
  fi
done

#
#apiVersion: ca.cpd.ibm.com/v1
#kind: CAService
#metadata:
# name: ca-addon-cr
# namespace: ${CP4D_PROJECT}
#spec:
# version: "4.0.5"
# license:
#   accept: true
#   license: "Enterprise"
# storage_class: ibmc-block-retain-gold
# namespace: "${OC_MARKETPLACE}"

#echo
#
#echo "Verifying the installation ..."
#echo "Changing to ${CP4D_PROJECT} project ..."
#oc project ${CP4D_PROJECT}
#echo
#echo


#oc get CAService ca-addon-cr -o jsonpath='{.status.caAddonStatus} {"\n"}'

#
#echo "Creating the Cognos Operator Subscription ..."
#cat <<EOF |oc apply -f -
#apiVersion: operators.coreos.com/v1alpha1
#kind: Subscription
#metadata:
#  name: ibm-ca-operator-catalog-subscription
#  labels:
#    app.kubernetes.io/instance: ibm-ca-operator
#    app.kubernetes.io/managed-by: ibm-ca-operator
#    app.kubernetes.io/name: ibm-ca-operator
#  namespace: ${COGNOS_PROJECT}
#spec:
#  channel: v4.0
#  name: ibm-ca-operator
#  installPlanApproval: Automatic
#  source: ibm-operator-catalog
#  sourceNamespace: ${COMM_SRVC_PROJECT}
#EOF
#
#echo
#echo
#
#echo "Validating that the operator was successfully created ..."
#oc get sub -n ${CP4D_PROJECT} ibm-ca-operator-catalog-subscription -o jsonpath='{.status.installedCSV} {"\n"}'
#echo
#echo
#
#echo "Confirming that the cluster service version (CSV) is ready:"
#oc get csv -n ${CP4D_PROJECT} ibm-ca-operator.v4.0.8 -o jsonpath='{ .status.phase } : { .status.message} {"\n"}'
#echo
#echo
#
#echo "Confirming that the operator is ready ..."
#oc get deployments -n ${CP4D_PROJECT} -l olm.owner="ibm-ca-operator.v4.0.8" -o jsonpath="{.items[0].status.availableReplicas} {'\n'}"
#echo
#echo
#
#




#echo "Creating the IBM Db2U Catalog ..."
#cat <<EOF |oc apply -f -
#apiVersion: operators.coreos.com/v1alpha1
#kind: CatalogSource
#metadata:
#  name: ibm-db2uoperator-catalog
#  namespace: ${CP4D_PROJECT}
#spec:
#  sourceType: grpc
#  image: icr.io/cpopen/ibm-db2uoperator-catalog:latest
#  installPlanApproval: Automatic
#  imagePullPolicy: Always
#  displayName: IBM Db2U Catalog
#  publisher: IBM
#  updateStrategy:
#    registryPoll:
#      interval: 45m
#EOF
#
#echo
#echo


