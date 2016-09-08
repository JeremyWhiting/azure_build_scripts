Param (
    
    #Here we are creating a template object that holds the parameters.
    #The commented out sections are the default values that come from the JSON template
    #If sections need to change from the default then uncomment and make the modifications


    #!!!!!!!!!!!!!!!!!!!!!Make sure at look at parameters I.E VNET name and IP ranges!!!!!!!!!
    $TemplateParameterObjectMed = [ordered]@{
            recommendedRSGName = 'LOC-RSG-RAX-ENV';      #Don't worry about this one
            virtualNetworkName = 'VNET01';              #Default value VNet01, will append region so end result will be [LOC]-VNet01
            virtualNetworkCIDR = '172.16.192.0/21';     #Default value is 172.16.192.0/21
            environmentA       = 'Production';          #Default value is Production.  Allowed values Production, Staging, Test, Development, Q/A, Other
            subnetDMZCIDRA     = '172.16.192.0/24';     #Default value is 172.16.192.0/24
            subnetAPPCIDRA     = '172.16.193.0/24';     #Default value is 172.16.193.0/24
            subnetINSCIDRA     = '172.16.194.0/24';     #Default value is 172.16.194.0/24
            subnetADCIDRA      = '172.16.195.0/28';     #Default value is 172.16.195.0/28
            subnetBASCIDR      = '172.16.195.16/28';    #Default value is 172.16.195.16/28
            subnetGWCIDR       = '172.16.195.224/28';   #Default value is 172.16.195.224/28
            environmentB       = 'Staging';             #NO Default value.  Available values Production, Staging, Test, Development, Q/A, Other
            subnetDMZCIDRB     = '172.16.196.0/24';     #Default value is 172.16.196.0/24
            subnetAPPCIDRB     = '172.16.197.0/24';     #Default value is 172.16.197.0/24
            subnetINSCIDRB     = '172.16.198.0/24';     #Default value is 172.16.198.0/24
            subnetADCIDRB      = '172.16.195.32/28';    #Default value is 172.16.195.32/28
            buildDate          = (Get-Date -format d).toString();
            buildBy            = $env:USERNAME;
    },

    $TemplateParameterObjectSmall = [ordered]@{
            recommendedRSGName = 'LOC-RSG-RAX-ENV';      #Don't worry about this one
            virtualNetworkName = 'VNET01';              #Default value VNet01, will append region so end result will be [LOC]-VNet01
            virtualNetworkCIDR = '10.137.208.0/22';     #Default value is 172.16.192.0/21
            environmentA       = 'Production';          #Default value is Production.  Allowed values Production, Staging, Test, Development, Q/A, Other
            subnetDMZCIDRA     = '10.137.208.0/24';     #Default value is 172.16.192.0/24
            subnetAPPCIDRA     = '10.137.209.0/24';     #Default value is 172.16.193.0/24
            subnetINSCIDRA     = '10.137.210.0/24';     #Default value is 172.16.194.0/24
            subnetADCIDRA      = '10.137.211.0/28';     #Default value is 172.16.195.0/28
            subnetBASCIDR      = '10.137.211.16/28';    #Default value is 172.16.195.16/28
            subnetGWCIDR       = '10.137.211.224/28';   #Default value is 172.16.195.224/28
            buildDate          = (Get-Date -format d).toString();
            buildBy            = $env:USERNAME;
    }
)

$Metadata = @{
                    Builder = $env:USERNAME;
                          
             }

$EnvironmentSizelist = 'Small', 'Medium', 'Large'
$subscriptionlist = $null
$ResourceGrouplist = $null
$deploymentName = "RackVnet" + (Get-Random -minimum 1 -maximum 99999)
$shortpadspace = 7
$longpadspace = 20


cls
Write-Host "Getting ready to create customer VNet, Subnets and NSGs..."
$ErrorActionPreference = 'Stop'

Write-Host "Validating Azure Accounts..."
try{
    $subscriptionlist = Get-AzureRmSubscription
}
catch {
    Write-Host "Reauthenticating..."
    Login-AzureRmAccount | Out-Null
}

