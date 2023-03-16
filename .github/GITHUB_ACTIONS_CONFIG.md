# Configuration for GitHub Actions

The newly created GitHub repo uses GitHub Actions to deploy Azure resources and application code automatically. Your subscription is accessed using an Azure Service Principal with **Contributor** and **User Access Administrator** permissions. This is an identity created for use by applications, hosted services, and automated tools to access Azure resources. Make sure your identity that runs the scripts has at least **Contributor** and **User Access Administrator**. 

If you have [GitHub CLI](https://cli.github.com/) installed, the script will create GitHub Action secrets automatically. Otherwise, you have to create the secrets following steps in [set up GitHub Actions to deploy Azure applications](https://github.com/Azure/actions-workflow-samples/blob/master/assets/create-secrets-for-GitHub-workflows.md)

## Set up configuration

Follow the steps to set up configuration:

1. Log in Azure

```bash
az login --tenant <your-tenant>
```

2. Run the setup script

```bash
cd .github/workflows

bash setup.sh
```

You are required to input values:

* Enter a disambiguation prefix
* Enter Oracle single sign-on userid
* Enter password for preceding Oracle single sign-on userid
* Enter owner/reponame

Then you'll get similar output as the following content shows.

If you have no GitHub CLI installed:

```bash
$ bash setup.sh
Enter a disambiguation prefix (try initials with a sequence number, such as ejb01): test01
Enter Oracle single sign-on userid: test@contoso.com
Enter password for preceding Oracle single sign-on userid: 

Enter owner/reponame (blank for upsteam of current fork): contoso/app-templates-WLS-on-aks
Using disambiguation prefix test010302
(1/4) Checking Azure CLI status...
Azure CLI is installed and configured!
(2/4) Checking GitHub CLI status...
setup.sh: line 132: gh: command not found
Cannot use the GitHub CLI. No worries! We'll set up the GitHub secrets manually.
(3/4) Create Azure credentials test010302sp with Contributor and User Access Administrator role in subscription scope.
{
  "canDelegate": null,
  "condition": null,
  "conditionVersion": null,
  "description": null,
  "id": "/subscriptions/xxxxxxxxx-xxxx-xxxx-xxxxxxx/providers/Microsoft.Authorization/roleAssignments/xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "name": "xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "principalId": "xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "principalType": "ServicePrincipal",
  "roleDefinitionId": "/subscriptions/xxxxxxxxx-xxxx-xxxx-xxxxxxx/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9",
  "scope": "/subscriptions/xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "type": "Microsoft.Authorization/roleAssignments"
}
(4/4) Create secrets in GitHub
======================MANUAL SETUP======================================
Using your Web browser to set up secrets...
Go to the GitHub repository you want to configure.
In the "settings", go to the "secrets" tab and the following secrets:
(in yellow the secret name and in green the secret value)
"AKS_REPO_USER_NAME"
oracle
"AZURE_CREDENTIALS"
{
  "clientId": "xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "clientSecret": "xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "subscriptionId": "xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "tenantId": "xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
"DB_PASSWORD"
Secret123!
"ORC_SSOPSW"
XXXXXXX
"ORC_SSOUSER"
test@contoso.com
"WDT_RUNTIMEPSW"
Secret123456
"WLS_PSW"
Secret123456
"WLS_USERNAME"
weblogic
========================================================================
Secrets configured

```

If you have GitHub CLI installed:

```bash
$ bash setup.sh
Enter a disambiguation prefix (try initials with a sequence number, such as ejb01): test03
Enter Oracle single sign-on userid: test@contoso.com
Enter password for preceding Oracle single sign-on userid: 

Enter owner/reponame (blank for upsteam of current fork): contoso/app-templates-WLS-on-aks
Using disambiguation prefix test030302
(1/4) Checking Azure CLI status...
Azure CLI is installed and configured!
(2/4) Checking GitHub CLI status...
github.com
  ✓ Logged in to github.com as contoso (/home/contoso/.config/gh/hosts.yml)
  ✓ Git operations for github.com configured to use ssh protocol.
  ✓ Token: gho_************************************
  ✓ Token scopes: admin:public_key, gist, read:org, repo
GitHub CLI is installed and configured!
(3/4) Create Azure credentials test030302sp with Contributor and User Access Administrator role in subscription scope.
{
  "canDelegate": null,
  "condition": null,
  "conditionVersion": null,
  "description": null,
  "id": "/subscriptions/xxxxxxxxx-xxxx-xxxx-xxxxxxx/providers/Microsoft.Authorization/roleAssignments/xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "name": "xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "principalId": "xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "principalType": "ServicePrincipal",
  "roleDefinitionId": "/subscriptions/xxxxxxxxx-xxxx-xxxx-xxxxxxx/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9",
  "scope": "/subscriptions/xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "type": "Microsoft.Authorization/roleAssignments"
}
(4/4) Create secrets in GitHub
Using the GitHub CLI to set secrets.
✓ Set Actions secret AKS_REPO_USER_NAME for contoso/app-templates-WLS-on-aks
✓ Set Actions secret AZURE_CREDENTIALS for contoso/app-templates-WLS-on-aks
"AZURE_CREDENTIALS"
{
  "clientId": "xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "clientSecret": "xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "subscriptionId": "xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "tenantId": "xxxxxxxxx-xxxx-xxxx-xxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
✓ Set Actions secret DB_PASSWORD for contoso/app-templates-WLS-on-aks
✓ Set Actions secret ORC_SSOPSW for contoso/app-templates-WLS-on-aks
✓ Set Actions secret ORC_SSOUSER for contoso/app-templates-WLS-on-aks
✓ Set Actions secret WDT_RUNTIMEPSW for contoso/app-templates-WLS-on-aks
✓ Set Actions secret WLS_PSW for contoso/app-templates-WLS-on-aks
✓ Set Actions secret WLS_USERNAME for contoso/app-templates-WLS-on-aks
Secrets configured
```

## Tear down configuration

Run the teardown script

```bash
cd .github/workflows

bash teardown.sh
```

You are required to enter values:
* Enter disambiguation prefix, which can be found in the output of setup script.
* Enter owner/reponame,

Then you'll get similar output as the following content shows.

If you have no GitHub CLI installed:

```bash
$ bash teardown.sh 
Enter disambiguation prefix: test010302
Enter owner/reponame (blank for upsteam of current fork): contoso/app-templates-WLS-on-aks
(1/3) Delete service principal test010302sp
(2/3) Checking GitHub CLI status...
teardown.sh: line 61: gh: command not found
Cannot use the GitHub CLI. No worries! We'll set up the GitHub secrets manually.
(3/3) Removing secrets...
======================MANUAL REMOVAL======================================
Using your Web browser to remove secrets...
Go to the GitHub repository you want to configure.
In the "settings", go to the "secrets" tab and remove the following secrets:
(in yellow the secret name)
"AKS_REPO_USER_NAME"
"AZURE_CREDENTIALS"
"DB_PASSWORD"
"ORC_SSOPSW"
"ORC_SSOUSER"
"WDT_RUNTIMEPSW"
"WLS_PSW"
"WLS_USERNAME"
========================================================================
Secrets removed
```

If you have GitHub CLI installed:

```bash
$ bash teardown.sh
Enter disambiguation prefix: test030302
Enter owner/reponame (blank for upsteam of current fork): contoso/app-templates-WLS-on-aks
(1/3) Delete service principal test030302sp
(2/3) Checking GitHub CLI status...
github.com
  ✓ Logged in to github.com as contoso (/home/contoso/.config/gh/hosts.yml)
  ✓ Git operations for github.com configured to use ssh protocol.
  ✓ Token: gho_************************************
  ✓ Token scopes: admin:public_key, gist, read:org, repo
GitHub CLI is installed and configured!
(3/3) Removing secrets...
Using the GitHub CLI to remove secrets.
✓ Deleted Actions secret AKS_REPO_USER_NAME from contoso/app-templates-WLS-on-aks
✓ Deleted Actions secret AZURE_CREDENTIALS from contoso/app-templates-WLS-on-aks
✓ Deleted Actions secret DB_PASSWORD from contoso/app-templates-WLS-on-aks
✓ Deleted Actions secret ORC_SSOPSW from contoso/app-templates-WLS-on-aks
✓ Deleted Actions secret ORC_SSOUSER from contoso/app-templates-WLS-on-aks
✓ Deleted Actions secret WDT_RUNTIMEPSW from contoso/app-templates-WLS-on-aks
✓ Deleted Actions secret WLS_PSW from contoso/app-templates-WLS-on-aks
✓ Deleted Actions secret WLS_USERNAME from contoso/app-templates-WLS-on-aks
Secrets removed
```
