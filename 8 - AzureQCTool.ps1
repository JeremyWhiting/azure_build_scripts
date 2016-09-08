<#
.SYNOPSIS 
    This script will perform the Rackspace QC of V1 (ASM) and V2 (ARM) Virtual Machines
.DESCRIPTION
    The script allows you to select VMs from a customers subscription to run the Rackspace intensification process on.
.EXAMPLE
   PS >> azurevmQC.ps1 
.NOTES
    AUTHORS: Andre Stephens and Dugan Sheehan
    LASTEDIT: March 1, 2016 
#>


############# Setting Script Variables #############

####################################################

function Intensification {
	Import-Module Azure -Verbose:$False
	$name = 'Azure' 
	if(Get-Module -ListAvailable | Where-Object { $_.name -eq $name }) {  
		$ab = (Get-Module -ListAvailable | Where-Object{ $_.Name -eq $name }) |  Select Version   
		if ($ab.version -ge "1.0.3") {
			StartMenu
		}
		else {
			Write-Host "Please update to Azure Powershell version 1.0.3 before continuing" -ForegroundColor Red
			Exit
		}
	}  
	else {  
		Write-Host "The Azure PowerShell module is not installed. Please install before continuing" -ForegroundColor Red
		Exit
	}
}

function StartMenu {
	Write-host "=====================================" -ForegroundColor Green
	Write-Host ""                                      -ForegroundColor Green
	Write-Host "         Azure QC Tool           " -ForegroundColor Green
	Write-host "            Version 1.0.1              " -ForegroundColor Green
	Write-Host ""                                      -ForegroundColor Green 
	Write-host "=====================================" -ForegroundColor Green
	Write-Host ""                                      -ForegroundColor Green


	$caption = "Auth to Azure?"

    try {
        $currentAccount = (Get-AzureSubscription -Current -ErrorAction Stop).DefaultAccount 
        $currentSubv1 = (Get-AzureSubscription -Current -ErrorAction Stop).SubscriptionID 
		$currentSubv2 = Get-AzureRmSubscription -SubscriptionId $currentSubv1 -ErrorAction Stop
    }
    catch {
        $currentSubv1 = $null = $null
		$currentSubv1 = $null
		$currentSubv2 = $null
    }
	if (($currentSubv1 -ne $null) -and ($currentSubv2 -ne $null)) {
		$message = "Currently logged in as $currentAccount `r`nwith Subscription ID: $currentSubv1."
		$newSession = new-Object System.Management.Automation.Host.ChoiceDescription "&New User","New User";
		$continueSession = new-Object System.Management.Automation.Host.ChoiceDescription "&Continue Session","Continue Session";
		$choices = [System.Management.Automation.Host.ChoiceDescription[]]($newSession,$continueSession);
		$answer = $host.ui.PromptForChoice($caption,$message,$choices,0)

		switch ($answer){
		0 {AuthAzure}
		1 { $defaultSubsv1 = Get-AzureSubscription -Current
			try {
            $defaultSubsv2 = Select-AzureRmSubscription -SubscriptionId $defaultSubsv1.SubscriptionId
            }
            catch {
            write-host "Sunscription is stale, you will be to reauthenticate"
            Add-AzureRmAccount
            }
			Write-Host "`r`nThe following subscription will be used:"
			$defaultSubsv1
			GatherVMs}
		}
	}
	else {
		$message = "Start New Session?";
		$newSession = new-Object System.Management.Automation.Host.ChoiceDescription "&New User","New User";
		$exitScript = new-Object System.Management.Automation.Host.ChoiceDescription "&Exit","Exit";
		$choices = [System.Management.Automation.Host.ChoiceDescription[]]($newSession,$exitScript);
		$answer = $host.ui.PromptForChoice($caption,$message,$choices,0)

		switch ($answer){
		0 {Get-AzureAuth}
		1 { Exit }
		}
	}
}

function Get-AzureAuth 
{

    Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
   #Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    #Get credentials from the user.
    try 
    {
        $azureAccount = Add-AzureRmAccount
    }
    catch 
    {
        #If the customer provided invalid information, abort execution.
        Write-Host -Object 'Invalid username/password!' -ForegroundColor Red
        return
    }

    $SubscriptionId = Get-AzureRmSubscription |
    Where-Object -FilterScript {
        $_.DefaultAccount -eq "$azureAuthUsername"
    } |
    Out-GridView -Title 'Subscriptions' -PassThru
    While ($SubscriptionId -eq $NULL) 
    {
        $SubscriptionId = Get-AzureRmSubscription | Out-GridView -Title 'Subscriptions' -PassThru
    }
    $result = Set-AzureRmContext -SubscriptionId $SubscriptionId.SubscriptionID
    GatherVMs
}

