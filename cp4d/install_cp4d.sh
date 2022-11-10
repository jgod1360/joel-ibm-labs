#!/usr/bin/env bash

CP4D_PROJECT="cp4d"
OC_MARKETPLACE="openshift-marketplace"
APPROVAL_TYPE="Automatic"
ENTITLEMENT_USER=""


#!/bin/bash


# Setup global_pull secret
./setup-global-pull-secret-bedrock.sh ${ENTITLEMENT_USER} ${ENTITLEMENT_KEY}

ibmcloud login --apikey ${IBMCLOUD_APIKEY} -g ${IBMCLOUD_RG_NAME} -r ${REGION}

# only call roks-update on vpc
if ${ON_VPC}; then
./roks-update.sh ${CLUSTER_NAME}
else # classic
./roks-reboot.sh ${CLUSTER_NAME}
fi

cd ../files

# # create bedrock catalog source

echo '*** executing **** oc create -f bedrock-catalog-source.yaml'

result=$(oc create -f ibm-op-catalog-source.yaml)
echo $result
sleep 1m

echo '*** executing **** oc create -f db2u-op-catalog.yaml'

result=$(oc create -f db2u-op-catalog.yaml)
echo $result

sleep 30

echo '*** executing **** oc create -f dmc-operator-catalog.yaml'
result=$(oc create -f dmc-operator-catalog.yaml)
echo $result
sleep 30

echo '*** executing **** oc create -f ccs-operator-catalog.yaml'
result=$(oc create -f ccs-operator-catalog.yaml)
echo $result
sleep 30

ATTEMPTS=0
TIMEOUT=360 # 1hr
while true; do
  if [ $ATTEMPTS -eq $TIMEOUT ] ; then
    echo "TIMED OUT: ibm-operator-catalog"
    exit 1
  fi
  if oc get catalogsource -n openshift-marketplace | grep ibm-operator-catalog >/dev/null 2>&1; then
    echo -e "IBM Operator Catalog was successfully created."
    break
  fi
  ATTEMPTS=$((ATTEMPTS + 1))
  sleep 10
done

ATTEMPTS=0
while true; do
  if [ $ATTEMPTS -eq $TIMEOUT ] ; then
    echo "TIMED OUT: ibm-db2uoperator-catalog"
    exit 1
  fi
  if oc get catalogsource -n openshift-marketplace | grep ibm-db2uoperator-catalog >/dev/null 2>&1; then
    echo -e "IBM Db2U Catalog was successfully created."
    break
  fi
  ATTEMPTS=$((ATTEMPTS + 1))
  sleep 10
done


# Creating the ibm-common-services namespace:

oc new-project ${OP_NAMESPACE}
oc project ${OP_NAMESPACE}

# Create bedrock operator group:

sed -i -e "s/OPERATOR_NAMESPACE/${OP_NAMESPACE}/g" bedrock-operator-group.yaml

echo '*** executing **** oc create -f bedrock-operator-group.yaml'


result=$(oc create -f bedrock-operator-group.yaml)
echo $result
sleep 1m


oc patch NamespaceScope common-service -n ibm-common-services --type=merge --patch='{"spec": {"csvInjector": {"enable": true} } }'


sed -i -e "s/OPERATOR_NAMESPACE/${OP_NAMESPACE}/g" cpd-operator-sub.yaml
echo '*** executing **** oc create -f cpd-operator-sub.yaml'
result=$(oc create -f cpd-operator-sub.yaml)
echo $result
sleep 60

# TODO: Fix hard-coded operator version.. stealth updates to the operator will break this.
ATTEMPTS=0
while true; do
  if [ $ATTEMPTS -eq $TIMEOUT ] ; then
    echo "TIMED OUT: cpd-platform-operator sub"
    exit 1
  fi
  if oc get sub -n ${OP_NAMESPACE} cpd-operator -o jsonpath='{.status.installedCSV} {"\n"}' | grep cpd-platform-operator >/dev/null 2>&1; then
    echo -e "\ncpd-platform-operator sub was successfully created."
    break
  fi
  ATTEMPTS=$((ATTEMPTS + 1))
  sleep 10
done

ATTEMPTS=0
while true; do
  if [ $ATTEMPTS -eq $TIMEOUT ] ; then
    echo "TIMED OUT: cpd-platform-operator csv"
    exit 1
  fi
  if oc get csv -n ${OP_NAMESPACE} | grep cpd-platform-operator | grep "Succeeded" >/dev/null 2>&1; then
    echo -e "\nInstall strategy completed with no errors"
    break
  fi
  ATTEMPTS=$((ATTEMPTS + 1))
  sleep 10
