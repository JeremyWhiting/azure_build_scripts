Param (

#Naming Standard for RSG's is [LOC]-RSG-[ALL-RAX-CLT]-[ENV]
#The below variables in the "Param" section should come from the customer documentation, single region only

    
    
    $ResourceGroupNameList = ('WU2-RSG-ALL','WU2-RSG-CLT-DR','WU2-RSG-RAX-BAS')


)
$Metadata = @{
                    Builder = $env:USERNAME;
                    RSGList = $ResourceGroupNameList
             }
$subscriptionlist = $null
$locationlist = $null
$shortpadspace = 7
$longpadspace = 20


cls
Write-Host "Getting ready to create customer resource groups..."
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
        Write-Host $question
        $locationNum = Read-Host
        $location = Get-AzureRmLocation | Where-Object {$_.DisplayName -eq $locationlist[$locationNum].DisplayName }
            

        $Metadata['Location'] = $location.DisplayName
    }

    catch{
            write-host "Couldn't set location."
            exit -2
    }

    write-host ("Subscription ID:".PadRight($longpadspace) + $Metadata['SubscriptionID'])
    write-host ("Subscription Name:".PadRight($longpadspace) + $Metadata['SubscriptionName'])
    write-host ("Location:".PadRight($longpadspace) + $Metadata['Location'])
    foreach($RSG in $Metadata['RSGList'])
    {
        Write-Host ("RSGs:".PadRight($longpadspace) + $RSG)
    }
    
    $RetVal = Read-Host "Is this correct (y/n)?"

    if (($RetVal.ToLower() -eq 'y')-or ($RetVal.ToLower() -eq 'yes')) {$Done = $true}

} while ($Done -ne $true)


Function CreateResourceGroups{
    cls

    ForEach ($RSG in $Metadata['RSGList']){

        Try{
            Write-Host "Creating Resource Group: $RSG"
            New-AzureRmResourceGroup -Name $RSG -Location $Metadata['Location']
        }
        Catch{
            Write-Host "Couldn't create RSGs"
            exit -2
        }
    }
}
        
CreateResourceGroups