function GatherVMs {
    $worspacearray = @()
    $worspacearray = workspacecheck

	$ErrorActionPreference = "stop"
    Write-Host "Grabbing Virtual Machine Details from Azure Subscription" -ForegroundColor Yellow
       	
    $VMv2 = @()
	$VMv2 += Find-AzureRMResource -ResourceType "Microsoft.Compute/VirtualMachines" | Select-Object Name,ResourceGroupName,ResourceType,Location
	Write-Host "    Gathered v2 Virtual Machines" -ForegroundColor Green

   
	$SubsVMs = @()
	$SelectVMs = @()
	$DetailedVMs = @()
	$BastionVMs = @()
	$SubsVMs += $VMv1
	$SubsVMs += $VMv2

    $SelectVMs += $SubsVMs | Sort-Object Name,ResourceGroupName | Out-GridView -Title "Select one or more virtual Machines (hold down the CTRL key for multiple selections)" -OutputMode Multiple
	while ($SelectVMs -eq $null) {
		Write-Host "You did not select any VMs!" -ForegroundColor Red
		$SelectVMs += $SubsVMs | Sort-Object Name,ResourceGroupName | Out-GridView -Title "Select one or more virtual Machines (hold down the CTRL key for multiple selections)" -OutputMode Multiple
	}
	Write-Host "`r`nPlease standby while additional details are gathered for selected VMs..." -ForegroundColor Yellow
	
	foreach ($VM in $SelectVMs) {
		if ($VM.ResourceType -eq "Microsoft.Compute/VirtualMachines") {
			$DetailedVMs += (Find-AzureRMResource -ResourceType "Microsoft.Compute/VirtualMachines" -Name $VM.Name -ExpandProperties)
		}
		elseif ($VM.ResourceType -eq "Microsoft.ClassicCompute/VirtualMachines") {
			$DetailedVMs += (Find-AzureRMResource -ResourceType "Microsoft.ClassicCompute/VirtualMachines" -Name $VM.Name -ExpandProperties) 
		}
	}
	<# 
    $BastionVMs += $SubsVMs | Where-Object { $_.Name -like "RACK-BAST" } | Sort-Object Name,ResourceGroupName | Out-GridView -Title "Select one or more virtual Machines (hold down the CTRL key for multiple selections)" -PassThru
	
	Write-Host "`r`nPlease standby while additional details are gathered for Bastion VMs..." -ForegroundColor Yellow
	
	foreach ($VM in $BastionVMs) {
		if ($VM.ResourceType -eq "Microsoft.Compute/VirtualMachines") {
			$DetailedBastionVMs += (Find-AzureRMResource -ResourceType "Microsoft.Compute/VirtualMachines" -Name $VM.Name -ExpandProperties)
		}
		elseif ($VM.ResourceType -eq "Microsoft.ClassicCompute/VirtualMachines") {
			$DetailedBastionVMs += (Find-AzureRMResource -ResourceType "Microsoft.ClassicCompute/VirtualMachines" -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -ExpandProperties) 
		}
	}
    #>
	ServerQC -DetailedVMs $DetailedVMs -workspaceId $worspacearray[0] -workspacekey $worspacearray[1]	
}