done

ATTEMPTS=0
while true; do
  if [ $ATTEMPTS -eq $TIMEOUT ] ; then
    echo "TIMED OUT: cpd-platform-operator deployments"
    exit 1
  fi
  if oc get deployments -n ${OP_NAMESPACE} | grep cpd-platform-operator-manager | grep 1/1 >/dev/null 2>&1; then
    echo -e "\ncpd-platform-operator deployments ready."
    break
  fi
  ATTEMPTS=$((ATTEMPTS + 1))
  sleep 10
done

ATTEMPTS=0
while true; do
  if [ $ATTEMPTS -eq $TIMEOUT ] ; then
    echo "TIMED OUT: ibm-namespace-scope-operator"
    exit 1
  fi
  if oc get pods -n ${OP_NAMESPACE} | grep ibm-namespace-scope-operator >/dev/null 2>&1; then
    echo -e "\nibm-namespace-scope-operator pods running"
    break
  fi
  ATTEMPTS=$((ATTEMPTS + 1))
  sleep 10
done

ATTEMPTS=0
while true; do
  if [ $ATTEMPTS -eq $TIMEOUT ] ; then
    echo "TIMED OUT: cpd-platform-operator-manager"
    exit 1
  fi
  if oc get pods -n ${OP_NAMESPACE} | grep cpd-platform-operator-manager >/dev/null 2>&1; then
    echo -e "\ncpd-platform-operator-manager pods running"
    break
  fi
  ATTEMPTS=$((ATTEMPTS + 1))
  sleep 10
done

ATTEMPTS=0
#for reinstall, namespace-scope configmap will be deleted when ibm-common-service-operator first running. need to delete this pod to force recreate Configmap namespace-scope.
while true; do
  if [ $ATTEMPTS -eq $TIMEOUT ] ; then
    echo "TIMED OUT: namespace-scope ibm-common-service-operator"
    exit 1
  fi
  # local cm_ns_status=$(oc get cm namespace-scope -n ibm-common-services)
  cm_ns_status=$(oc get cm namespace-scope -n $OP_NAMESPACE)
  if [[ -n $cm_ns_status ]]; then
    echo "Config Map namespace-scope exist."
    break
  fi
  ATTEMPTS=$((ATTEMPTS + 1))
  sleep 30
  oc get pods -n ${OP_NAMESPACE} -l name=ibm-common-service-operator | awk '{print $1}' | grep -Ev NAME | xargs oc delete pods -n $OP_NAMESPACE
  sleep 30
done

sleep 60

ATTEMPTS=0
echo "Waiting for Bedrock operator pods ready"
while true; do
  if [ $ATTEMPTS -eq $TIMEOUT ] ; then
    echo "TIMED OUT: Waiting for Bedrock operator pods"
    exit 1
  fi
  pod_status=$(oc get pods -n ${OP_NAMESPACE} | grep -Ev "NAME|1/1|2/2|3/3|5/5|Comp")
  if [[ -z $pod_status ]]; then
    echo "All pods are running now"
    break
  fi
  echo "Waiting for Bedrock operator pods ready"
  oc get pods -n ${OP_NAMESPACE}
  ATTEMPTS=$((ATTEMPTS + 1))
  sleep 30
  if [[ `oc get po -n ${OP_NAMESPACE}` =~ "Error" ]]; then
    oc delete `oc get po -o name | grep ibm-common-service-operator`
  else
    echo "No pods with Error"
  fi
done

sleep 60

cd ../scripts

# Checking if the bedrock operator pods are ready and running.

# checking status of ibm-namespace-scope-operator

./check-subscription-status.sh cpd-operator ${OP_NAMESPACE} state
./pod-status-check.sh cpd-platform-operator-manager ${OP_NAMESPACE}

./pod-status-check.sh ibm-namespace-scope-operator ${OP_NAMESPACE}

# checking status of operand-deployment-lifecycle-manager

./pod-status-check.sh operand-deployment-lifecycle-manager ${OP_NAMESPACE}

# checking status of ibm-common-service-operator

./pod-status-check.sh ibm-common-service-operator ${OP_NAMESPACE}

cd ../files


# Create zen namespace

