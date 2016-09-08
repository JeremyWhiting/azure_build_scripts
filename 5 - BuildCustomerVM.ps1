Param (
    
    #Here we are creating a template object that holds the parameters.
    #The commented out sections are the default values that come from the JSON template
    #If sections need to change from the default then uncomment and make the modifications

    $TemplateParameterObject = [ordered]@{
             #recommendedRSGName       = "LOC-RSG-CLT-ENV";     #Default value is [LOC]-RSG-CLT-[ENV]
             coreDeviceId       = "802787";              #Get this in Core
             environment        = 'Production';           #Default is Production. Allowed values are Production, Staging, Test, Development, Q/A, Other
             buildDate          = (Get-Date -format d).toString();
             buildBy            = $env:USERNAME;
    },

    $AVSetOptions = ("New","None","Existing"),
    $SAOptions = ("New", "Existing"),
    $ADOptions = ("No", "Yes"),
    $OSOptions = ("Windows Server 2012 R2", "Windows Server 2008 R2 SP1", "Windows SQL Server 2014 SP1 Standard", "Windows SQL Server 2014 SP1 Standard - BYOL", "Windows SQL Server 2014 Express Edition", "Windows SQL Server 2012 SP3 Standard",
                 "Windows SQL Server 2008 SP3 Standard", "Linux - Centos 7", "Linux - Redhat 7", "Linux - Ubuntu 14.04 LTS", "Linux - Ubuntu 15.04"),
    $LBOptions = ("None","Internal", "External"),
    $SATypeOptions = ("Standard_LRS","Standard_GRS","Standard_RAGRS","Standard_ZRS","Premium_LRS"),
    $WebServerOptions = ("Windows - IIS","Linux - Apache","Linux - Nginx","None")

)

$Metadata = @{
                    Builder = $env:USERNAME;
                          
             }

$locationlist = $null
$subscriptionlist = $null
$ResourceGrouplist = $null
$deploymentName = "CustomerVMs" + (Get-Random -minimum 1 -maximum 99999)
$shortpadspace = 7
$longpadspace = 20
$outfiledirectory = "C:\Users\JeremyWhiting\Box Sync\azure\Customer Builds\HubInternational\HubInternational-$deploymentName.log"

