Param (
    
    $RecoveryVaultName = "EU2-RSV01",
    $VMNames = ('evftp01'),

    $PolicyName="BKP-POL-DAILY2AM-RET-7D4W",
    $BackupTime ="02:00AM" #hh:mm(AM/PM) 




)

$Metadata = @{
                    Builder = $env:USERNAME;
                          
             }

$subscriptionlist = $null
$ResourceGrouplist = $null
$shortpadspace = 7
$longpadspace = 20
$ErrorActionPreference = 'Stop'
$locationlist = $null

function createRecoveryVault{
    
    cls
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

    try{
         Write-Host "Creating recovery vault named $RecoveryVaultName.."
         Register-AzureRmResourceProvider -ProviderNamespace Microsoft.RecoveryServices
         $Metadata['RSVault'] = New-AzureRmRecoveryServicesVault -Name $RecoveryVaultName -Location $Metadata['Location'] -ResourceGroupName $Metadata['RVRSG']
    }
    catch{
            write-host "Couldn't create recovery Vault"
            exit -2

    }

}


Write-Host "Validating Azure Accounts..."
try{
    $subscriptionlist = Get-AzureRmSubscription
}
catch {
    Write-Host "Reauthenticating..."
    Login-AzureRmAccount | Out-Null
}


Do {
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
    Write-Host "Collecting Recovery Vault Resource Group information..."
    try{
        $ResourceGrouplist = Get-AzureRmResourceGroup | select -Property ResourceGroupName
 
        $question = "`tAvailable Resource Groups`r`n------------------------------`r`n"

        for ($i = 0;$i -lt $ResourceGrouplist.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $ResourceGrouplist[$i].ResourceGroupName + "`r`n")
        }

        $question += "Which Resource Group would you like to use?"
        $ResourceGroupNum = Read-Host $question
        $ResourceGroup = Get-AzureRmResourceGroup | Where-Object {$_.ResourceGroupName -eq $ResourceGrouplist[$ResourceGroupNum].ResourceGroupName }
            

        $Metadata['RVRSG'] = $ResourceGroup.ResourceGroupName
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
    

 

    Write-Host "Finding existing Recovery Vaults...."
    try{
            $recoveryServicesVaults = Get-AzureRmRecoveryServicesVault

            $createRSV = Read-Host "Would you like to create an RSV (y/n)?"

            if($recoveryServicesVaults.Count -eq 0 -or $createRSV.ToLower() -eq 'y'){
                Write-Host "There are no vaults available in the subscription."
                        
                $createRecoveryVault = Read-Host "Would you like to create one (y/n)?"
                if (($createRecoveryVault.ToLower() -eq 'y')-or ($createRecoveryVault.ToLower() -eq 'yes')) {
                    $VaultCreationReturn = createRecoveryVault
                }
                else{
                    exit -2
                }
            }
            
            else{
                $question = "`tAvailable VM Resource Groups`r`n------------------------------`r`n"

                for ($i = 0;$i -lt $recoveryServicesVaults.Count; $i++){
                    $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $recoveryServicesVaults[$i].Name + "`r`n")
                }

                $question += "Which Recovery Vault would you like to use?"
                $RVNum = Read-Host $question
                $Metadata['RSVault'] = $recoveryServicesVaults[$RVNum]
            }
    }
    catch{
            write-host "Couldn't find Recovery Vault"
            exit -2

    }


    cls
    write-host ("Subscription ID:".PadRight($longpadspace) + $Metadata['SubscriptionID'])
    write-host ("Subscription Name:".PadRight($longpadspace) + $Metadata['SubscriptionName'])
    Write-Host ("VM Resource Group:".PadRight($longpadspace) + $Metadata['RVRSG'])
    write-host ("RS Vault:".PadRight($longpadspace) + $Metadata['RSVault'].Name)
    write-host ("VM Resource Group:".PadRight($longpadspace) + $Metadata['RSG'])
    Write-Host ("VM names:".PadRight($longpadspace) + $VMNames)
    
    $RetVal = Read-Host "Is this correct (y/n)?"

    if (($RetVal.ToLower() -eq 'y')-or ($RetVal.ToLower() -eq 'yes')) {$Done = $true}

}while($Done -ne $true)

Function addServerstoRSV{
    cls
    write-host "Creating policy and adding servers to Recovery Vault..."
    try{

        Set-AzureRmRecoveryServicesVaultContext -Vault $Metadata['RSVault']

        $backupScheduledDate = [datetime]::ParseExact($BackupTime,"hh:mmtt",$null)
        #$backupScheduledDate = $backupScheduledDate.AddHours(-5)


        $schPol = Get-AzureRmRecoveryServicesBackupSchedulePolicyObject -WorkloadType "AzureVM" -BackupManagementType AzureVM
        $retPol = Get-AzureRmRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM" -BackupManagementType AzureVM
        $retPol.IsMonthlyScheduleEnabled = $false
        $retPol.IsYearlyScheduleEnabled = $false
        #$retPol.IsWeeklyScheduleEnabled = $true
        $retPol.MonthlySchedule = $null
        $retPol.WeeklySchedule.DurationCountinWeeks = 4
        #$retpol.WeeklySchedule.RetentionTimes.Clear()
        #$retpol.WeeklySchedule.RetentionTimes.Add($
        $retPol.YearlySchedule = $null
        $retPol.DailySchedule.DurationCountInDays = 7
        #$retPol.DailySchedule.RetentionTimes.Clear()
        #$retPol.DailySchedule.RetentionTimes.Add($backupScheduledDate.ToUniversalTime())
        $schPol.ScheduleRunTimes.Clear()
        $schPol.ScheduleRunTimes.Add($backupScheduledDate.ToUniversalTime())
        $schPol.ScheduleRunDays   

    }
    catch{
            write-host "Error creating Recovery Vault Policy"
            exit -2

    }

    try{
        $pol=Get-AzureRmRecoveryServicesBackupProtectionPolicy -Name $PolicyName
    }
    Catch{
        $pol="not found"
    }
    try{
        if ($pol -eq "not found"){
            New-AzureRmRecoveryServicesBackupProtectionPolicy -Name $PolicyName -WorkloadType AzureVM -RetentionPolicy $retPol -SchedulePolicy $schPol
            $pol=Get-AzureRmRecoveryServicesBackupProtectionPolicy -Name $PolicyName
        }
    }
    catch{
                write-host "Error adding Policy to recovery vault"
                exit -2
    }
    try{
        foreach($vmName in $vmnames){
            Enable-AzureRmRecoveryServicesBackupProtection -Policy $pol -ResourceGroupName $Metadata['RSG'] -Name $vmName
        }
    }
    catch{

            write-host "Error adding servers to recovery vault"
            exit -2
    }
}


addServerstoRSV









