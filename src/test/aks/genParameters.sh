#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

gitUserName=$1
testbranchName=$2
appPackageUrls=$3
dbPassword=$4
dbUser=$5
dsConnectionURL=$6
location=$7
ocrSSOPSW=$8
ocrSSOUser=$9
wdtRuntimePassword=${10}
wlsPassword=${11}
wlsUserName=${12}
parametersPath=${13}

cat <<EOF > ${parametersPath}
{
    "\$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "_artifactsLocation": {
            "value": "https://raw.githubusercontent.com/${gitUserName}/weblogic-azure/${testbranchName}/weblogic-azure-aks/src/main/arm/"
        },
        "aksAgentPoolNodeCount": {
            "value": 3
        },
        "vmSize": {
            "value": "Standard_DS2_v2"
        },
        "appGatewayCertificateOption": {
            "value": "generateCert"
        },
        "appgwForAdminServer": {
            "value": true
        },
        "appgwForRemoteConsole": {
            "value": false
        },
        "appPackageUrls": {
            "value": [
                "${appPackageUrls}"
            ]
        },
        "appReplicas": {
            "value": 2
        },
        "createACR": {
            "value": true
        },
        "createAKSCluster": {
            "value": true
        },
        "createDNSZone": {
            "value": true
        },
        "databaseType": {
            "value": "postgresql"
        },
        "dbGlobalTranPro": {
            "value": "EmulateTwoPhaseCommit"
        },
        "dbPassword": {
            "value": "${dbPassword}"
        },
        "dbUser": {
            "value": "${dbUser}"
        },
        "dsConnectionURL": {
            "value": "${dsConnectionURL}"
        },
        "enableAppGWIngress": {
            "value": true
        },
        "enableAzureMonitoring": {
            "value": true
        },
        "enableAzureFileShare": {
            "value": true
        },
        "enableDB": {
            "value": true
        },
        "enableDNSConfiguration": {
            "value": false
        },
        "enableCookieBasedAffinity": {
            "value": true
        },
        "jdbcDataSourceName": {
            "value": "jdbc/CargoTrackerDB"
        },
        "location": {
            "value": "${location}"
        },
        "lbSvcValues": {
            "value": []
        },
        "ocrSSOPSW": {
            "value": "${ocrSSOPSW}"
        },
        "ocrSSOUser": {
            "value": "${ocrSSOUser}"
        },
        "wdtRuntimePassword": {
            "value": "${wdtRuntimePassword}"
        },
        "wlsImageTag": {
            "value": "14.1.1.0-11"
        },
        "wlsPassword": {
            "value": "${wlsPassword}"
        },
        "wlsUserName": {
            "value": "${wlsUserName}"
        }
    }
}
EOF