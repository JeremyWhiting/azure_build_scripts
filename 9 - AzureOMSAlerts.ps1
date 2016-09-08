#ONCE PER SUBSCRIPTION
################################################
#Subscription and workspace definition
################################################

#$SubscriptionId = "c39e4605-fe9c-4bda-a716-739102ebd6ee"
#$WorkspaceName = "804735RaxMonitoring"
#$WorkspaceName = "45676556OMS"
#$resourceGroupOMS = "testOMSdeploy"
#$resourceGroupOMS = "804735RAXSupport"
$resourceGroupOMS = "EU2-RSG-ALL"
$WorkspaceName = "814818-OMS"
$SubscriptionId = "561fb812-a95c-4938-b596-32573a5e0bd5"

####NEEED TO GET UPDATED VERSION######

################################################
#Defining Alert List
################################################
$Alerts = @"
[
    {
	    "Id": "raxmalwaresignatures",
	    "Category": "Alert",
	    "DisplayName": "Malware - Signatures Out of Date",
	    "Description": "This monitor triggers an alert when the microsoft antimalware agent (SCEP) signatures become out of date",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-Malware-SignaturesOutofDate",
	    "Query": "Type=ProtectionStatus AND (ProtectionStatusRank=250) AND (TypeofProtection=\"System Center Endpoint Protection\")",
        "Interval": 240,
	    "Version": 1
    },
    {
	    "Id": "raxmalwarerealtimeprotect",
	    "Category": "Alert",
	    "DisplayName": "Malware - RealTime Protection is not Enabled",
	    "Description": "This monitor triggers an alert when the Microsoft antimalware agent (SCEP) does not have real-time protection enabled",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-Malware-RealTimeProtectionisnotEnabled",
	    "Query": "Type=ProtectionStatus AND (ProtectionStatusRank=270) AND (TypeofProtection=\"System Center Endpoint Protection\")",
        "Interval": 240,
	    "Version": 1
    },
    {
	    "Id": "raxmalwareactivethreat",
	    "Category": "Alert",
	    "DisplayName": "Malware - Active Threat Detected",
	    "Description": "This monitor triggers an alert when the Microsoft antimalware agent (SCEP) detects a threat",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-Malware-ActiveThreatDetected",
	    "Query": "Type=ProtectionStatus AND (ThreatStatus=Active) AND (TypeofProtection=\"System Center Endpoint Protection\")",
	    "Version": 1
    },
    {
	    "Id": "raxmalwarequarantineev",
	    "Category": "Alert",
	    "DisplayName": "Malware - Virus Quarantine Event",
	    "Description": "This monitor triggers an alert when the Microsoft antimalware agent (SCEP) performs a quarantine event",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-Malware-VirusQuarantineEvent",
	    "Query": "Type=ProtectionStatus AND (ThreatStatus=Quarantined) AND (TypeofProtection=\"System Center Endpoint Protection\")",
	    "Version": 1
    },
    {
	    "Id": "raxunexpectedshutdown",
	    "Category": "Alert",
	    "DisplayName": "System Log - EventID 6008 - Unexpected Shutdown",
	    "Description": "This monitor triggers an alert when the system log records an unexpected shutdown event (6008)",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-SystemLog-EventID6008-UnexpectedShutdown",
	    "Query": "Type=Event EventLog=\"System\" EventID:6008",
	    "Version": 1
    },
    {
	    "Id": "raxhighcpu",
	    "Category": "Alert",
	    "DisplayName": "Windows Perfmon - CPU average greater than 95 percent average over 5 minutes",
	    "Description": "This monitor triggers an alert when avergage CPU is greater than 95% over a 5 minute period",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-WindowsPerfmon-CPUaveragegreaterthan95percentaverageover5minutes",
	    "Query": "Type:Perf (ObjectName=Processor) CounterName=\"% Processor Time\" InstanceName=_Total | measure Avg(CounterValue) as AVGCPU by Computer | where AVGCPU>=95",
        "Interval": 30,
	    "Version": 1
    },
    {
	    "Id": "raxlowcdisk",
	    "Category": "Alert",
	    "DisplayName": "Windows Perfmon - Operating System Disk C: has less than 1000 MB free space",
	    "Description": "This monitor triggers an alert when the operating system disk C: has less than 1000 MB free space",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-WindowsPerfmon-OperatingSystemDiskC:haslessthan1000MBfreespace",
	    "Query": "Type=Perf ObjectName=LogicalDisk \"Free Megabytes\" InstanceName=\"C:\" AND CounterValue < 1000",
	    "Version": 1
    },
    {
	    "Id": "raxlowpecentdisk",
	    "Category": "Alert",
	    "DisplayName": "Windows Perfmon - Less than 5% available Disk Space",
	    "Description": "This monitor triggers an alert when free disk space drops below 5% available",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-WindowsPerfmon-Lessthan5%availableDiskSpace",
	    "Query": "Type=Perf (ObjectName=LogicalDisk) (CounterName=\"% Free Space\") AND CounterValue<=5",
        "Interval": 30,
	    "Version": 1
    },
    {
	    "Id": "raxdblogfilefull",
	    "Category": "Alert",
	    "DisplayName": "Application Log - Event ID 9002: MSSQL Server database log file is full",
	    "Description": "This monitor triggers an alert when a MSSQL Server database log file becomes full",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-ApplicationLog-EventID9002:MSSQLServerdatabaselogfileisfull",
	    "Query": "EventLog=Application AND Source=*MSSQL* AND EventID=9002",
	    "Version": 1
    },
    {
	    "Id": "raxsqljobfail",
	    "Category": "Alert",
	    "DisplayName": "Application Log - Event ID 208: MSSQL Agent job has failed",
	    "Description": "This monitor triggers an alert when a MSSQL Server Agent job fails to execute",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-ApplicationLog-EventID208:MSSQLAgentjobhasfailed",
	    "Query": "EventLog=Application AND Source=*SQLAgent* AND EventID=208",
	    "Version": 1
    },
    {
	    "Id": "raxsqlgenericfileerror",
	    "Category": "Alert",
	    "DisplayName": "Application Log - Event ID 5105: Device activation error. The physical file name incorrect",
	    "Description": "This monitor triggers an alert when a database creation action fails",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-ApplicationLog-EventID5105:Deviceactivationerror.Thephysicalfilenameincorrect",
	    "Query": "EventLog=Application AND Source=*MSSQL* AND EventID=5105",
	    "Version": 1
    },
    {
	    "Id": "raxdfsreplication",
	    "Category": "Alert",
	    "DisplayName": "DFS Replication - Generic Error",
	    "Description": "This monitor triggers an alert when DFS Replication records an error",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-DFSReplication-GenericErrorL",
	    "Query": "EventLog=\"DFS Replication\" AND EventLevelName=Error",
	    "Version": 1
    },
    {
	    "Id": "raxdirectoryservice",
	    "Category": "Alert",
	    "DisplayName": "Directory Service Replication - Generic Error",
	    "Description": "This monitor triggers an alert when Directory Service Replication records an error",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-DirectoryServiceReplication-GenericError",
	    "Query": "EventLog=\"Directory Service\" AND EventLevelName=Error",
	    "Version": 1
    },
    {
	    "Id": "raxdnserror",
	    "Category": "Alert",
	    "DisplayName": "Windows DNS Server - Generic Error",
	    "Description": "This monitor triggers an alert when Windows DNS Server records and error",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-WindowsDNSServer-GenericError",
	    "Query": "EventLog=\"DNS Server\" AND EventLevelName=Error",
	    "Version": 1
    },
    {
	    "Id": "raxazurebackuperror",
	    "Category": "Alert",
	    "DisplayName": "Microsoft Azure Backup Agent - Generic Error",
	    "Description": "This monitor triggers an alert when Azure File Backup agent records and error",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-MicrosoftAzureBackupAgent-GenericError",
	    "Query": "EventLog=\"CloudBackup\" AND EventLevelName=Error",
	    "Version": 1
    },
    {
	    "Id": "raxserverbackuperror",
	    "Category": "Alert",
	    "DisplayName": "Microsoft Server Backup Agent - Generic Error",
	    "Description": "This monitor triggers an alert when Microsoft Server Backup records and error",
	    "Remediation": "https://one.rackspace.com/display/FSFA/Azure+Alerts#AzureAlerts-MicrosoftServerBackupAgent-GenericError",
	    "Query": "EventLog=Microsoft-Windows-Backup AND EventLevelName=Error",
	    "Version": 1
    }
]
"@ | ConvertFrom-Json



