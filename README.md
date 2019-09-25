# Azure templates
Templates for consumption

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest)

Templates use Azure CLI credentials, so you must start with:
```
$ az login --use-device-code

To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code ABCDEFG1234 to authenticate.
...
```

### Referencing nested templates
* https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-linked-templates

**Use this URI to link to files in this repo**

```https://raw.githubusercontent.com/CU-CommunityApps/ct-az-templates/master/<level>/<template-file-name>```
```
"resources": [
  {
    "type": "Microsoft.Resources/deployments",
    "apiVersion": "2018-05-01",
    "name": "linkedTemplate",
    "properties": {
    "mode": "Incremental",
    "templateLink": {
        "uri":"https://raw.githubusercontent.com/CU-CommunityApps/ct-az-templates/master/<level>/<template-file-name>",
        "contentVersion":"1.0.0.0"
    }
  }
]
```

#### [rg-level](rg-level) Resource group deployments
* https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy-cli
```
az group deployment create \
--resource-group <resource-group-name> \
--template-file <path-to-template-file> \
--parameters parameter-name1 <parameter-value1> parameter-name2 <parameter-value2>
```

#### [sub-level](sub-level) Subscription based deployments
* https://docs.microsoft.com/en-us/azure/azure-resource-manager/deploy-to-subscription
* https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy-cli
```
az deployment create \
--name <deployment-name> \
--location <region> \
--template-file <path-to-template-file> \
--parameters parameter-name1 <parameter-value1> parameter-name2 <parameter-value2> \
--subscription <subscriptionId>
```
