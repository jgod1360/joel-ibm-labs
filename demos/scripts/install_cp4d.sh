#!/usr/bin/env bash

CP4D_PROJECT="cp4d"
ZEN_PROJET="zen"
ENTITLEMENT_KEY=""

# 1. Creating the project where the cp4d will be installed.
echo "Creating the ${CP4D_PROJECT}  where the Cloud Pak for Data will be installed"
oc new-project ${CP4D_PROJECT}
echo
echo


echo "Creating the ${ZEN_PROJET}  where the Cloud Pak for Data will be installed"
oc new-project ${ZEN_PROJET}
echo
echo

echo "Creating the Operator group ..."
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: operatorgroup
  namespace: ${CP4D_PROJECT}
spec:
  targetNamespaces:
  - ${CP4D_PROJECT}
EOF

echo
echo

# 2.
echo "Checking the existance of global image ..."
oc extract secret/pull-secret -n openshift-config
echo
echo


# 3. Applying new configuration
echo "Applying new configuration ..."
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=.dockerconfigjson
echo
echo

echo "Creating the IBM Operator Catalog Source ..."
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-operator-catalog
  namespace: openshift-marketplace
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

echo "Creating the Catalog Source with the dependencies ..."
cat <<EOF |oc apply -f -
---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cpd-ccs-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-cpd-ccs-operator-catalog@sha256:34854b0b5684d670cf1624d01e659e9900f4206987242b453ee917b32b79f5b7
  imagePullPolicy: Always
  displayName: CPD Common Core Services
  publisher: IBM

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cpd-datarefinery-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-cpd-datarefinery-operator-catalog@sha256:27c6b458244a7c8d12da72a18811d797a1bef19dadf84b38cedf6461fe53643a
  imagePullPolicy: Always
  displayName: Cloud Pak for Data IBM DataRefinery
  publisher: IBM

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-db2aaservice-cp4d-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-db2aaservice-cp4d-operator-catalog@sha256:a0d9b6c314193795ec1918e4227ede916743381285b719b3d8cfb05c35fec071
  imagePullPolicy: Always
  displayName: IBM Db2aaservice CP4D Catalog
  publisher: IBM

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cpd-iis-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-cpd-iis-operator-catalog@sha256:3ad952987b2f4d921459b0d3bad8e30a7ddae9e0c5beb407b98cf3c09713efcc
  imagePullPolicy: Always
  displayName: CPD IBM Information Server
  publisher: IBM

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cpd-wml-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: Cloud Pak for Data Watson Machine Learning
  publisher: IBM
  sourceType: grpc
  imagePullPolicy: Always
  image: icr.io/cpopen/ibm-cpd-wml-operator-catalog@sha256:d2da8a2573c0241b5c53af4d875dbfbf988484768caec2e4e6231417828cb192
  updateStrategy:
    registryPoll:
      interval: 45m

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cpd-ws-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-cpd-ws-operator-catalog@sha256:bf6b42df3d8cee32740d3273154986b28dedbf03349116fba39974dc29610521
  imagePullPolicy: Always
  displayName: CPD IBM Watson Studio
  publisher: IBM

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: opencontent-elasticsearch-dev-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/opencontent-elasticsearch-operator-catalog@sha256:bc284b8c2754af2eba81bb1edf6daa59dc823bf7a81fe91710c603f563a9a724
  displayName: IBM Opencontent Elasticsearch Catalog
  publisher: CloudpakOpen
  updateStrategy:
    registryPoll:
      interval: 45m

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-rabbitmq-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: IBM RabbitMQ operator Catalog
  publisher: IBM
  sourceType: grpc
  image: icr.io/cpopen/opencontent-rabbitmq-operator-catalog@sha256:c3b14816eabc04bcdd5c653eaf6e0824adb020ca45d81d57059f50c80f22964f
  updateStrategy:
    registryPoll:
      interval: 45m

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cloud-databases-redis-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: ibm-cloud-databases-redis-operator-catalog
  publisher: IBM
  sourceType: grpc
  image: icr.io/cpopen/ibm-cloud-databases-redis-catalog@sha256:980e4182ec20a01a93f3c18310e0aa5346dc299c551bd8aca070ddf2a5bf9ca5

---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-cpd-ws-runtimes-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: icr.io/cpopen/ibm-cpd-ws-runtimes-operator-catalog@sha256:c1faf293456261f418e01795eecd4fe8b48cc1e8b37631fb6433fad261b74ea4
  imagePullPolicy: Always
  displayName: CPD Watson Studio Runtimes
  publisher: IBM
EOF

echo
echo

# 7. Create the Db2U catalog source if you plan to install one of the following services: Data Virtualization Db2® Db2 Big SQL Db2 Warehouse OpenPages
echo "Creating Db2u Catalog Source ..."
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-db2uoperator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: docker.io/ibmcom/ibm-db2uoperator-catalog:latest
  imagePullPolicy: Always
  displayName: IBM Db2U Catalog
  publisher: IBM
  updateStrategy:
    registryPoll:
      interval: 45m
EOF

echo
echo

