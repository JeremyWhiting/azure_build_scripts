#VM's being attached must be in same Subscription and Resource Group 
<#  Changes
        $VMNames = Get-AzureRmVm -ResourceGroupName $ResourceGroup.ResourceGroupName |Select-Object -ExpandProperty Name; 

#>

Param (
    
    $CoreDevice = '802787',
    $OMSWorkspaceName = $CoreDevice + "-OMS",
    $VMNames = ('evftp01')

)

$Metadata = @{
                    Builder = $env:USERNAME;
                          
             }

$subscriptionlist = $null
$ResourceGrouplist = $null
$shortpadspace = 7
$longpadspace = 20
$ErrorActionPreference = 'Stop'

Write-Host "Validating Azure Accounts..."
try{
    $subscriptionlist = Get-AzureRmSubscription
}
catch {
    Write-Host "Reauthenticating..."
    Login-AzureRmAccount | Out-Null
}


Do  {
    $Done = $false
    cls
    Write-Host "Collecting Subscription information..."
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

    cls
    Write-Host "Collecting OMS Workspace Resource Group information..."
    try{
        $ResourceGrouplist = Get-AzureRmResourceGroup | select -Property ResourceGroupName
 
        $question = "`tAvailable OMS Resource Groups`r`n------------------------------`r`n"

        for ($i = 0;$i -lt $ResourceGrouplist.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $ResourceGrouplist[$i].ResourceGroupName + "`r`n")
        }

        $question += "Which Resource Group would you like to use?"
        $ResourceGroupNum = Read-Host $question
        $ResourceGroup = Get-AzureRmResourceGroup | Where-Object {$_.ResourceGroupName -eq $ResourceGrouplist[$ResourceGroupNum].ResourceGroupName }
            

        $Metadata['OMSRSG'] = $ResourceGroup.ResourceGroupName
    }

    catch{
            write-host "Couldn't set Resource Group Resource."
            exit -2
    }

    cls
    Write-Host "Collecting VM Resource Group information..."
    try{
        $ResourceGrouplist = Get-AzureRmResourceGroup | select -Property ResourceGroupName
 
        $question = "`tAvailable VM Resource Groups`r`n------------------------------`r`n"

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
    
    try{

        $MetaData['WorkspaceID'] = (Get-AzureRmOperationalInsightsWorkspace -Name $OMSWorkspaceName -ResourceGroupName $Metadata['OMSRSG']).CustomerId
        $MetaData['WorkspaceKey'] = (Get-AzureRmOperationalInsightsWorkspaceSharedKeys -Name $OMSWorkspaceName -ResourceGroupName $Metadata['OMSRSG']).PrimarySharedKey
    }
    catch{
            write-host "Couldn't find OMS workspace"
            exit -2
    }

    cls
    write-host ("Subscription ID:".PadRight($longpadspace) + $Metadata['SubscriptionID'])
    write-host ("Subscription Name:".PadRight($longpadspace) + $Metadata['SubscriptionName'])
    Write-Host ("OMS Resource Group:".PadRight($longpadspace) + $Metadata['OMSRSG'])
    Write-Host ("VM Resource Group:".PadRight($longpadspace) + $Metadata['RSG'])
    write-host ("Workspace Name:".PadRight($longpadspace) + $OMSWorkspaceName)
    write-Host ("Workspace ID:".PadRight($longpadspace) + $Metadata['WorkspaceID'].ToString())
    Write-Host ("Workspace Key:".PadRight($longpadspace) + $Metadata['WorkspaceKey'].ToString())
    Write-Host ("VM names:".PadRight($longpadspace) + $VMNames)
    
    $RetVal = Read-Host "Is this correct (y/n)?"

    if (($RetVal.ToLower() -eq 'y')-or ($RetVal.ToLower() -eq 'yes')) {$Done = $true}

} while ($Done -ne $true)


Function ConnetVMtoOMSWorkspace{
    cls
       
    try{
           foreach($VMName in $VMNames){
                Write-Host "Connecting $VMName to OMS workspace"
                $vm = Get-AzureRMVM -ResourceGroupName $Metadata['RSG'] -Name $VMName
                $location = $vm.Location
                $workSpaceID = $Metadata['WorkspaceID']
                $workSpaceKey = $Metadata['WorkspaceKey']

           
                Set-AzureRMVMExtension -ResourceGroupName $Metadata['RSG'] -VMName $VMname -Name 'MicrosoftMonitoringAgent' -Publisher 'Microsoft.EnterpriseCloud.Monitoring' `
                                        -ExtensionType 'MicrosoftMonitoringAgent' -TypeHandlerVersion '1.0' -Location $location `
                                        -SettingString "{'workspaceId': '$workSpaceID'}" -ProtectedSettingString "{'workspaceKey': '$workSpaceKey'}"
           }                  
    }
    Catch{
            Write-Host "Couldn't deploy OMS Workspace"
            exit -2
    }
}
    
        
ConnetVMtoOMSWorkspace