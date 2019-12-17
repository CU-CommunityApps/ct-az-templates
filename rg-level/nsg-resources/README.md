# Cornell Baseline NSG Resources Template

## Current Rules
Latest Version = 1.0

To update baseline NSGs in your account, select the "Deploy to Azure" button below and select your NSG resource group (default: cit-cornell-nsg-rg)

***This will update your cornell-private-nsg and cornell-public-nsg rules and could affect any resources using these NSG's, please review all updates prior to deployment.***

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FCU-CommunityApps%2Fct-az-templates%2Fmaster%2Frg-level%2Fnsg-resources%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/CU-CommunityApps/ct-az-templates/master/images/deploytoazure.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FCU-CommunityApps%2Fct-az-templates%2Fmaster%2Frg-level%2Fnsg-resources%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/CU-CommunityApps/ct-az-templates/master/images/visualizebutton.png"/>
</a>

Currently the only supported methods for deploying subscription level templates are the REST apis, some SDKS and the Azure CLI.  For the latest check [here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/create-resource-group-in-template#create-empty-resource-group).
