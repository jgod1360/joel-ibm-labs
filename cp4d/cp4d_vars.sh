#===============================================================================
# Cloud Pak for Data installation variables
#===============================================================================

# ------------------------------------------------------------------------------
# Cluster variables
# ------------------------------------------------------------------------------

export OCP_URL=""


# ------------------------------------------------------------------------------
# Project variables
# ------------------------------------------------------------------------------

export PROJECT_CPFS_OPS=ibm-common-services
export PROJECT_CPD_OPS=<enter your Cloud Pak for Data operator installation project>
export PROJECT_CATSRC=openshift-marketplace
export PROJECT_CPD_INSTANCE=<enter your Cloud Pak for Data installation project>
# export PROJECT_TETHERED=<enter the tethered project>


# ------------------------------------------------------------------------------
# Operator installation variables
# ------------------------------------------------------------------------------

export APPROVAL_TYPE=Automatic


# ------------------------------------------------------------------------------
# Licenses variables
# ------------------------------------------------------------------------------

export LICENSE_CPD=<enter the license you purchased>

# ------------------------------------------------------------------------------
# IBM Entitled Registry variables
# ------------------------------------------------------------------------------

export IBM_ENTITLEMENT_KEY=<enter your IBM entitlement API key>
export IBM_ENTITLEMENT_USER=cp
export IBM_ENTITLEMENT_SERVER=cp.icr.io


# ------------------------------------------------------------------------------
# CASE package management variables
# ------------------------------------------------------------------------------

export OFFLINEDIR_CPD=<enter an existing directory>
export OFFLINEDIR_CPFS=<enter an existing directory>
export PATH_CASE_REPO=https://github.com/IBM/cloud-pak/raw/master/repo/case
export USE_SKOPEO=true


# ------------------------------------------------------------------------------
# Private container registry variables
# ------------------------------------------------------------------------------
# Set the following variables if you mirror images to a private container registry.
#
# To export these variables, you must uncomment each command in this section.

# export PRIVATE_REGISTRY_LOCATION=<enter the location of your private container registry>
# export PRIVATE_REGISTRY_PUSH_USER=<enter the username of a user that can push to the registry>
# export PRIVATE_REGISTRY_PUSH_PASSWORD=<enter the password of the user that can push to the registry>
# export PRIVATE_REGISTRY_PULL_USER=<enter the username of a user that can pull from the registry>
# export PRIVATE_REGISTRY_PULL_PASSWORD=<enter the password of the user that can pull from the registry>


# ------------------------------------------------------------------------------
# Intermediary container registry variables
# ------------------------------------------------------------------------------
# Set the following variables if you use an intermediary container registry to
# mirror images to your private container registry.
#
# To export these variables, you must uncomment each command in this section.

# export INTERMEDIARY_REGISTRY_HOST=localhost
# export INTERMEDIARY_REGISTRY_PORT=<enter the port to use on the localhost>
# INTERMEDIARY_REGISTRY_LOCATION="${INTERMEDIARY_REGISTRY_HOST}:${INTERMEDIARY_REGISTRY_PORT}"
# export INTERMEDIARY_REGISTRY_LOCATION
# export INTERMEDIARY_REGISTRY_USER=<enter the username to authenticate to the registry>
# export INTERMEDIARY_REGISTRY_PASSWORD=<enter the password for the user>