function ServerQC ($DetailedVMs,$workspaceId,$workspacekey) {
$i = 0
    $QCsummary = @()
	foreach ($VM in $DetailedVMs) {
		$VMName = $VM.Name
		Write-Host "`r`nStarting QC on $VMName" -ForegroundColor Yellow
		if ($VM.ResourceType -eq "Microsoft.Compute/VirtualMachines") {
				$operatingSystem = $VM.Properties.StorageProfile.OSDisk.OSType
				$networkNames = $VM.Properties.NetworkProfile.NetworkInterfaces.ID
				$VMResourceGRPName = $VM.ResourceGroupName
				$VMLocation = $VM.Location
                #$VMDetails = get-azurerm -name $VMName -ResourceGroupName $VMResourceGRPName

				if ($operatingSystem -eq "Windows") {
					Write-Host "$VMName, is a V2 VM running Windows" -ForegroundColor Yellow

                    ######### Malware ##########
                    $malwareResults = malwarecheckv2 -VMResourceGRPName $VMResourceGRPName -VMName $VMName
                    if ($malwareResults -eq "Need Installation"){
                    $malwareResults = installmalwarev2 -VMResourceGRPName $VMResourceGRPName -VMLocation $VMLocation -VMName $VMName 
                    }
                    write-host -ForegroundColor Cyan "**** Malware Check: $malwareResults ****"

                    ######### Monitoring ##########
                    $monitorResults = monitoringcheckv2 -VMResourceGRPName $VMResourceGRPName -VMName $VMName
                    if ($monitorResults -eq "Need Installation"){
                    $monitorResults = installmonitoringv2 -VMResourceGRPName $VMResourceGRPName -VMLocation $VMLocation -VMName $VMName -workspaceId $workspaceId -workspacekey $workspacekey
                    }
                    write-host -ForegroundColor Cyan "**** Monitoring Check: $malwareResults ****"

                   ######### report overall results ##########
                   if (($monitorResults -eq "Passed") -and ($malwareResults -eq "Passed")){
                        write-host -ForegroundColor Green "All checks for $VMName passed" 
                        $QCsummary += "$VMName - All checks Passed"
                        }
                    else{
                        write-host -ForegroundColor red "Some checks for $VMName failed" 
                        $QCsummary += "$VMName - Some checks failed"
                        }
				}
				elseif ($operatingSystem -eq "Linux") {
					Write-Host "$VMName, is a V2 VM running Linux" -ForegroundColor Yellow
				}
				else {
					Write-Host "You know that thing called an Operating System? Well $VMName doesn't have one..." -ForegroundColor Red
					return
				}
		}
		elseif ($VM.ResourceType -eq "Microsoft.ClassicCompute/VirtualMachines") {
			$VMServiceName = (Get-AzureVM | Where-Object { $_.Name -eq $VM.Name }).ServiceName
			$operatingSystem = $VM.Properties.StorageProfile.OperatingSystemDisk.OperatingSystem
			$networkNames = $VM.Properties.NetworkProfile.VirtualNetwork.Name
			$VMLocation = $VM.Location

			if ($operatingSystem -eq "Windows") {
				$VMDetails = Get-AzureVM -ServiceName $VMServiceName -Name $VMName
   				Write-Host "$VMName, is a V1 VM running Windows" -ForegroundColor Yellow
                ######### Malware ##########
                $malwareResults = MalwarecheckV1 -VMDetails $VMDetails
                if ($malwareResults -eq "Need Installation"){
                    $malwareResults = installmalwarev1 -VMDetails $VMDetails
                    }
                write-host -ForegroundColor Cyan "**** Malware Check: $malwareResults ****"

                ######### Monitoring ##########
                $monitoringResults = monitoringcheckv1 -VMDetails $VMDetails -workspaceId $workspaceId -workspacekey $workspacekey
                if ($monitoringResults -eq "Need Installation"){
                    $monitoringResults = installmonitoringv1 -VMDetails $VMDetails -workspaceId $workspaceId -workspacekey $workspacekey
                    }
                write-host "**** Monitoring Check: $monitoringResults ***" -ForegroundColor Cyan 
			    }
                
                ######### report overall results ##########
                   if (($monitoringResults -eq "Passed") -and ($malwareResults -eq "Passed")){
                        write-host -ForegroundColor Green "All checks for $VMName passed" 
                        $QCsummary += "$VMName - All checks Passed"
                        }
                    else{
                        write-host -ForegroundColor red "Some checks for $VMName failed" 
                        $QCsummary += "$VMName - Some checks failed"
                        }

			}
			elseif ($operatingSystem -eq "Linux") {
				Write-Host "$VMName, is a V1 VM running Linux" -ForegroundColor Yellow
			}
			else {
				Write-Host "You know that thing called an Operating System? Well $VMName doesn't have one..." -ForegroundColor Red
				return
			}
        $I++
		}
Write-host " "
Write-host " "
Write-host "###############################################"
Write-host "###############################################"
Write-host "############### RESULTS SUMMARY ###############"
return $QCsummary
	}

