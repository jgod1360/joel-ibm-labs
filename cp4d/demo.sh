#!/usr/bin/env bash

CP4D_PROJECT="cp4d"
OC_MARKETPLACE="openshift-marketplace"

echo "Creating an operator subscription for the scheduling service"
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-cpd-scheduling-catalog-subscription
  namespace: ${OC_MARKETPLACE}
spec:
  channel: v1.3
  installPlanApproval: ${APPROVAL_TYPE}
  name: ibm-cpd-scheduling-operator
  source: ibm-operator-catalog
  sourceNamespace: ${OC_MARKETPLACE}
EOF

echo "Creating the Operation Subscription ..."
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-cpd-datastage-operator-subscription
  namespace: ${CP4D_PROJECT}
spec:
  channel: v1.0
  installPlanApproval: Automatic
  name: ibm-cpd-datastage-operator
  source: ibm-operator-catalog
  sourceNamespace: ${OC_MARKETPLACE}
EOF
echo

echo "Valid that the operator was successfully installed ..."
oc get sub -n ${CP4D_PROJECT} ibm-cpd-datastage-operator-subscription -o jsonpath='{.status.installedCSV} {"\n"}'
echo


echo "Run the following command to confirm that the cluster service version (CSV) is ready ..."
oc get csv -n ${CP4D_PROJECT} ibm-cpd-datastage-operator -o jsonpath='{ .status.phase } : { .status.message} {"\n"}'
echo


echo "Run the following command to confirm that the operator is ready ..."
oc get deployments -n ${CP4D_PROJECT} -l olm.owner="ibm-cpd-datastage-operator.v1.0.7" -o jsonpath="{.items[0].status.availableReplicas} {'\n'}"
echo

echo "Creating a DataStage custom resource to install DataStage ..."
cat <<EOF | oc apply -f -
apiVersion: ds.cpd.ibm.com/v1alpha1
kind: DataStage
metadata:
  name: datastage
  namespace: ${CP4D_PROJECT}
spec:
  license:
    accept: true
    license: Standard
  version: 4.0.9
  storageClass: ibmc-file-gold-gid
EOF
echo

echo "Changing to the project ${CP4D_PROJECT} ..."
oc project ${CP4D_PROJECT}
echo

echo "Get the status of DataStage (datastage):"
oc get DataStage datastage -o jsonpath='{.status.dsStatus} {"\n"}'
echo

echo "Get the status of the PXRuntime instance (ds-px-default):"
oc get pxruntime ds-px-default -o jsonpath='{.status.dsStatus} {"\n"}'