oc new-project ${NAMESPACE}
oc project ${NAMESPACE}

# Create the zen operator
sed -i -e s#CPD_NAMESPACE#${NAMESPACE}#g cpd-operandrequest.yaml

echo '*** executing **** oc create -f cpd-operandrequest.yaml'
result=$(oc create -f cpd-operandrequest.yaml)
echo $result
sleep 30


# ****** sed command for classic goes here *******
if [[ ${ON_VPC} == false ]] ; then
    sed -i -e "s/portworx-shared-gp3/ibmc-file-gold-gid/g" ibmcpd-cr.yaml
else
    sed -i -e "s/portworx-shared-gp3/${STORAGE}/g" ibmcpd-cr.yaml
    sed -i -e "s/RWO_STORAGE/${RWO_STORAGE}/g" ibmcpd-cr.yaml
fi

# Create lite CR:
sed -i -e s#CPD_NAMESPACE#${NAMESPACE}#g ibmcpd-cr.yaml
echo '*** executing **** oc create -f ibmcpd-cr.yaml'
result=$(oc create -f ibmcpd-cr.yaml)
echo $result

cd ../scripts

# check if the zen operator pod is up and running.

./pod-status-check.sh ibm-zen-operator ${OP_NAMESPACE}
./pod-status-check.sh ibm-cert-manager-operator ${OP_NAMESPACE}

./pod-status-check.sh cert-manager-cainjector ${OP_NAMESPACE}
./pod-status-check.sh cert-manager-controller ${OP_NAMESPACE}
./pod-status-check.sh cert-manager-webhook ${OP_NAMESPACE}

# check the lite cr status

./check-cr-status.sh ibmcpd ibmcpd-cr ${NAMESPACE} controlPlaneStatus