function workspacecheck {
$RackspaceWorkspaceList = Get-AzurermOperationalInsightsWorkspace | Where Tags -match "Rackspace"      

if ($RackspaceWorkspaceList -eq $NULL){
    write-host "A Rackspace monitoring workspace does not exsit within this subscription. A new workspace will need to be created"
            do{
        $Raxdevicenumber = read-host "Enter Azure-Rackspace Core device number. This will be used to create a new unique workspace"
        }while (($Raxdevicenumber -notmatch "\d{1,9}\d{1,9}\d{1,9}\d{1,9}\d{1,9}\d{1,9}") -and ($Raxdevicenumber.Length -ne 6))

    $raxResrouce = $Raxdevicenumber+"RAXSupport"
    $Raxworkspace = $Raxdevicenumber+"RaxMonitoring"
    $resources = Get-AzurermResourceGroup | select ResourceGroupName
    
    if($resources.ResourceGroupName -notcontains $raxResrouce){
        New-AzurermResourceGroup -Name $raxResrouce -Location "East US"
    }

    $workspaceInfo = New-AzurermOperationalInsightsWorkspace -ResourceGroupName "$raxResrouce" -Name "$Raxworkspace" -Location "East US" -Sku "Standard" -Tags @{ "Group" = "Rackspace" }
    $workspaceId = $workspaceInfo.CustomerId.Guid
    $workspaceKey = (Get-AzurermOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $workspaceInfo.ResourceGroupName -Name $workspaceInfo.Name).PrimarySharedKey  
    }

else{
    do{
    $workspaceSelection = Read-host "The following Rackspace workspace exists:" $RackspaceWorkspaceList.name ".... Would you like to use this? (yes, no)"
    } while (($workspaceSelection -ne "yes") -and ($workspaceSelection -ne "no"))

    if ($workspaceSelection -eq "yes"){
    $workspaceId = $RackspaceWorkspaceList.CustomerId.Guid
    $workspaceKey = (Get-AzurermOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $RackspaceWorkspaceList.ResourceGroupName -Name $RackspaceWorkspaceList.Name).PrimarySharedKey
    #$workspaceId
    #$workspaceKey  
    }

    if ($workspaceSelection -eq "no"){
    write-host "QC process is exiting ..."
    return
    }
    return $workspaceId,$workspaceKey
    }
}
function installmalwarev1 ($VMDetails) {
$MalwareCheckSum = $NULL
$config_string = '{ 
"AntimalwareEnabled": true, 
"RealtimeProtectionEnabled": true, 
"Exclusions": {"Extensions": ".FWD;.GSC;.GSE;.MYD;.MYI;.SMD;.VAC;.BAK;.CHK;.FRM;.LDF;.LOG;.MBX;.MDF;.NDF;.TRN;.UND;.UNF;.UNH;.UNI;.UNQ;.UNS;.VHD;.VMDX;.WCI;.EDB;.SDS", 
"Paths": "C:\\rs-pkgs;C:\\System Volume Information\\DFSR;C:\\Sysvol;C:\\ProgramData\\Microsoft\\SharePoint;C:\\Program Files\\Common Files\\Microsoft Shared\\Web Server Extensions;C:\\Program Files\\Operations Manager;C:\\Program Files\\Microsoft Monitoring Agent;C:\\Program Files\\Microsoft Office Servers;C:\\Program Files\\Microsoft System Center 2012 R2\\Server;C:\\Program Files\\System Center Operations Manager;C:\\Program Files\\System Center Operations Manager 2007;C:\\Windows\\Microsoft.NET\\Framework64\\v2.0.50727\\Temporary ASP.NET Files;C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\Temporary ASP.NET Files\\ \\Windows\\NTDS;C:\\Windows\\System32\\LogFiles;C:\\Windows\\Sysvol;C:\\Program Files\\Double-Take Software;C:\\Program Files\\DoubleTake;C:\\Program Files\\Exchsrvr;C:\\Program Files\\Ipswitch;C:\\Program Files\\LogMeIn;C:\\Windows\\SoftwareDistribution\\Datastore;C:\\Windows\\Temp\\Gthrsvc C:\\Winnt\\Temp\\Gthrsvc\\", 
"Processes": "HealthService.exe;ManagementService.exe;Microsoft.Mom.Sdk.Service.exe;Microsoft.Mom.ConfigServiceHost.exe;MonitoringHost.exe;pagefile.sys" }
            }'

$malInstall = Set-AzureVMMicrosoftAntimalwareExtension -VM $VMDetails -AntimalwareConfiguration $config_string
$Upresult = $NULL

