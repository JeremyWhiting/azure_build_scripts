Param (
    
    #Here we are creating a template object that holds the parameters.
    #The commented out sections are the default values that come from the JSON template
    #If sections need to change from the default then uncomment and make the modifications

    $TemplateParameterObject = [ordered]@{
             coreDeviceId       = '814823';
             #bastionId          = '1';                 #Default is 1.  Can be more in the event the customer has more than one bastion
             operatingSystem    = 'Windows';           #Allowed values are Windows or Linux
             #environment        = 'Bastion';           #Default is Bastion. Allowed values are Production, Staging, Test, Development, Q/A, Bastion, Other
             buildDate          = (Get-Date -format d).toString();
             buildBy            = $env:USERNAME;
    }


)

$Metadata = @{
                    Builder = $env:USERNAME;
                          
             }

$locationlist = $null
$subscriptionlist = $null
$ResourceGrouplist = $null
$deploymentName = "RackBastion" + (Get-Random -minimum 1 -maximum 99999)
$shortpadspace = 7
$longpadspace = 20


cls
Write-Host "Getting ready to the Rackspace bastion"
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
    #Write-Host $question
    $subscription = read-host $question
    $subscription = $subscriptionlist[$subscription]
 

    $selectedsubscription = Select-AzureRmSubscription -SubscriptionId $subscription.SubscriptionId
        
    $Metadata['SubscriptionID'] = $subscription.SubscriptionId
    $Metadata['SubscriptionName'] = $subscription.SubscriptionName

    }

    catch{
    Write-host "Couldn't set subscription"
    exit -2
    }

    Write-Host "Collecting location information..."
    try{
        $locationlist = Get-AzureRmLocation | select -Property DisplayName
 
        $question = "`tAvailable Locations`r`n------------------------------`r`n"

        for ($i = 0;$i -lt $locationlist.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $locationlist[$i].DisplayName + "`r`n")
        }

        $question += "Which Location would you like?"
        #Write-Host $question
        $locationNum = Read-Host $question
        $location = Get-AzureRmLocation | Where-Object {$_.DisplayName -eq $locationlist[$locationNum].DisplayName }
            

        $Metadata['Location'] = $location.DisplayName
    }

    catch{
            write-host "Couldn't set location."
            exit -2
    }

    Write-Host "Collecting Resource Group information..."
    try{
        $ResourceGrouplist = Get-AzureRmResourceGroup | select -Property ResourceGroupName
 
        $question = "`tAvailable Resource Groups`r`n------------------------------`r`n"

        for ($i = 0;$i -lt $ResourceGrouplist.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $ResourceGrouplist[$i].ResourceGroupName + "`r`n")
        }

        $question += "Which Resource Group would you like to use?"
        #Write-Host $question
        $ResourceGroupNum = Read-Host $question
        $ResourceGroup = Get-AzureRmResourceGroup | Where-Object {$_.ResourceGroupName -eq $ResourceGrouplist[$ResourceGroupNum].ResourceGroupName }
            

        $Metadata['RSG'] = $ResourceGroup.ResourceGroupName
    }

    catch{
            write-host "Couldn't set Resource Group Resource."
            exit -2
    }

    Write-Host "Collecting VNet information..."
    try{
        $VNetlist = Get-AzureRmVirtualNetwork | sort Name
 
        $question = "`tAvailable VNets`r`n------------------------------`r`n"

        for ($i = 0;$i -lt $VNetlist.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $VNetlist[$i].Name + "`r`n")
        }

        $question += "Which VNet would you like?"
        #Write-Host $question
        $VNetNum = Read-Host $question
        $VNet = Get-AzureRmVirtualNetwork | Where-Object {$_.Name -eq $VNetlist[$VNetNum].Name }
            

        $Metadata['VNet'] = $Vnet.Name
        $Metadata['VNetRG'] = $Vnet.ResourceGroupName
    }

    catch{
            write-host "Couldn't set VNet."
            exit -2
    }

    Write-Host "Collecting Subnet information..."
    try{
        $Subnetlist = Get-AzureRmVirtualNetwork | where {$_.Name -eq $MetaData['VNet']} | select -Property subnets
 
        $question = "`tAvailable Subnets`r`n------------------------------`r`n"

        for ($i = 0;$i -lt $Subnetlist.Subnets.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $Subnetlist.Subnets[$i].Name + "`r`n")
        }

        $question += "Which Subnet would you like to use?"
        #Write-Host $question
        $SubnetNum = Read-Host $question
        $Subnet = $Subnetlist.Subnets[$SubnetNum].Name
           
        $Metadata['Subnet'] = $Subnet
    }

    catch{
            write-host "Couldn't set Subnet."
            exit -2
    }

    write-host ("Subscription ID:".PadRight($longpadspace) + $Metadata['SubscriptionID'])
    write-host ("Subscription Name:".PadRight($longpadspace) + $Metadata['SubscriptionName'])
    write-host ("Resource Group:".PadRight($longpadspace) + $Metadata['RSG'])
    write-host ("Location:".PadRight($longpadspace) + $Metadata['Location'])
    write-host ("Vnet:".PadRight($longpadspace) + $Metadata['Vnet'])
    write-host ("Subnet:".PadRight($longpadspace) + $Metadata['Subnet'])
    
    $RetVal = Read-Host "Is this correct (y/n)?"

    if (($RetVal.ToLower() -eq 'y')-or ($RetVal.ToLower() -eq 'yes')) {$Done = $true}

} while ($Done -ne $true)


Function CreateRackspaceBastion{
    cls

    $TemplateParameterObject.Add("virtualNetworkRGName", $Metadata['VNetRG'])
    $TemplateParameterObject.Add("virtualNetworkName", $MetaData['VNet'])
    $TemplateParameterObject.Add("subnetName", $Metadata['Subnet'])
       
    try{
            write-host "Creating Rackspace Bastion..."
            New-AzureRmResourceGroupDeployment -Name $deploymentName `
                            -ResourceGroupName $Metadata['RSG'] `
                            -Mode Incremental `
                            -TemplateParameterObject $TemplateParameterObject `
                            -TemplateUri "https://vmqcresources.blob.core.windows.net/templates/bastion/bastion.json" `
                            -Force
                              
    }
    Catch{
            Write-Host "Couldn't deploy Rackspace Bastion"
            exit -2
    }
            
           

        $ops = get-azurermresourcegroupdeploymentoperation -ResourceGroupName $Metadata['RSG'] -deploymentname $deploymentName
        foreach($op in $ops.properties)
        {
            $op
        }

}
    
        
CreateRackspaceBastion