#echo "Creating the ${CP4D_PROJECT} project ..."
#echo "Creating an operator subscription for the scheduling service"
#
#cat <<EOF |oc apply -f -
#apiVersion: operators.coreos.com/v1alpha1
#kind: Subscription
#metadata:
#  name: ibm-cpd-scheduling-catalog-subscription
#  namespace: ${OC_MARKETPLACE}
#spec:
#  channel: v1.3
#  installPlanApproval: ${APPROVAL_TYPE}
#  name: ibm-cpd-scheduling-operator
#  source: ibm-operator-catalog
#  sourceNamespace: ${OC_MARKETPLACE}
#EOF
#
#echo
#sleep 50
#
#echo "Verifying the subcription that it was triggered ... "
#cpd_scheduling_catalog=$(oc get sub -n ${OC_MARKETPLACE} ibm-cpd-scheduling-catalog-subscription -o jsonpath='{.status.installedCSV} {"\n"}')
#echo "${cpd_scheduling_catalog}"
#echo
#
#echo "Verifying the cluster service version ..."
#oc get csv -n ${OC_MARKETPLACE} "${cpd_scheduling_catalog}" -o jsonpath='{ .status.phase } : { .status.message} {"\n"}'
#echo
#
#echo "Verifying the operator is ready ..."
#oc get deployments -n ${OC_MARKETPLACE} -l olm.owner="${cpd_scheduling_catalog}" -o jsonpath="{.items[0].status.availableReplicas} {'\n'}"
#echo
#
#echo "Creating an operator subscription for the IBM Cloud Pak for Data platform operator ..."
#cat <<EOF |oc apply -f -
#apiVersion: operators.coreos.com/v1alpha1
#kind: Subscription
#metadata:
#  name: cpd-operator
#  namespace: ${CP4D_PROJECT}
#spec:
#  channel: v2.0
#  installPlanApproval: ${APPROVAL_TYPE}
#  name: cpd-platform-operator
#  source: ibm-operator-catalog
#  sourceNamespace: ${OC_MARKETPLACE}
#EOF
#echo
#sleep 50
#
#echo "Verifying that the operator was successfully created ..."
#echo "Verifying the subcription that it was triggered ... "
#cpd_platform_operator=$(oc get sub -n ${CP4D_PROJECT} cpd-operator -o jsonpath='{.status.installedCSV} {"\n"}')
#echo "${cpd_platform_operator}"
#echo
#
#echo "Verifying the cluster service version ..."
#oc get csv -n ${CP4D_PROJECT} "${cpd_platform_operator}" -o jsonpath='{ .status.phase } : { .status.message} {"\n"}'
#echo
#
#echo "Verifying the operator is ready ..."
#oc get deployments -n ${CP4D_PROJECT} -l olm.owner="${cpd_platform_operator}" -o jsonpath="{.items[0].status.availableReplicas} {'\n'}"
#echo
#
#echo "Creating an operator subscription for services ..."
#
#echo "Creating an operator subscription for services ..."
#cat <<EOF | oc apply -f -
#apiVersion: operators.coreos.com/v1alpha1
#kind: Subscription
#metadata:
#  labels:
#    app.kubernetes.io/instance: ibm-cpd-ae-operator-subscription
#    app.kubernetes.io/managed-by: ibm-cpd-ae-operator
#    app.kubernetes.io/name: ibm-cpd-ae-operator-subscription
#  name: ibm-cpd-ae-operator-subscription
#  namespace: ${CP4D_PROJECT}
#spec:
#    channel: stable-v1
#    installPlanApproval: ${APPROVAL_TYPE}
#    name: analyticsengine-operator
#    source: ibm-operator-catalog
#    sourceNamespace: ${OC_MARKETPLACE}
#EOF
#echo
#
#sleep 50
#
#echo "Creating an operator subscription for Cognos Analytics service ..."
#cat <<EOF |oc apply -f -
#apiVersion: operators.coreos.com/v1alpha1
#kind: Subscription
#metadata:
#  name: ibm-ca-operator-catalog-subscription
#  labels:
#    app.kubernetes.io/instance: ibm-ca-operator
#    app.kubernetes.io/managed-by: ibm-ca-operator
#    app.kubernetes.io/name: ibm-ca-operator
#  namespace: ${CP4D_PROJECT}
#spec:
#  channel: v4.0
#  name: ibm-ca-operator
#  installPlanApproval: ${APPROVAL_TYPE}
#  source: ibm-operator-catalog
#  sourceNamespace: ${OC_MARKETPLACE}
#EOF
#
#echo "Verifying that the operator subscription for Cognos Analytics service ..."
#echo "Verifying the subcription that it was triggered ... "
#cpd_ca_operator=$(oc get sub -n ${CP4D_PROJECT} ibm-ca-operator-catalog-subscription -o jsonpath='{.status.installedCSV} {"\n"}')
#echo "${cpd_ca_operator}"
#echo
#
#echo "Verifying the cluster service version ..."
#oc get csv -n ${CP4D_PROJECT} "${cpd_ca_operator}" -o jsonpath='{ .status.phase } : { .status.message} {"\n"}'
#echo
#
#echo "Verifying the operator for Cognos Analytics is ready ..."
#oc get deployments -n ${CP4D_PROJECT} -l olm.owner="${cpd_ca_operator}" -o jsonpath="{.items[0].status.availableReplicas} {'\n'}"
#echo
#
#echo "Creating an operator subscription for Cognos Dashboard service ..."
#cat <<EOF | oc apply -f -
#apiVersion: operators.coreos.com/v1alpha1
#kind: Subscription
#metadata:
#  labels:
#    app.kubernetes.io/instance: ibm-cde-operator-subscription
#    app.kubernetes.io/managed-by: ibm-cde-operator
#    app.kubernetes.io/name: ibm-cde-operator-subscription
#  name: ibm-cde-operator-subscription
#  namespace: ${CP4D_PROJECT}
#spec:
#  channel: v1.0
#  installPlanApproval: ${APPROVAL_TYPE}
#  name: ibm-cde-operator
#  source: ibm-operator-catalog
#  sourceNamespace: ${OC_MARKETPLACE}
#EOF
#
#echo "Verifying that the operator subscription for Cognos Analytics service ..."
#echo "Verifying the subcription that it was triggered ... "
#cpd_cde_operator=$(oc get sub -n ${CP4D_PROJECT} ibm-cde-operator-subscription -o jsonpath='{.status.installedCSV} {"\n"}')
#echo "${cpd_cde_operator}"
#echo
#
#echo "Verifying the cluster service version ..."
#oc get csv -n ${CP4D_PROJECT} "${cpd_cde_operator}" -o jsonpath='{ .status.phase } : { .status.message} {"\n"}'
#echo
#
#echo "Verifying the operator for Cognos Analytics is ready ..."
#oc get deployments -n ${CP4D_PROJECT} -l olm.owner="${cpd_cde_operator}" -o jsonpath="{.items[0].status.availableReplicas} {'\n'}"
#echo