do {   
        Try {
        $updateVM = $VMDetails | Update-AzureVM -ErrorAction Stop
        $Upresult = 'success'
        }

        Catch [system.exception]{
        Write-host $UpdateTries
        $UpdateTries++
        $Upresult = 'Fail'
        start-sleep 5  
        }
    } while (($UpdateTries -lt 20) -and ($Upresult -ne 'success'))

    Write-host "malware installation has begun"

    $malTries = 0
    $VMDetails = get-azureVM -name $VMDetails.name -ServiceName $VMDetails.ServiceName
    $Extensionlist = (Get-AzureVMExtension -VM $VMDetails).ExtensionName
    $MalwareExtension = $VMDetails.ResourceExtensionStatusList | where HandlerName -eq Microsoft.Azure.Security.IaaSAntimalware
    #$malextensionConfig = (Get-AzureVMMicrosoftAntimalwareExtension -VM $VMDetails -WarningAction SilentlyContinue).PublicConfiguration | ConvertFrom-Json 

	if (($MalwareExtension.status -eq "Installing") -or ($MalwareExtension.status -eq $Null)){
    Do{
    start-sleep 30 
    $malTries = $malries+1
    $VMDetails = get-azureVM -name $VMDetails.name -ServiceName $VMDetails.ServiceName
    $MalwareExtension = $VMDetails.ResourceExtensionStatusList | where HandlerName -eq Microsoft.Azure.Security.IaaSAntimalware
    write-host "waiting for install to complete"
    write-host $MalwareExtension.status
    }while (($MalwareExtension.status -ne "Ready") -and ($malTries -lt 10))
    }
    
    #$malextensionConfig = (Get-AzureVMMicrosoftAntimalwareExtension -VM $VMDetails -WarningAction SilentlyContinue).PublicConfiguration | ConvertFrom-Json
    $MalwareExtension = $VMDetails.ResourceExtensionStatusList | where HandlerName -eq Microsoft.Azure.Security.IaaSAntimalware

    if ($MalwareExtension.status -eq "Ready") {
        #Malware Agent ready and set for realtime protection
        $MalwareCheckSum = "Passed"
    }

    else{
        #Malware Agent Update Failed. Please reveiw server then re-run the QC script
        $MalwareCheckSum = "Failed"
        write-host -ForegroundColor Red "Installation and configuration failed"
        write-host "Status - $MalwareExtension.status"
    }
    return $MalwareCheckSum 
}
Function MalwarecheckV1 ($VMDetails){
########check to see if malware agent is installed#######
#checking for AntiMalware Agent
Write-Host "----STARTING MALWARE CHECK----"
$Extensionlist = (Get-AzureVMExtension -VM $VMDetails).ExtensionName
$MalwareExtension = $VMDetails.ResourceExtensionStatusList | where HandlerName -eq Microsoft.Azure.Security.IaaSAntimalware
$malwareDiag = $NULL
$MalwareCheckSum = $NULL

if (($Extensionlist -match "IaaSAntimalware") -and ($MalwareExtension.status -eq "Ready")) {
    Write-host "Microsoft AntiMalware is Installed"
    Write-host "Checking to see if it matches standard rackspace configuraton (Realtime Scanning, Exclusions)"
    $malextensionConfig = (Get-AzureVMMicrosoftAntimalwareExtension -VM $VMDetails -WarningAction SilentlyContinue).PublicConfiguration | ConvertFrom-Json

        if (($malextensionConfig.AntimalwareEnabled -eq "True") -and ($malextensionConfig.RealtimeProtectionEnabled -eq "True") -and ($malextensionConfig.Exclusions.Paths -like "*C:\rs-pkgs*")){
        write-host "Malware is set for realtime protection with Rackspace exclusions"
        $MalwareCheckSum = "Passed"
        }
        else {
        Write-host "Malware was not match standard rackspace deployment ...updating the config"
        $MalwareCheckSum = "Need Installation"
        }
}
    	
else{
    Write-host "Agent is not installed or ready. Installing Agent......(this may take a few minutes)"
    $MalwareCheckSum = "Need Installation"
    }
    return $MalwareCheckSum
}
function monitoringcheckv1 ($VMDetails,$workspaceId,$workspacekey){
#######check to see if opsinsights agent is intalled#######
Write-Host "----STARTING MONITORING CHECK----"
write-host "Checking for Microsoft Monitoring Agent installation...."
#write-host "ID: $workspaceId"
#write-host "KEY: $workspacekey"

$Extensionlist = (Get-AzureVMExtension -VM $VMDetails).ExtensionName
$MonitoringExtension = $VMDetails.ResourceExtensionStatusList | where HandlerName -eq Microsoft.EnterpriseCloud.Monitoring.MicrosoftMonitoringAgent


if (($Extensionlist -match "MicrosoftMonitoringAgent") -and ($MonitoringExtension.status -eq "Ready")) {
    write-host "Microsoft Monitoring agent is Installed and Ready, Checking workspace ...."

    $WorkspacePubID = (Get-AzureVMExtension -VM $VMDetails | Where ExtensionName -eq MicrosoftMonitoringAgent).PublicConfiguration
    $WorkspacePubIDjson = $WorkspacePubID | ConvertFrom-Json
	$currentworkspaceID = $WorkspacePubIDjson.workspaceId
 
    if($currentworkspaceID -match $workspaceId){
        write-host "Microsoft Monitoring Agent is installed and CORRECTLY registerd with Rackspace Workspace"
        write-host "Workspace: $currentworkspaceID"
        $InsightsCheckSum = "Passed"   
    }
    else{
		write-host "Microsoft Monitoring Agent is installed but registered with a non-Rackspace workspace"
        write-host "Current Workspace: $currentworkspaceID ..... Rackspace Workspace: $workspaceId"
        $InsightsCheckSum = "Failed"  
		}
}
Elseif (($Extensionlist -match "MicrosoftMonitoringAgent") -and ($MonitoringExtension.status -ne "Ready")){
    write-host "Agent is installed, but is not in a ready status: $MonitoringExtension.status"
    $InsightsCheckSum = "Failed"
    }
Else{
    $InsightsCheckSum = "Need Installation"
    }
return $InsightsCheckSum
}
function installmonitoringv1 ($VMDetails,$workspaceId,$workspacekey){
Write-host "Monitoring Agent is not installed, configuring with Rackspace standards"
Write-host "Completing installation ..... (this will take serveral minutes)"
write-host "ID: $workspaceId"
write-host "KEY: $workspacekey"


$Setextention = Set-AzureVMExtension -VM $VMDetails -Publisher 'Microsoft.EnterpriseCloud.Monitoring' -ExtensionName 'MicrosoftMonitoringAgent' -Version '1.*' -PublicConfiguration "{'workspaceId': '$workspaceId'}" -PrivateConfiguration "{'workspaceKey': '$workspaceKey' }"

$Upresult = $NULL
    do {
        Try {
        $VMDetails | Update-AzureVM -ErrorAction Stop
        $Upresult = 'success'
        }

        Catch [system.exception]{
        $_
        Write-host $UpdateTries
        $UpdateTries++
        $Upresult = 'Fail'
        start-sleep 5  
        }
    } while (($UpdateTries -lt 20) -and ($Upresult -ne 'success'))

    ###Checking Install###
    write-host "waiting for install to complete"
        $installTries = 0
        Do{
        $installTries++
        start-sleep 35 
        $VMDetails = get-azureVM -name $VMDetails.name -ServiceName $VMDetails.ServiceName
        $MonitoringExtension = $VMDetails.ResourceExtensionStatusList | where HandlerName -eq Microsoft.EnterpriseCloud.Monitoring.MicrosoftMonitoringAgent
        $Status = $MonitoringExtension.status
        $installmessage = $MonitoringExtension.FormattedMessage.message
        write-host "Status: $Status"
        write-host "Message: $installmessage"
        }while (($MonitoringExtension.status -eq "Installing") -or ($MonitoringExtension.status -eq $Null) -or ($installmessage -match "Enabling Plugin") -or ($MonitoringExtension.status -eq "NotReady") -or ($MonitoringExtension.status -eq "Unresponsive"))

    $MonitoringExtension = $VMDetails.ResourceExtensionStatusList | where HandlerName -eq Microsoft.EnterpriseCloud.Monitoring.MicrosoftMonitoringAgent
    $installmessage = $MonitoringExtension.FormattedMessage.message
    Write-host "Info: $installmessage"

    if ($installmessage -match "Error while parsing heartbeat"){
        write-host "Trying to resolve heartbeat issue"
        start-sleep 35
        $VMDetails = get-azureVM -name $VMDetails.name -ServiceName $VMDetails.ServiceName
        $MonitoringExtension = $VMDetails.ResourceExtensionStatusList | where HandlerName -eq Microsoft.EnterpriseCloud.Monitoring.MicrosoftMonitoringAgent
        }

    if ($MonitoringExtension.status -eq "NotReady"){
        start-sleep 20
        $VMDetails = get-azureVM -name $VMDetails.name -ServiceName $VMDetails.ServiceName
        $MonitoringExtension = $VMDetails.ResourceExtensionStatusList | where HandlerName -eq Microsoft.EnterpriseCloud.Monitoring.MicrosoftMonitoringAgent
        }
    $InsightsCheckSum = $Null
    if ($MonitoringExtension.status -eq "Ready") {
        $InsightsCheckSum = "Passed"
        write-host -ForegroundColor Green "Agent installed and registered"
    }
    else{
        Write-host "Monitoring Extension Installation Failed. Please reveiw server then re-run the QC script"
        $InsightsCheckSum = "Failed"
    }
    
    return $InsightsCheckSum
    }