cls
#Write-Host "Getting ready to the Rackspace bastion"
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

    cls
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

    cls
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
            

        $Metadata['virtualNetworkName'] = $Vnet.Name
        $Metadata['virtualNetworkRGName'] = $Vnet.ResourceGroupName
        $TemplateParameterObject.Add("virtualNetworkRGName",$Metadata['virtualNetworkRGName'])
        $TemplateParameterObject.Add("virtualNetworkName",$Metadata['virtualNetworkName'])
    }

    catch{
            write-host "Couldn't set VNet."
            exit -2
    }

    cls
    Write-Host "Collecting Subnet information..."
    try{
        $Subnetlist = Get-AzureRmVirtualNetwork | where {$_.Name -eq $MetaData['virtualNetworkName']} | select -Property subnets
 
        $question = "`tAvailable Subnets`r`n------------------------------`r`n"

        for ($i = 0;$i -lt $Subnetlist.Subnets.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $Subnetlist.Subnets[$i].Name + "`r`n")
        }

        $question += "Which Subnet would you like to use?"
        #Write-Host $question
        $SubnetNum = Read-Host $question
        $Subnet = $Subnetlist.Subnets[$SubnetNum].Name
           
        $Metadata['subnetName'] = $Subnet
        $TemplateParameterObject.Add("subnetName",$Metadata['subnetName'])
    }

    catch{
            write-host "Couldn't set Subnet."
            exit -2
    }

    cls
    Write-Host "Collecting Availability Set Option information..."
    $question = "`tAvailability Set options`r`n------------------------------`r`n"
    for ($i = 0;$i -lt $AVSetOptions.Count; $i++) {
        $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $AVSetOptions[$i] + "`r`n")
    }
    $question += "Choose an option for Availability Set?"
    #Write-Host $question
    $AVSetNum = Read-Host $question
 
    $Metadata['availabilitySetOption'] = $AVSetOptions[$AVSetNum]
    $TemplateParameterObject.Add("availabilitySetOption",$Metadata['availabilitySetOption'])

    cls
    Write-Host "Collecting Storage Account Option information..."
    $question = "`tStorage Account Options`r`n------------------------------`r`n"
    for ($i = 0;$i -lt $SAOptions.Count; $i++) {
        $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $SAOptions[$i] + "`r`n")
    }
    $question += "Choose an option for Storage Account?"
    #Write-Host $question
    $SANum = Read-Host $question
 
    $Metadata['storageAccountOption'] = $SAOptions[$SANum]
    $TemplateParameterObject.Add("storageAccountOption",$Metadata['storageAccountOption'])

    cls
    Write-Host "Collecting Domain Join Option information..."
    $question = "`tDomain Join options`r`n------------------------------`r`n"
    for ($i = 0;$i -lt $ADOptions.Count; $i++) {
        $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $ADOptions[$i] + "`r`n")
    }
    $question += "Choose an option for Domain Join?"
    #Write-Host $question
    $ADNum = Read-Host $question
 
    $Metadata['joinActiveDirectoryDoamin'] = $ADOptions[$ADNum]
    $TemplateParameterObject.Add("joinActiveDirectoryDoamin",$Metadata['joinActiveDirectoryDoamin'])

    cls
    Write-Host "Collecting Operating System Option information..."
    $question = "`tOperating System options`r`n------------------------------`r`n"
    for ($i = 0;$i -lt $OSOptions.Count; $i++) {
        $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $OSOptions[$i] + "`r`n")
    }
    $question += "Choose an option for Operating System?"
    #Write-Host $question
    $OSNum = Read-Host $question
 
    $Metadata['operatingSystem'] = $OSOptions[$OSNum]
    $TemplateParameterObject.Add("operatingSystem",$Metadata['operatingSystem'])

    cls
    Write-Host "Collecting Load Balancer Option information..."
    $question = "`tLoad Balancer options`r`n------------------------------`r`n"
    for ($i = 0;$i -lt $LBOptions.Count; $i++) {
        $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $LBOptions[$i] + "`r`n")
    }
    $question += "Choose an option for Load Balancer?"
    #Write-Host $question
    $LBNum = Read-Host $question
 
    $Metadata['loadBalancerOption'] = $LBOptions[$LBNum]
    $TemplateParameterObject.Add("loadBalancerOption",$Metadata['loadBalancerOption'])

    cls
    Write-Host "Collecting Web Server Option information..."
    $question = "`tWeb Server options`r`n------------------------------`r`n"
    for ($i = 0;$i -lt $WebServerOptions.Count; $i++) {
        $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $WebServerOptions[$i] + "`r`n")
    }
    $question += "Is this going to be a web server, if so which kind?"

    $WSNum = Read-Host $question
 
    $Metadata['deployWebServer'] = $WebServerOptions[$WSNum]
    $TemplateParameterObject.Add("deployWebServer",$Metadata['deployWebServer'])

    cls
    write-host ("Subscription ID:".PadRight($longpadspace) + $Metadata['SubscriptionID'])
    write-host ("Subscription Name:".PadRight($longpadspace) + $Metadata['SubscriptionName'])
    write-host ("Resource Group:".PadRight($longpadspace) + $Metadata['RSG'])
    write-host ("Vnet:".PadRight($longpadspace) + $Metadata['virtualNetworkName'])
    write-host ("Subnet:".PadRight($longpadspace) + $Metadata['subnetName'])
    write-host ("Availability Set:".PadRight($longpadspace) + $Metadata['availabilitySetOption'])
    write-host ("Storage Account:".PadRight($longpadspace) + $Metadata['storageAccountOption'])
    write-host ("Domain Join:".PadRight($longpadspace) + $Metadata['joinActiveDirectoryDoamin'])
    write-host ("Operating System:".PadRight($longpadspace) + $Metadata['operatingSystem'])
    write-host ("Load Balancer:".PadRight($longpadspace) + $Metadata['loadBalancerOption'])
    Write-Host ("Web Server:".PadRight($longpadspace) + $Metadata['deployWebServer'])
    
    $RetVal = Read-Host "Is this correct (y/n)?"

    if (($RetVal.ToLower() -eq 'y')-or ($RetVal.ToLower() -eq 'yes')) {$Done = $true}

} while ($Done -ne $true)

