#!/bin/bash

# ibm-common-services
PROJECT_CATSRC=openshift-marketplace
CP4D_PROJECT=cp4d
COGNOS_PROJECT=cognos

#cat <<EOF |oc apply -f -
#apiVersion: operators.coreos.com/v1alpha1
#kind: Subscription
#metadata:
#  annotations:
#  name: ibm-cpd-ws-operator-catalog-subscription
#  namespace: cp4d
#spec:
#  channel: v2.0
#  installPlanApproval: Automatic
#  name: ibm-cpd-wsl
#  source: ibm-operator-catalog
#  sourceNamespace: openshift-marketplace
#EOF

# ibm-operator-catalog

cat <<EOF | oc apply -f -
apiVersion: ca.cpd.ibm.com/v1
kind: CAService
metadata:
  name: ca-addon-cr
  namespace: ${COGNOS_PROJECT}
spec:
  version: 4.0.8
  license:
    accept: true
    license: "Enterprise"
  namespace: ${COGNOS_PROJECT}
  storage_class: ibmc-block-retain-gold
EOF

#cat <<EOF |oc apply -f -
#apiVersion: operators.coreos.com/v1alpha1
#kind: CatalogSource
#metadata:
#  name: ibm-ca-operator-catalog
#  namespace: ${PROJECT_CATSRC}
#spec:
#  displayName: "IBM Operator Catalog"
#  publisher: IBM
#  sourceType: grpc
#  image: icr.io/cpopen/ibm-operator-catalog:latest
#  updateStrategy:
#    registryPoll:
#      interval: 45m
#EOF
#
#echo
#echo
#
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
#  source: ibm-ca-operator-catalog
#  sourceNamespace: ${PROJECT_CATSRC}
#EOF