############################################################################
#creating alerts with webhook and custom JSON -  minute interval and public comment
############################################################################


foreach ($alert in $Alerts) {
    $id = $alert.Id
    $DisplayName = $alert.DisplayName
    $description = $alert.Description
    $remediation = $alert.Remediation
    $interval = $NULL
    $interval = $alert.interval 

    if ($interval -eq $NULL){
        $interval = 5
        }
    
    $notification = $NULL
    $notification = $alert.notification 

    if ($notification -eq $NULL){
        $notification = "public"
        }
    
    #do 30 minutes for CPU


#Creating Custom JSON
$PayloadPublic = @" 
{
"`"workspaceId`"":"`"#workspaceid`"", `
"`"alertName`"":"`"#alertrulename`"", `
"`"alertValue`"":"`"#thresholdvalue`"", `
"`"searchInterval`"":"`"#searchinterval`"", `
"`"IncludeSearchResults`"":true , `
"`"Remediation"`" : "`"$remediation"`", `
"`"Description"`": "`"#description"`", `
"`"NotificationType`"":"`"$notification"`"
}
"@

    #create saved search
    write-host -ForegroundColor Yellow "Creating Saved Search"
    New-AzureRmOperationalInsightsSavedSearch -ResourceGroupName $resourceGroupOMS -WorkspaceName $WorkspaceName -SavedSearchId $id -DisplayName $alert.DisplayName -Category $alert.Category -Query $alert.Query -Version $alert.Version
    
    #create Schedule
    write-host -ForegroundColor Yellow "Creating Schedule"
    $scheduleJson = "{'properties': { 'Interval': $interval, 'QueryTimeSpan': $interval, 'Active':'true' }"
    armclient put /subscriptions/$subscriptionId/resourceGroups/$resourceGroupOMS/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName/savedSearches/$id/schedules/$id`?api-version=2015-03-20 $scheduleJson

    #set threshold
    write-host -ForegroundColor Yellow "Setting Threshold"
    $thresholdJson = "{'properties': { 'Name': '$DisplayName', 'Version':'1', 'Type':'Alert', 'Threshold': { 'Operator': 'gt', 'Value': 0 }, 'Description':'$description', 'Severity':'Critical' }"
    armclient put /subscriptions/$subscriptionId/resourceGroups/$resourceGroupOMS/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName/savedSearches/$id/schedules/$id/actions/mythreshold?api-version=2015-03-20 $thresholdJson

    #set webhook
    write-host -ForegroundColor Yellow "Applying Webhook Parameters"
    $webhookAction = "{'properties': { 'Name': '$DisplayName', 'Type':'Webhook', 'WebhookUri': 'https://events.raxcloud.com/api/webhooks/incoming/genericjson?code=Q9o4bZq0z25J1bC927aC8rxsfv67zsO60R757n5QmkD', 'CustomPayload': '$PayloadPublic', 'Version':'1' }"
    armclient put /subscriptions/$subscriptionId/resourceGroups/$resourceGroupOMS/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName/savedSearches/$id/schedules/$id/actions/mywebhookaction?api-version=2015-03-20 $webhookAction
}