# Deploy Cargo Tracker to Oracle WebLogic Server on Azure Kubernetes Service (AKS)

The [official Azure offer for running WLS on AKS](https://aka.ms/wls-aks-portal) enables you to easily run a WebLogic applications on AKS. For a quickstart on this offer, see [https://aka.ms/wls-aks-quickstart](https://aka.ms/wls-aks-quickstart).

This quickstart shows you how to deploy an existing Java WebLogic application to AKS. When you're finished, you can continue to manage the application via the Azure CLI or Azure Portal.

* [Deploy Cargo Tracker to Oracle WebLogic Server on Azure Kubernetes Service (AKS)]()
  * [Introduction](#introduction)
  * [Prerequisites](#prerequisites)
  * [Unit-1 - Deploy and monitor Cargo Tracker]()
  * [Unit-2 - Automate deployments using GitHub Actions]()
  * [Next Steps]()

## Introduction

In this quickstart, you will:
* Build Cargo Tracker.
* Deploying Cargo Tracker
  * Create ProgresSQL Database
  * Provisioning Azure Infra Services with Azure BICEP
    * Create an Azure Container Registry
    * Build Cargo Tracker, Oracle WebLogic Server and domain configuration models into an image
    * Push the application image to the container registry
    * Create an Azure Kubernetes Service  
    * Deploy the application to AKS
    * Create an Azure Application Gateway
    * Expose the application with the application gateway
  * Verify the application
  * Monitor application
  * Automate deployments using GitHub Actions

## Prerequisites

- Local shell with Azure CLI 2.45.0 or higher installed or [Azure Cloud Shell](https://ms.portal.azure.com/#cloudshell/)
- Azure Subscription, on which you are able to create resources and assign permissions
  - View your subscription using ```az account show``` 
  - If you don't have an account, you can [create one for free](https://azure.microsoft.com/free). 
- An Oracle account. To create an Oracle account and accept the license agreement for WebLogic Server images, follow the steps in [Oracle Container Registry](https://aka.ms/wls-aks-ocr). Make note of your Oracle Account password and email.
- GitHub CLI (optional, but strongly recommended). To install the GitHub CLI on your dev environment, see [Installation](https://cli.github.com/manual/installation).

## Unit-1 - Deploy and monitor Cargo Tracker

### Clone and build Cargo Tracker

Clone the sample app repository to your development environment.

```bash
mkdir cargotracker-wls-aks
DIR="$PWD/cargotracker-wls-aks"

git clone https://github.com/Azure-Samples/cargotracker-wls-aks.git ${DIR}/cargotracker
```

Change directory and build the project.

```bash
mvn clean install -PweblogicOnAks --file ${DIR}/cargotracker/pom.xml
```

After the Maven command completes, the WAR file locates in `${DIR}/cargotracker/target/cargo-tracker.war`.

### Clone WLS on AKS Bicep templates

Clone the Bicep templates from [oracle/weblogic-azure](https://github.com/oracle/weblogic-azure). This quickstart was tested with [commit 364b764](https://github.com/oracle/weblogic-azure/commit/364b7648bbe395cb17683180401d07a3029abe91). 

```bash
WLS_AKS_REPO_REF="364b7648bbe395cb17683180401d07a3029abe91"
git clone https://github.com/oracle/weblogic-azure.git ${DIR}/weblogic-azure

cd ${DIR}/weblogic-azure
git checkout ${WLS_AKS_REPO_REF}

cd ${DIR}
```

### Sign in to Azure

If you haven't already, sign in to your Azure subscription by using the `az login` command and follow the on-screen directions.

```bash
az login
```

If you have multiple Azure tenants associated with your Azure credentials, you must specify which tenant you want to sign in to. You can do this with the `--tenant option`. For example, `az login --tenant contoso.onmicrosoft.com`.

### Create a resource group

Create a resource group with `az group create`. Resource group names must be globally unique within a subscription.

```bash
RESOURCE_GROUP_NAME="abc1110rg"

az group create \
    --name ${RESOURCE_GROUP_NAME} \
    --location eastus
```

### Create Azure Storage Account and upload the application

To deploy a Java EE application along with the WLS on AKS offer deployment. You have to upload the application file (.war, .ear, or .jar) to a pre-existing Azure Storage Account and Storage Container within that account.

Create an Azure Storage Account using the `az storage account create` command, as shown in the following example:

```bash
STORAGE_ACCOUNT_NAME="stgwlsaks$(date +%s)"
az storage account create \
    --resource-group ${RESOURCE_GROUP_NAME} \
    --name ${STORAGE_ACCOUNT_NAME} \
    --location eastus \
    --sku Standard_RAGRS \
    --kind StorageV2
```

Create a container for storing blobs with the `az storage container create` command, with public access enabled.

```bash
KEY=$(az storage account keys list \
    --resource-group ${RESOURCE_GROUP_NAME} \
    --account-name ${STORAGE_ACCOUNT_NAME} \
    --query [0].value -o tsv)

az storage container create \
    --account-name ${STORAGE_ACCOUNT_NAME} \
    --name mycontainer \
    --public-access container
```

Next, upload Cargo Tracker to a blob using the `az storage blob upload` command.

```bash
az storage blob upload \
    --account-name ${STORAGE_ACCOUNT_NAME} \
    --container-name mycontainer \
    --name cargo-tracker.war \
    --file ${DIR}/cargotracker/target/cargo-tracker.war
```

Obtain the blob URL, which will be used as a deployment parameter.

```bash
cargoTrackerBlobUrl=$(az storage blob url \
  --account-name ${STORAGE_ACCOUNT_NAME} \
  --container-name mycontainer \
  --name cargo-tracker.war -o tsv)
APP_URL=$(echo ${cargoTrackerBlobUrl} | sed 's,/,\\\/,g')
```

### Create an Azure Database for PostgreSQL instance

Use `az postgres server create` to provision a PostgreSQL instance on Azure. The data server allows access from Azure Services.

```bash
DB_SERVER_NAME="wlsdb$(date +%s)"
DB_PASSWORD="Secret123456"

az postgres server create \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --name ${DB_SERVER_NAME}  \
  --location eastus \
  --admin-user weblogic \
  --ssl-enforcement Disabled \
  --public-network-access Enabled \
  --admin-password ${DB_PASSWORD} \
  --sku-name B_Gen5_1

  echo "Allow Access To Azure Services"
  az postgres server firewall-rule create \
  -g ${RESOURCE_GROUP_NAME} \
  -s ${DB_SERVER_NAME} \
  -n "AllowAllWindowsAzureIps" \
  --start-ip-address "0.0.0.0" \
  --end-ip-address "0.0.0.0"
```

Obtain the JDBC connection string, which will be used as a deployment parameter.

```bash
DB_CONNECTION_STRING="jdbc:postgresql://${DB_SERVER_NAME}.postgres.database.azure.com:5432/postgres"
```

### Prepare deployment parameter file

Several parameters are required to invoke the Bicep templates. Parameters and their value are listed in the table. Make sure the variables have correct value.

Create variables for Oracle account and WebLogic admin.

```bash
MY_ORACLE_SSO_USER="user@contoso.com" # please replace with your Oracle Account user name.
MY_ORACLE_SSO_PASSWORD="Secret123456" # please replace with your Oracle Account password.
MY_WEBLOGIC_ADMIN_USER_NAME="weblogic"
MY_WEBLOGIC_ADMIN_PASSWORD="Secret123456"
```

| Parameter Name | Value | Note |
| -------------| ---------- | -----------------|
| `_artifactsLocation` | `https://raw.githubusercontent.com/oracle/weblogic-azure/${WLS_AKS_REPO_REF}/weblogic-azure-aks/src/main/arm/` | This quickstart is using templates and scripts from `oracle/weblogic-azure/${WLS_AKS_REPO_REF}` |
| `appgwForAdminServer` | `true` | The admin server will be exposed by Application Gateway. |
| `appgwForRemoteConsole` | `false` | WebLogic Remote Console is not required in this quickstart. |
| `appPackageUrls` | `["${APP_URL}"]` | An array includes Cargo Tracker blob URL. |
| `databaseType` | `postgresql` | This quickstart uses Azure Database for PostgreSQL. |
| `dbGlobalTranPro` | `EmulateTwoPhaseCommit` | To ensure Cargo Tracker work correctly, `dbGlobalTranPro` must be `EmulateTwoPhaseCommit`. |
| `dbPassword` | `${DB_PASSWORD}` | The password of PostgreSQL database . |
| `dbUser` | `weblogic` | The username of PostgreSQL database. This quickstart uses `weblogic`. |
| `dsConnectionURL` | `${DB_CONNECTION_STRING}` | The connection string of PostgreSQL database. |
| `enableAppGWIngress` | `true` | This value causes provisioning of Azure Application Gateway Ingress Controller and ingress for WLS admin server and cluster. |
| `enableAzureMonitoring` | `true` | This value causes provisioning Azure Monitor. |
| `enableCookieBasedAffinity` | `true` | This value causes the template to enable Application Gateway Cookie Affinity. |
| `jdbcDataSourceName` | `jdbc/CargoTrackerDB` | This value is defined in Cargo Tracker, do not change it. |
| `ocrSSOPSW` | `${MY_ORACLE_SSO_PASSWORD}` | |
| `ocrSSOUser` | `${MY_ORACLE_SSO_USER}` | |
| `wdtRuntimePassword` | `${MY_WEBLOGIC_ADMIN_PASSWORD}` | |
| `wlsImageTag` | `14.1.1.0-11` | Cargo Tracker runs on WLS 14 and JDK 11. Do not change the value. |
| `wlsPassword` | `${MY_WEBLOGIC_ADMIN_PASSWORD}` | |
| `wlsUserName` | `${MY_WEBLOGIC_ADMIN_USER_NAME}` | |

Create parameter file.

```bash
cat <<EOF >parameters.json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "_artifactsLocation": {
      "value": "https://raw.githubusercontent.com/oracle/weblogic-azure/${WLS_AKS_REPO_REF}/weblogic-azure-aks/src/main/arm/"
    },
    "aksAgentPoolNodeCount": {
      "value": 2
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
        "${APP_URL}"
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
    "databaseType": {
      "value": "postgresql"
    },
    "dbGlobalTranPro": {
      "value": "EmulateTwoPhaseCommit"
    },
    "dbPassword": {
      "value": "${DB_PASSWORD}"
    },
    "dbUser": {
      "value": "weblogic"
    },
    "dsConnectionURL": {
      "value": "${DB_CONNECTION_STRING}"
    },
    "enableAppGWIngress": {
      "value": true
    },
    "enableAzureMonitoring": {
      "value": true
    },
    "enableAzureFileShare": {
      "value": false
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
      "value": "eastus"
    },
    "ocrSSOPSW": {
      "value": "${MY_ORACLE_SSO_PASSWORD}"
    },
    "ocrSSOUser": {
      "value": "${MY_ORACLE_SSO_USER}"
    },
    "wdtRuntimePassword": {
      "value": "${MY_WEBLOGIC_ADMIN_PASSWORD}"
    },
    "wlsImageTag": {
      "value": "14.1.1.0-11"
    },
    "wlsPassword": {
      "value": "${MY_WEBLOGIC_ADMIN_PASSWORD}"
    },
    "wlsUserName": {
      "value": "${MY_WEBLOGIC_ADMIN_USER_NAME}"
    }
  }
}
EOF
```

### Invoke WLS on AKS Bicep template to deploy the application

Invoke the Bicep template in `${DIR}/weblogic-azure/weblogic-azure-aks/src/main/bicep/mainTemplate.bicep` to deploy Cargo Tracker to WLS on AKS.

Run the following command to validate the parameter file.

```bash
az deployment group validate \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --name wls-on-aks \
  --parameters @parameters.json \
  --template-file ${DIR}/weblogic-azure/weblogic-azure-aks/src/main/bicep/mainTemplate.bicep
```

The command should complete without error. If there is, you must resolve it before moving on.

Next, invoke the template.

```bash
az deployment group create \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --name wls-on-aks \
  --parameters @parameters.json \
  --template-file ${DIR}/weblogic-azure/weblogic-azure-aks/src/main/bicep/mainTemplate.bicep
```

It takes more than 1 hour to finish the deployment.

### Configure JMS

Once the deployment completes, you are able to access Cargo Tracker using the output URL. To have Cargo Tracker fully operational, you need to configure JMS.

1. Connect to AKS

Run the following commands to obtain AKS resource name.

```bash
AKS_NAME=$(az resource list \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --query "[?type=='Microsoft.ContainerService/managedClusters'].name|[0]" \
  -o tsv)
```

Connect to AKS cluster.

```bash
az aks get-credentials --resource-group ${RESOURCE_GROUP_NAME} --name $AKS_NAME
```

1. Apply JMS configuration



1. Roll update the WLS cluster

### Monitor WebLogic application

## Unit-2 - Automate deployments using GitHub Actions

1. Fork the repository by clicking the 'Fork' button on the top right of the page.
This creates a local copy of the repository for you to work in. 

2. Configure GITHUB Actions:  Follow the instructions in the [GITHUB_ACTIONS_CONFIG.md file](.github/GITHUB_ACTIONS_CONFIG.md) (Located in the .github folder.)

4. Manually run the workflow

* Under your repository name, click Actions.
* In the left sidebar, click the workflow "Setup WLS on AKS".
* Above the list of workflow runs, select Run workflow.
* Configure the workflow.
  + Use the Branch dropdown to select the workflow's main branch.
  + For **Included in names to disambiguate. Get from another pipeline execution**, enter disambiguation prefix, e.g. `test01`.

5. Click Run workflow.

## Workflow description

As mentioned above, the app template uses the [official Azure offer for running WLS on AKS](https://aka.ms/wls-aks-portal). The workflow uses the source code behind that offer by checking it out and invoking it from Azure CLI.

### Job: preflight

This job is to build WLS on AKS template into a ZIP file containing the ARM template to invoke.

* Set up environment to build the WLS on AKS templates
  + Set up JDK 1.8
  + Set up bicep 0.11.1

* Download dependencies
  + Checkout azure-javaee-iaas, this is a precondition necessary to build WLS on AKS templates. For more details, see [Azure Marketplace Azure Application (formerly known as Solution Template) Helpers](https://github.com/Azure/azure-javaee-iaas).

* Checkout and build WLS on AKS templates
  + Checkout ${{ env.aksRepoUserName }}/weblogic-azure. Checkout [oracle/weblogic-azure](https://github.com/oracle/weblogic-azure) by default. This repository contains all the BICEP templates that provision Azure resources, configure WLS and deploy app to AKS. 
  + Build and test weblogic-azure/weblogic-azure-aks. Build and package the WLS on AKS templates into a ZIP file (e.g. wls-on-aks-azure-marketplace-1.0.56-arm-assembly.zip). The structure of the ZIP file is:

    ```text
    ├── mainTemplate.json (ARM template that is built from BICEP files, which will be invoked for the following deployments)
    └── scripts (shell scripts and metadata)
    ```

  + Archive weblogic-azure/weblogic-azure-aks template. Upload the ZIP file to the pipeline. The later jobs will download the ZIP file for further deployments.

### Job: deploy-db

This job is to deploy PostgreSQL server and configure firewall setting.

* Set Up Azure Database for PostgreSQL
  + azure-login. Login Azure.
  + Create Resource Group. Create a resource group to which the database will deploy.
  + Set Up Azure Postgresql to Test dbTemplate. Provision Azure Database for PostgreSQL Single Server. The server allows access from Azure services.

### Job: deploy-storage-account

This job is to build Cargo Trakcer and deploy an Azure Storage Account with a container to store the application.

* Build Cargo Trakcer
  + Checkout cargotracker. Checkout Cargo Trakcer from this repository.
  + Maven build web app. Build Cargo Trakcer with Maven. The war file locates in `cargotracker/target/cargo-tracker.war`

* Provision Storage Account and container
  + azure-login. Login Azure.
  + Create Resource Group. Create a resource group to which the storage account will deploy.
  + Create Storage Account. Create a storage account with name `${{ env.storageAccountName }}`.
  + Create Storage Container. Create a container with name `${{ env.storageContainerName }}`.

* Upload Cargo Trakcer to the container
  + Upload built web app war file. Upload the application war file to the container using AZ CLI commands. The URL of the war file will pass to the ARM template as a parameter when deploying WLS on AKS templates.

### Job: deploy-wls-on-aks

This job is to provision Azure resources, configure WLS, run WLS on AKS and deploy the application to WLS using WLS on AKS solution template.

* Download the WLS on AKS solution template
  + Checkout ${{ env.aksRepoUserName }}/weblogic-azure. Checkout [oracle/weblogic-azure](https://github.com/oracle/weblogic-azure) to find the version information.
  + Get version information from weblogic-azure/weblogic-azure-aks/pom.xml. Get the version info for solution template ZIP file, which is used to generate the ZIP file name: `wls-on-aks-azure-marketplace-${version}-arm-assembly.zip`
  + Output artifact name for Download action. Generate and output the ZIP file name: `wls-on-aks-azure-marketplace-${version}-arm-assembly.zip`.
  + Download artifact for deployment. Download the ZIP file that is built in job:preflight.

* Deploy WLS on AKS
  + azure-login. Login Azure.
  + Query web app blob url and set to env. Obtain blob url for cargo-tracker.war, which will server as a parameter for the deployment.
  + Create Resource Group. Create a resource group for WLS on AKS.
  + Checkout cargotracker. Checkout the parameter template.
  + Prepare parameter file. Set values to the parameters.
  + Validate Deploy of WebLogic Server Cluster Domain offer. Validate the parameters file in the context of the bicep template to be invoked. This will catch some errors before taking the time to start the full deployment. `--template-file` is the mainTemplate.json from solution template ZIP file. `--parameters` is the parameter file created in last step.
  + Deploy WebLogic Server Cluster Domain offer. Invoke the mainTemplate.json to deploy resources and configurations. After the deployment completes, you'll get the following result:
    + An Azure Container Registry and a WLS image that contains Cargo Tracker in the ACR repository.
    + An Azure Kubernetes Service with WLS running in `sample-domain1-ns` namespace, including 1 pod for WLS admin server and 2 pods for managed server.
    + An Azure Application Gateway that is able to route to the backend WLS pods. You can access the application using `http://<gateway-hostname>/cargo-tracker/`

* Enable Cargo Tracker with full operations
  + Connect to AKS cluster. Though the application is accessible, but some functionalities are not ready. We have to apply JMS configuration in `src/test/aks/cargo-tracker-jms.yaml` to WLS cluster. This step is to connect to AKS cluster to update WLS configuration.
  + Generate&Apply configmap. Append JMS configuration in `src/test/aks/cargo-tracker-jms.yaml` to WLS configuration, which is stored in configmap `sample-domain1-wdt-config-map` in `sample-domain1-ns` namespace. Then the step causes a rolling update on the WLS pods.
  + Verify pods are restarted. This step is to wait for WLS cluster ready. You can follow steps in [Exercise the Cargo Tracker app](https://www.ridingthecrest.com/javaland-javaee/wls#exercise-the-cargo-tracker-app) to validate the JMS configuration.

## Cargo Tracker Website

![Cargo Tracker Website](cargo_tracker_website.png)

If you wish to view the Cargo Tracker Deployment, you have the following options:

- Log into the Azure Portal
- Navigate to the `wlsd-aks-<your-disambiguate-prefix>-<number>` Resource Group
- Select **Settings**, **Deployments**, **wls-on-aks**, **Outputs**, you will see `clusterExternalUrl`. The application URL is `${clusterExternalUrl}cargo-tracker/`.
- Open your web browser, navigate to the application URL, you will see the Cargo Tracker landing page.

## Exercise Cargo Tracker Functionality

1. On the main page, select **Public Tracking Interface** in new window. 

   1. Enter **ABC123** and select **Track!**

   1. Observe what the **next expected activity** is.

1. On the main page, select **Administration Interface**, then, in the left navigation column select **Live** in a new window.  This opens up a map view.

   1. Mouse over the pins and find the one for **ABC123**.  Take note of the information in the hover window.

1. On the main page, select **Mobile Event Logger**.  This opens up in a new, small, window.

1. Drop down the menu and select **ABC123**.  Select **Next**.

1. Select the **Location** using the information in the **next expected activity**.  Select **Next**.

1. Select the **Event Type** using the information in the **next expected activity**.  Select **Next**.

1. Select the **Voyage** using the information in the **next expected activity**.  Select **Next**.

1. Set the **Completion Date** a few days in the future.  Select **Next**.

1. Review the information and verify it matches the **next expected activity**.  If not, go back and fix it.  If so, select **Submit**.

1. Back on the **Public Tracking Interface** select **Tracking** then enter **ABC123** and select **Track**.  Observe that a different. **next expected activity** is listed.

1. If desired, go back to **Mobile Event Logger** and continue performing the next activity.

## Learn more about Cargo Tracker

See [Eclipse Cargo Tracker - Applied Domain-Driven Design Blueprints for Jakarta EE](cargo-tracker.md)
