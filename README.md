# Azure templates
Templates for consumption

[rg-level](rg-level) Resource group deployments
- https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy-cli
```
az group deployment create \
--resource-group <resource-group-name> \
--template-file <path-to-template-file> \
--parameters parameter-name1 <parameter-value1> parameter-name2 <parameter-value2>
```

[sub-level](sub-level) Subscription based deployments
- https://docs.microsoft.com/en-us/azure/azure-resource-manager/deploy-to-subscription
- https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy-cli
```
az deployment create \
--name <deployment-name> \
--location <region> \
--template-file <path-to-template-file> \
--parameters parameter-name1 <parameter-value1> parameter-name2 <parameter-value2> \
--subscription <subscriptionId>
```