function installmalwarev2 ($VMResourceGRPName,$VMName,$VMLocation){
$allVersions= (Get-AzureRmVMExtensionImage -Location "$VMLocation" -PublisherName "Microsoft.Azure.Security" -Type "IaaSAntimalware").Version
$typeHandlerVer = $allVersions[($allVersions.count)-1]
$typeHandlerVerMjandMn = $typeHandlerVer.split(".")
$typeHandlerVerMjandMn = $typeHandlerVerMjandMn[0] + "." + $typeHandlerVerMjandMn[1]

$config_string = '{ 
		"AntimalwareEnabled": true, 
		"RealtimeProtectionEnabled": true, 
		"Exclusions": {"Extensions": ".FWD;.GSC;.GSE;.MYD;.MYI;.SMD;.VAC;.BAK;.CHK;.FRM;.LDF;.LOG;.MBX;.MDF;.NDF;.TRN;.UND;.UNF;.UNH;.UNI;.UNQ;.UNS;.VHD;.VMDX;.WCI;.EDB;.SDS", 
		"Paths": "C:\\rs-pkgs;C:\\System Volume Information\\DFSR;C:\\Sysvol;C:\\ProgramData\\Microsoft\\SharePoint;C:\\Program Files\\Common Files\\Microsoft Shared\\Web Server Extensions;C:\\Program Files\\Operations Manager;C:\\Program Files\\Microsoft Monitoring Agent;C:\\Program Files\\Microsoft Office Servers;C:\\Program Files\\Microsoft System Center 2012 R2\\Server;C:\\Program Files\\System Center Operations Manager;C:\\Program Files\\System Center Operations Manager 2007;C:\\Windows\\Microsoft.NET\\Framework64\\v2.0.50727\\Temporary ASP.NET Files;C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319\\Temporary ASP.NET Files\\ \\Windows\\NTDS;C:\\Windows\\System32\\LogFiles;C:\\Windows\\Sysvol;C:\\Program Files\\Double-Take Software;C:\\Program Files\\DoubleTake;C:\\Program Files\\Exchsrvr;C:\\Program Files\\Ipswitch;C:\\Program Files\\LogMeIn;C:\\Windows\\SoftwareDistribution\\Datastore;C:\\Windows\\Temp\\Gthrsvc C:\\Winnt\\Temp\\Gthrsvc\\", 
		"Processes": "HealthService.exe;ManagementService.exe;Microsoft.Mom.Sdk.Service.exe;Microsoft.Mom.ConfigServiceHost.exe;MonitoringHost.exe;pagefile.sys" }
					}'

