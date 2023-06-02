You can create the policy definition using a command like in windows:

```az policy definition create --name "Preview-AKS-Monitoring-Addon-MSI" --display-name "Preview-AKS-Monitoring-Addon-MSI" --mode Indexed --metadata version=1.0.0 category=Kubernetes --rules .\azure-policy.rules.json --params .\azure-policy.parameters.json```

For linux or wsl environment, change the backward slash to forward slash.

You can Create the policy assignment with the following command like :

```az policy assignment create --name aks-monitoring-addon --policy "Preview-AKS-Monitoring-Addon-MSI" --assign-identity --identity-scope /subscriptions/<subscriptionId> --role Contributor --scope /subscriptions/<subscriptionId> --location <location> --role Contributor --scope /subscriptions/<subscriptionId> -p "{ \"workspaceResourceId\": { \"value\":  \"/subscriptions/<subscriptionId>/resourcegroups/<resourceGroupName>/providers/microsoft.operationalinsights/workspaces/<workspaceName>\" } }"```

**NOTE**

- Please download all files under AddonPolicyTemplate folder before running the policy template.
- If you want to assign policy from the portal, follow the below guides:
    - After creating the policy definition through the above command, go to Azure portal -> Policy -> Definitions and select the definition you just created.
    - Click on 'Assign' and then go to the 'Parameters' tab and fill in the details. Then click 'Review + Create'.
    - Now that the policy is assigned to the subscription, whenever you create a new cluster which does not have container insights enabled, the policy will run and deploy the resources. If you want to apply the policy to existing AKS cluster, create a 'Remediation task' for that resource after going to the 'Policy Assignment'.