echo "Creating operator subscriptions ..."
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  annotations:
  labels:
    operators.coreos.com/ibm-cpd-scheduling-operator.aks: ""
    velero.io/exclude-from-backup: "true"
  name: ibm-cpd-scheduling-catalog-subscription
  namespace: ${CP4D_PROJECT}
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: ibm-cpd-scheduling-operator
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
echo
echo

echo "Creating the Cloud Pak for Data operator subscription ..."
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: cpd-operator
  namespace: ${CP4D_PROJECT}
spec:
  channel: stable-v1
  installPlanApproval: Automatic
  name: cpd-platform-operator
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF

echo
echo

echo "Creating the Db2 Data Management Console ..."
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-dmc-operator-subscription
  namespace: ${CP4D_PROJECT}
spec:
  channel: v1.0
  installPlanApproval: Automatic
  name: ibm-dmc-operator
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF

echo
echo

echo "Creating the Db2U operator subscription ..."
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-db2uoperator-catalog-subscription
  namespace: ${CP4D_PROJECT}
spec:
  channel: v1.1
  name: db2u-operator
  installPlanApproval: Automatic
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF

echo
echo

echo "Creating the Db2 Warehouse operator subscription ..."
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-db2wh-cp4d-operator-catalog-subscription
  namespace: ${CP4D_PROJECT}
spec:
  channel: v1.0
  name: ibm-db2wh-cp4d-operator
  installPlanApproval: Automatic
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF

echo
echo

echo "Creating the Watson Knowledge Catalog operator subscription for your environment ..."
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    app.kubernetes.io/instance:  ibm-cpd-wkc-operator-catalog-subscription
    app.kubernetes.io/managed-by: ibm-cpd-wkc-operator
    app.kubernetes.io/name:  ibm-cpd-wkc-operator-catalog-subscription
  name: ibm-cpd-wkc-operator-catalog-subscription
  namespace: ${CP4D_PROJECT}
spec:
    channel: v1.0
    installPlanApproval: Automatic
    name: ibm-cpd-wkc
    source: ibm-operator-catalog
    sourceNamespace: openshift-marketplace
EOF

echo
echo

echo "Creating the Watson Studio operator subscription for your environment ..."
cat <<EOF |oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  annotations:
  name: ibm-cpd-ws-operator-catalog-subscription
  namespace: ${CP4D_PROJECT}
spec:
  channel: v2.0
  installPlanApproval: Automatic
  name: ibm-cpd-wsl
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF

echo
echo

echo "Load balancer timeout settings Use the following command to set the server-side timeout for the HAProxy route to 360 seconds:"
oc annotate route zen-cpd --overwrite haproxy.router.openshift.io/timeout=360s
echo
echo


echo "Creating a custom node-level tune with the following content ..."
cat <<EOF |oc apply -f -
apiVersion: tuned.openshift.io/v1
kind: Tuned
metadata:
  name: cp4d-wkc-ipc
  namespace: openshift-cluster-node-tuning-operator
spec:
  profile:
  - name: cp4d-wkc-ipc
    data: |
      [main]
      summary=Tune IPC Kernel parameters on OpenShift Worker Nodes running WKC Pods
      [sysctl]
      kernel.shmall = 33554432
      kernel.shmmax = 68719476736
      kernel.shmmni = 32768
      kernel.sem = 250 1024000 100 32768
      kernel.msgmax = 65536
      kernel.msgmnb = 65536
      kernel.msgmni = 32768
      vm.max_map_count = 262144
  recommend:
  - match:
    - label: node-role.kubernetes.io/worker
    priority: 10
    profile: cp4d-wkc-ipc
EOF

echo
echo

echo "Configure kubelet to allow Db2U to make syscalls ..."
cat << EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: db2u-kubelet
spec:
  machineConfigPoolSelector:
      matchLabels:
      db2u-kubelet: sysctl
  kubeletConfig:
      allowedUnsafeSysctls:
      - "kernel.msg*"
      - "kernel.shm*"
      - "kernel.sem"
EOF

echo
echo

echo "Verifying the machineconfigpool that it is updated ..."
cat <<EOF |oc apply -f -
apiVersion: operator.ibm.com/v1alpha1
kind: OperandRequest
metadata:
  name: empty-request
  namespace: ${CP4D_PROJECT}
spec:
  requests: []
EOF

echo
echo

echo "Creating a custom resource to install Cloud Pak for Data ..."
cat <<EOF |oc apply -f -
apiVersion: cpd.ibm.com/v1
kind: Ibmcpd
metadata:
  name: ibmcpd-cr
  namespace: ${CP4D_PROJECT}
spec:
  license:
    accept: true
    license: Enterprise
  storageClass: ibmc-file-gold-gid
  zenCoreMetadbStorageClass: ibmc-file-gold-gid
  version: "4.0.1"
EOF

echo
echo

oc project "${CP4D_PROJECT}"
echo

echo "Getting the status of the control plane Zen Service Custom Resource lite-cr ..."
oc get ZenService lite-cr -o jsonpath="{.status.zenStatus}{'\n'}"

echo
echo

echo "Getting the URL of the Cloud Pak for Data web client ..."
oc get ZenService lite-cr -o jsonpath="{.status.url}{'\n'}"

echo
echo

echo "Getting the initial password for the admin user: "
oc extract secret/admin-user-details --keys=initial_admin_password --to=-