$install = Set-AzureRmVMExtension -ResourceGroupName "$VMResourceGRPName" -VMName "$VMName" -Location "$VMLocation" -Name "IaaSAntimalware" -Publisher "Microsoft.Azure.Security" -ExtensionType "IaaSAntimalware" -TypeHandlerVersion $typeHandlerVerMjandMn -SettingString $config_string 

$malwarecheck = Get-AzureRmVMExtension -Name IaaSAntimalware -ResourceGroupName $VMResourceGRPName -VMName $VMName -ErrorAction SilentlyContinue
$MalwareCheckSum = $NULL
$maljson = $malwarecheck.PublicSettings | ConvertFrom-Json

if (($maljson.AntimalwareEnabled -eq "True") -and ($maljson.RealtimeProtectionEnabled -eq "True")){
        write-host "Install complete - Malware is set for realtime protection with Rackspace exclusions"
        $MalwareCheckSum = "Passed"
        }
        else {
        Write-host "Malware installation did not go as planned"
        $MalwareCheckSum = "Failed"
        }
        return $MalwareCheckSum
}
Function malwarecheckv2 ($VMResourceGRPName,$VMName){
#checking for AntiMalware Agent
Write-Host "----STARTING MALWARE CHECK----"
$malwarecheck = Get-AzureRmVMExtension -Name IaaSAntimalware -ResourceGroupName $VMResourceGRPName -VMName $VMName -ErrorAction SilentlyContinue
$MalwareCheckSum = $NULL


if (($malwarecheck -eq $NULL) -or ($malwarecheck.ProvisioningState -ne "Succeeded")){
Write-host "Agent is not installed or ready. Installing Agent......(this may take a few minutes)"
    $MalwareCheckSum = "Need Installation"
    }

else {
    Write-host "Microsoft AntiMalware is Installed"
    Write-host "Checking to see if it matches standard rackspace configuraton (Realtime Scanning, Exclusions)"
    $maljson = $malwarecheck.PublicSettings | ConvertFrom-Json

        if (($maljson.AntimalwareEnabled -eq "True") -and ($maljson.RealtimeProtectionEnabled -eq "True") -and ($maljson.Exclusions.Paths -like "*C:\rs-pkgs*")){
        write-host "Malware is set for realtime protection with Rackspace exclusions"
        $MalwareCheckSum = "Passed"
        }
        else {
        Write-host "Malware was not match standard rackspace deployment ...updating the config"
        $MalwareCheckSum = "Need Installation"
        }
}
return $MalwareCheckSum
}
Function monitoringcheckv2 ($VMResourceGRPName,$VMName){
#checking for AntiMalware Agent
Write-Host "----STARTING MONITORING CHECK----"
$monitoringcheck = Get-AzureRmVMExtension -Name MicrosoftMonitoringAgent -ResourceGroupName $VMResourceGRPName -VMName $VMName -ErrorAction SilentlyContinue
$MonitoringCheckSum = $NULL


if ($monitoringcheck.ProvisioningState -eq "Succeeded"){
Write-host "Monitoring agent is installed, Checking workspace"
$Monjson = $monitoringcheck.PublicSettings | ConvertFrom-Json

    if ($Monjson.workspaceId -eq $workspaceId){
    write-host "Agent is correctly registered with Rackspace workspace"
    $MonitoringCheckSum = "Passed"
    }
    else{
    write-host -ForegroundColor Red "Agent is not registered to the Rackspace workspace"
    write-host "currently pointing to workspace: '$Monjson'"
    $MonitoringCheckSum = "Failed"
    }
}

else{
    write-host "Monitoring Agent is not deployed, installing agent ... (this will take a few minutes)"
    $MonitoringCheckSum = "Need Installation"
    }
return $MonitoringCheckSum
}
function installmonitoringv2 ($VMname,$VMResourceGRPName,$VMLocation,$workspaceId,$workspacekey){
$maxversion= (Get-AzureRmVMExtensionImage -Location "Central US" -PublisherName "Microsoft.EnterpriseCloud.Monitoring" -Type "MicrosoftMonitoringAgent").Version | Select-Object -Last 1 
$typeHandlerVerMjandMn = $maxversion.split(".")
$typeHandlerVerMjandMn = $typeHandlerVerMjandMn[0] + "." + $typeHandlerVerMjandMn[1]

<# Install Extension OpsInsights Resource Manager #>
$install = Set-AzureRMVMExtension -ResourceGroupName $VMResourceGRPName `
-VMName $VMname `
-Name "MicrosoftMonitoringAgent" `
-Publisher 'Microsoft.EnterpriseCloud.Monitoring' `
-ExtensionType 'MicrosoftMonitoringAgent' `
-TypeHandlerVersion "$typeHandlerVerMjandMn" `
-Location "$VMLocation" `
-SettingString "{'workspaceId':  '$workspaceId'}" -ProtectedSettingString "{'workspaceKey': '$workspaceKey' }" 

$monitoringcheck = Get-AzureRmVMExtension -Name MicrosoftMonitoringAgent -ResourceGroupName $VMResourceGRPName -VMName $VMName -ErrorAction SilentlyContinue
$MonitoringCheckSum = $NULL
$Monjson = $monitoringcheck.PublicSettings | ConvertFrom-Json

if (($monitoringcheck.ProvisioningState -eq "Succeeded") -and ($Monjson.workspaceId -eq "$workspaceId")){
        write-host "Agent installed and correctly registered with the workspace"
        $MonitoringCheckSum = "Passed"
        }
        else {
        Write-host "Malware installation did not go as planned"
        $MonitoringCheckSum = "Failed"
        }
        return $MonitoringCheckSum
}
Intensification

