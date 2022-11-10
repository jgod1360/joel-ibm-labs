#!/usr/bin/env bash

COGNOS_PROJECT=cognos
CP4D_PROJECT=cognos
PROJECT_CATSRC=openshift-marketplace

#echo "Creating Cognos project: ${COGNOS_PROJECT} ..."
#oc new-project ${COGNOS_PROJECT}
#echo
#echo


echo "*** Cognos Dashboards ***"
echo "Creating operator subscription for Cognos Dashboards ..."
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    app.kubernetes.io/instance: ibm-cde-operator-subscription
    app.kubernetes.io/managed-by: ibm-cde-operator
    app.kubernetes.io/name: ibm-cde-operator-subscription
  name: ibm-cde-operator-subscription
  namespace: ${CP4D_PROJECT}
spec:
  channel: v1.0
  installPlanApproval: Automatic
  name: ibm-cde-operator
  source: ibm-cde-operator-catalog
  sourceNamespace: ${PROJECT_CATSRC}
EOF
echo
echo

echo "Confirming that the subscription was triggered ..."
oc get sub -n ${CP4D_PROJECT} ibm-cde-operator-subscription -o jsonpath='{.status.installedCSV} {"\n"}'
echo
echo

echo "Confirming that the cluster service version (CSV) is ready:"
oc get csv -n ${CP4D_PROJECT} ibm-cpd-cde.v1.0.9 -o jsonpath='{ .status.phase } : { .status.message} {"\n"}'
echo
echo

echo "Confirming that the operator is ready ..."
oc get deployments -n ${CP4D_PROJECT} -l olm.owner="ibm-cpd-cde.v1.0.9" -o jsonpath="{.items[0].status.availableReplicas} {'\n'}"
echo
echo

echo "Changing to the project where you installed Cognos Analytics:"
oc project ${COGNOS_PROJECT}
echo
echo

echo "Getting the status of Cognos Analytics (ca-addon-cr):"
oc get CAService ca-addon-cr -o jsonpath='{.status.caAddonStatus} {"\n"}'