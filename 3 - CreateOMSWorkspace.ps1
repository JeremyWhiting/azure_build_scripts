Param (
    
    #Here we are creating a template object that holds the parameters.
    #The commented out sections are the default values that come from the JSON template
    #If sections need to change from the default then uncomment and make the modifications

    $TemplateParameterObject = [ordered]@{           
             buildDate          = (Get-Date -format d).toString();
             buildBy            = $env:USERNAME;
    },

    $locationlist = ("East US","West Europe","Southeast Asia","Australia Southeast"),
    $STList = ("Standard","Premium"),
    $CoreDevice = '814818'

)

$Metadata = @{
                    Builder = $env:USERNAME;
                          
             }

$subscriptionlist = $null
$ResourceGrouplist = $null
$deploymentName = "RackOMS" + (Get-Random -minimum 1 -maximum 99999)
$shortpadspace = 7
$longpadspace = 20
$outfiledirectory = "C:\Users\JeremyWhiting\Box Sync\azure\Customer Builds\HubInternational\HubInternational-$deploymentName.log"


cls
Write-Host "Getting ready to create the OMS workspace"
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
 
        $question = "`tAvailable Locations`r`n------------------------------`r`n"

        for ($i = 0;$i -lt $locationlist.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $locationlist[$i] + "`r`n")
        }

        $question += "Which Location would you like?"
        $locationNum = Read-Host $question
        $location = $locationlist[$locationNum]
            
        $Metadata['location'] = $location
        $TemplateParameterObject.Add("location",$Metadata['location'])
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
        $ResourceGroupNum = Read-Host $question
        $ResourceGroup = Get-AzureRmResourceGroup | Where-Object {$_.ResourceGroupName -eq $ResourceGrouplist[$ResourceGroupNum].ResourceGroupName }
            

        $Metadata['RSG'] = $ResourceGroup.ResourceGroupName
    }

    catch{
            write-host "Couldn't set Resource Group Resource."
            exit -2
    }

    Write-Host "Collecting OMS Service Tier information..."

    $question = "'tAvailable OMS Service Tiers`r`n------------------------------`r`n"

     for ($i = 0;$i -lt $STList.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $STList[$i] + "`r`n")
        }

    $question += "Which Resource Group would you like to use?"
    $STNum = Read-Host $question
    $Metadata['serviceTier'] = $STList[$STNum]
    $TemplateParameterObject.Add("serviceTier",$Metadata['serviceTier'])
            

    $Metadata['workspaceName'] = $CoreDevice + "-OMS"
    $TemplateParameterObject.Add("workspaceName",$Metadata['workspaceName'])

    cls
    write-host ("Subscription ID:".PadRight($longpadspace) + $Metadata['SubscriptionID'])
    write-host ("Subscription Name:".PadRight($longpadspace) + $Metadata['SubscriptionName'])
    write-host ("Location:".PadRight($longpadspace) + $Metadata['location'])
    Write-Host ("Resource Group:".PadRight($longpadspace) + $Metadata['RSG'])
    Write-Host ("Service Tier:".PadRight($longpadspace) + $Metadata['serviceTier'])
    write-host ("Workspace Name:".PadRight($longpadspace) + $Metadata['workspaceName'])
    
    $RetVal = Read-Host "Is this correct (y/n)?"

    if (($RetVal.ToLower() -eq 'y')-or ($RetVal.ToLower() -eq 'yes')) {$Done = $true}

} while ($Done -ne $true)


Function CreateOMSWorkspace{
    cls
       
    try{
            write-host "Creating OMS Workspace..."
            New-AzureRmResourceGroupDeployment -Name $deploymentName `
                            -ResourceGroupName $Metadata['RSG'] `
                            -Mode Incremental `
                            -TemplateParameterObject $TemplateParameterObject `
                            -TemplateUri "https://vmqcresources.blob.core.windows.net/templates/monitoring/oms-workspace.json" `
                            -Force
                              
    }
    Catch{
            Write-Host "Couldn't deploy OMS Workspace"
            exit -2
    }
            
           

        $ops = get-azurermresourcegroupdeploymentoperation -ResourceGroupName $Metadata['RSG'] -deploymentname $deploymentName
        foreach($op in $ops.properties)
        {
            $op | out-file $outfiledirectory -Append
        }

}
    
        
CreateOMSWorkspace