Write-Host "Collecting Subscription information..."
Do  {
    $Done = $false

    try{
        $subscriptionlist = Get-AzureRmSubscription | sort SubscriptionName
        $question = "`tAvailable Subscriptions`r`n------------------------------`r`n"
    
        for ($i = 0;$i -lt $subscriptionlist.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $subscriptionlist[$i].SubscriptionName + "`r`n")
    }

    $question += "Which Subscription would you like to use?"
    Write-Host $question
    $subscription = read-host
    $subscription = $subscriptionlist[$subscription]
 

    $selectedsubscription = Select-AzureRmSubscription -SubscriptionId $subscription.SubscriptionId
        
    $Metadata['SubscriptionID'] = $subscription.SubscriptionId
    $Metadata['SubscriptionName'] = $subscription.SubscriptionName

    }

    catch{
    Write-host "Couldn't set subscription"
    exit -2
    }


    Write-Host "Collecting Resource Group information..."
    try{
        $ResourceGrouplist = Get-AzureRmResourceGroup | select -Property ResourceGroupName
 
        $question = "`tAvailable Resource Groups`r`n------------------------------`r`n"

        for ($i = 0;$i -lt $ResourceGrouplist.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $ResourceGrouplist[$i].ResourceGroupName + "`r`n")
        }

        $question += "Which VNET Size would you like to use?"
        Write-Host $question
        $ResourceGroupNum = Read-Host
        $ResourceGroup = Get-AzureRmResourceGroup | Where-Object {$_.ResourceGroupName -eq $ResourceGrouplist[$ResourceGroupNum].ResourceGroupName }
            

        $Metadata['RSG'] = $ResourceGroup.ResourceGroupName
    }

    catch{
            write-host "Couldn't set VNET Size."
            exit -2
    }


     try{
 
        $question = "`tAvailable Environment Sizes`r`n------------------------------`r`n"

        for ($i = 0;$i -lt $EnvironmentSizeList.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $EnvironmentSizelist[$i] + "`r`n")
        }

        $question += "Which Resource Group would you like to use?"
        Write-Host $question
        $SizeListNum = Read-Host
        $EnvironmentSize = $EnvironmentSizelist[$SizeListNum]
            

        $Metadata['EnvSize'] = $EnvironmentSize
    }

    catch{
            write-host "Couldn't Set Environment Size"
            exit -2
    }

    write-host ("Subscription ID:".PadRight($longpadspace) + $Metadata['SubscriptionID'])
    write-host ("Subscription Name:".PadRight($longpadspace) + $Metadata['SubscriptionName'])
    write-host ("Resource Group:".PadRight($longpadspace) + $Metadata['RSG'])
    write-host ("Environment Size:".PadRight($longpadspace) + $Metadata['EnvSize'])
    
    $RetVal = Read-Host "Is this correct (y/n)?"

    if (($RetVal.ToLower() -eq 'y')-or ($RetVal.ToLower() -eq 'yes')) {$Done = $true}

} while ($Done -ne $true)


Function CreateVNetandSubnets{
    cls
    
        Switch($metadata['EnvSize'])
        { 
            "Small" {
                        try{
                                write-host "Starting Vnet deployment..."
                                New-AzureRmResourceGroupDeployment -Name $deploymentName `
                                               -ResourceGroupName $Metadata['RSG'] `
                                               -Mode Incremental `
                                               -TemplateParameterObject $TemplateParameterObjectSmall `
                                               -TemplateUri "https://vmqcresources.blob.core.windows.net/templates/network/network-small.json" `
                                               -Force
                            
                        }
                        Catch{
                                Write-Host "Coudn't deploy Vnet"
                                exit -2
                        }
             }
                   
            "Medium" {
        
                        try{
                                write-host "Starting Vnet deployment..."
                                New-AzureRmResourceGroupDeployment -Name $deploymentName `
                                               -ResourceGroupName $Metadata['RSG'] `
                                               -Mode Incremental `
                                               -TemplateParameterObject $TemplateParameterObjectMed `
                                               -TemplateUri "https://vmqcresources.blob.core.windows.net/templates/network/network-medium.json" `
                                               -Force
                            
                        }
                        Catch{
                                Write-Host "Coudn't deploy Vnet"
                                exit -2
                        }
            } 
            "Large" {"You chose large."} 
            default {"Environment Size could not be determined"}
        }

        $ops = get-azurermresourcegroupdeploymentoperation -ResourceGroupName $Metadata['RSG'] -deploymentname $deploymentName
        foreach($op in $ops.properties)
        {
            $op
        }

}
    
        
CreateVnetandSubnets