Do{
    $Done = $false

    cls
  
    Write-Host "Collecting location information..."
    try{
        $locationlist = Get-AzureRmLocation | select -Property DisplayName
 
        $question = "`tAvailable Locations`r`n------------------------------`r`n"

        for ($i = 0;$i -lt $locationlist.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $locationlist[$i].DisplayName + "`r`n")
        }

        $question += "Which Location would you like?"
        $locationNum = Read-Host $question
        $location = Get-AzureRmLocation | Where-Object {$_.DisplayName -eq $locationlist[$locationNum].DisplayName }
            

        $Metadata['Location'] = $location.DisplayName
    }

    catch{
            write-host "Couldn't set location."
            exit -2
    }

    cls
    Write-Host "Collecting Server Size information..."
    try{
        $SSlist = Get-AzureRmVMSize -Location $Metadata['Location'] | select -Property Name
 
        $question = "`tAvailable Machine Sizes for your region`r`n------------------------------`r`n"

        for ($i = 0;$i -lt $SSList.Count; $i++){
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $SSlist[$i].Name + "`r`n")
        }

        $question += "Which Server Size would you like?"
        $SSNum = Read-Host $question
        $ServerSize = $SSList[$SSNum]
            

        $Metadata['vmSize'] = $ServerSize.Name
        $TemplateParameterObject.Add("vmSize",$Metadata['vmSize'])
    }

    catch{
            write-host "Couldn't set server size."
            exit -2
    }
    
    cls
    #Default is "win-iis-"
    #IT will append the incremented numbers after...for example 1, 2, 3
    $MachineName = Read-Host "What Server Name do you want to use"
    $Metadata['vmNamePrefix'] = $MachineName.trim().ToLower()
    $TemplateParameterObject.Add("vmNamePrefix",$Metadata['vmNamePrefix'])

    $VMCount = Read-Host "How many servers are you building in the group (1-99)?"
    $Metadata['vmCount'] = [convert]::ToInt32($VMCount, 10)
    $TemplateParameterObject.Add("vmCount",$Metadata['vmCount'])

    $startindex = Read-Host "The Starting Index for the VM to create (will be used to append a number at the end) (1-99)"
    [int]$intstartIndex = [convert]::ToInt32($startindex,10)
    $Metadata['startIndex'] = $intstartIndex
    $TemplateParameterObject.Add("startIndex",$Metadata['startIndex'])

    $VMDisk = Read-Host "What size would you like the VM Disk (1-1023)?"
    $Metadata['dataDiskSize'] = $VMDisk.Trim()
    $TemplateParameterObject.Add("dataDiskSize",$Metadata['dataDiskSize'])

    if($Metadata['storageAccountOption'] -eq "New"){
        
            cls
            Write-Host "Collecting Storage Account Option information..."
            $question = "`tStorage Account options`r`n------------------------------`r`n"
            for ($i = 0;$i -lt $SATypeOptions.Count; $i++) {
                $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $SATypeOptions[$i] + "`r`n")
            }
            $question += "Choose type of Storage account for your VM's"
          
            $SATypeNum = Read-Host $question
 
            $Metadata['storageAccountType'] = $SATypeOptions[$SATypeNum]
            $TemplateParameterObject.add("storageAccountType", $Metadata['storageAccountType'])

    }


    if($Metadata['availabilitySetOption'] -eq "New"){
        
            cls
            #Default is AS-WEB-PRD
            $AVSetname = Read-Host "What would you like to call your new Availability Set?"
            $Metadata['availabilitySetName'] = $AVSetname.Trim().ToLower()

            
            $TemplateParameterObject.add("availabilitySetName", $Metadata['availabilitySetName'])

    }
    
    elseif($Metadata['availabilitySetOption'] -eq "Existing"){

            $ASlist = Get-AzureRmAvailabilitySet -ResourceGroupName $Metadata['RSG']
 
            $question = "`tAvailability Sets in the selected RSG`r`n------------------------------`r`n"

            for ($i = 0;$i -lt $ASList.Count; $i++){
                    $question +=  ($i.ToString().PadRight($shortpadspace,'-') + $ASlist[$i].Name + "`r`n")
            }

            $question += "Which Availability Set would you like to use?"
 
            $ASNum = Read-Host $question
            $AvailabilitySet = $ASList[$ASNum]
            

            $Metadata['availabilitySetName'] = $AvailabilitySet.Name
            $TemplateParameterObject.add("availabilitySetName", $Metadata['availabilitySetName'])
     }
    
    
    if($Metadata['loadBalancerOption'] -eq "External"){
            
            cls
            $LBName = Read-Host "Specify the dns name to use for the external load balancer.  Must be unique"
 
            $LBName = $LBName.trim().ToLower() + (Get-Random -minimum 1 -maximum 99999).ToString()

            $Metadata['dnsNameExternalLoadBalancer'] = $LBName
            $TemplateParameterObject.add("dnsNameExternalLoadBalancer", $Metadata['dnsNameExternalLoadBalancer'])
    }
    
    if($Metadata['joinActiveDirectoryDoamin'] -eq "Yes"){
         
            cls
            $ADName = Read-Host "Specify the domain name to join:"
            $ADUserName = Read-Host "Specify the domain admin username:"
            $ADPassword = Read-Host "Specify the domain admin password:"
            $ADOU = Read-Host "Type the OU to use when joining this machine to the domain. Leave this blank for default's computers OU:"

            $Metadata['domainToJoin'] = $ADName.Trim().ToLower()
            $Metadata['organizationalUnit'] = $ADOU.Trim().ToLower()
            $Metadata['domainAdminUsername'] = $ADUserName.Trim().ToLower()
            $Metadata['domainAdminPassword'] = ConvertTo-SecureString -String ($ADPassword.Trim().ToLower()) -AsPlainText -Force

            $TemplateParameterObject.add("domainToJoin", $Metadata['domainToJoin'])
            $TemplateParameterObject.add("organizationalUnit", $Metadata['organizationalUnit'])
            $TemplateParameterObject.add("domainAdminUsername", $Metadata['domainAdminUsername'])
            $TemplateParameterObject.add("domainAdminPassword", $Metadata['domainAdminPassword'])
    }

   cls

   $TemplateParameterObject
   
   $RetVal = Read-Host "Is this correct (y/n)?"

   if (($RetVal.ToLower() -eq 'y')-or ($RetVal.ToLower() -eq 'yes')) {$Done = $true}

}while($Done -eq $false)


Function CreateCustomerServer{
    cls
       
    try{
            write-host "Creating customer servers..."
            New-AzureRmResourceGroupDeployment -Name $deploymentName `
                            -ResourceGroupName $Metadata['RSG'] `
                            -Mode Incremental `
                            -TemplateParameterObject $TemplateParameterObject `
                            -TemplateUri "https://vmqcresources.blob.core.windows.net/templates/compute/virtual-machine.json" `
                            -Force
                              
    }
    Catch{
            Write-Host "Couldn't deploy customer servers"
            exit -2
    }
            
           

    $ops = get-azurermresourcegroupdeploymentoperation -ResourceGroupName $Metadata['RSG'] -deploymentname $deploymentName
    foreach($op in $ops.properties)
    {
        $op | out-file $outfiledirectory -Append
    }

}
    
        
CreateCustomerServer