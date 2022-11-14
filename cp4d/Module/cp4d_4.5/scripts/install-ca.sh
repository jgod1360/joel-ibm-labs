#!/bin/bash

# Install ca operator 
oc project "${COMM_SRVC_PROJECT}"

echo
 New Cognos Analytics installation start from here.
echo "Creating the Cognos Analytic Operator catalog subscription ..."
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-ca-operator-catalog-subscription
  labels:
    app.kubernetes.io/instance: ibm-ca-operator
    app.kubernetes.io/managed-by: ibm-ca-operator
    app.kubernetes.io/name: ibm-ca-operator
  namespace: ${COMM_SRVC_PROJECT}
spec:
  channel: v4.0
  name: ibm-ca-operator
  installPlanApproval: Automatic
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF

#sleep 1m

echo

echo "Creating the Cognos Analytic Service ..."
cat << EOF | oc apply -f -
apiVersion: ca.cpd.ibm.com/v1
kind: CAService
metadata:
 name: ca-addon-cr
 labels:
  app.kubernetes.io/instance: ibm-ca-operator
  app.kubernetes.io/managed-by: ibm-ca-operator
  app.kubernetes.io/name: ibm-ca-operator
 namespace: ${CP4D_PROJECT}
spec:
 license:
  accept: true
 storage_class: "ibmc-file-gold-gid"
 namespace: ${CP4D_PROJECT}
 version: 4.5.3
EOF

sleep 1m

echo


cd ../scripts

# check the CCS cr status
./check-cr-status.sh CAService ca-addon-cr "${CP4D_PROJECT}" caAddonStatus



#
#cd ../files
#
#sed -i -e "s/OPERATOR_NAMESPACE/${OP_NAMESPACE}/g" ca-sub.yaml # replace the namespace with "ibm-common-services"
#
#echo '*** executing **** oc create -f ca-sub.yaml'
#result=$(oc create -f ca-sub.yaml)
#echo $result
#sleep 1m
#
#cd ../scripts
## Checking if the ca operator pods are ready and running.
## checking status of ca-operator
#./pod-status-check.sh ca-operator ${OP_NAMESPACE}
#
## switch to zen namespace
#oc project ${NAMESPACE}
#
#cd ../files
#
## Create ca CR:
#
## ****** sed command for classic goes here *******
#if [[ ${ON_VPC} == false ]] ; then
#    sed -i -e "s/portworx-shared-gp3/ibmc-file-gold-gid/g" ca-cr.yaml
#else
#    sed -i -e "s/portworx-shared-gp3/${STORAGE}/g" ca-cr.yaml
#fi
#
#sed -i -e "s/REPLACE_NAMESPACE/${NAMESPACE}/g" ca-cr.yaml
#echo '*** executing **** oc create -f ca-cr.yaml'
#result=$(oc create -f ca-cr.yaml)
#echo $result
#
## check the CCS cr status
#./check-cr-status.sh CAService ca-addon-cr "${CP4D_PROJECT}" caAddonStatus