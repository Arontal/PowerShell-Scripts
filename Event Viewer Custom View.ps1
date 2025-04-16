# Event Viewer Custom View Creator for JSIG AU-2 Compliance
# This script creates persistent custom views in Windows Event Viewer using native functionality

# Set execution policy to bypass for current user
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force

#Requires -RunAsAdministrator

# Define paths and variables
$CustomViewsPath = "$env:USERPROFILE\Documents\Event Viewer Views"
$ConsolidatedViewName = "JSIG AU-2 Consolidated View"

# Function to test if Security log is enabled
function Test-SecurityLogEnabled {
    try {
        $securityLog = Get-WinEvent -ListLog Security -ErrorAction Stop
        
        if ($securityLog.IsEnabled) {
            Write-Host "Security log is enabled and accessible." -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Security log is not enabled. Please enable it to proceed." -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error accessing Security log: $_" -ForegroundColor Red
        Write-Host "Please ensure you have proper permissions and the Security log is enabled." -ForegroundColor Red
        return $false
    }
}

# Test Security log status before proceeding
if (-not (Test-SecurityLogEnabled)) {
    Write-Host "`nScript cannot proceed without an enabled Security log." -ForegroundColor Red
    Write-Host "Please enable the Security log and try again." -ForegroundColor Red
    exit 1
}

# Function to create and import a custom view
function New-CustomEventView {
    param (
        [string]$ViewName,
        [string]$Query,
        [string]$Description
    )
    
    try {
        $ViewPath = Join-Path $CustomViewsPath "$ViewName.xml"
        $CustomView = @"
<?xml version="1.0" encoding="utf-8"?>
<ViewerConfig>
    <QueryConfig>
        <QueryParams>
            <UserQuery>
                <![CDATA[$Query]]>
            </UserQuery>
            <Name>$ViewName</Name>
            <Description>$Description</Description>
        </QueryParams>
    </QueryConfig>
</ViewerConfig>
"@
        $CustomView | Out-File -FilePath $ViewPath -Encoding UTF8
        
        # Create a temporary XML file for wevtutil
        $TempQueryFile = Join-Path $env:TEMP "$ViewName-query.xml"
        $Query | Out-File -FilePath $TempQueryFile -Encoding UTF8
        
        # Import the view using wevtutil with proper escaping for spaces
        $escapedViewName = $ViewName -replace ' ', '` '
        wevtutil sl "`"$ViewName`"" /q:"`"$TempQueryFile`"" /l:en-US
        
        # Clean up temporary file
        Remove-Item -Path $TempQueryFile -Force
        
        Write-Host "Created and imported custom view: $ViewName" -ForegroundColor Green
    }
    catch {
        Write-Host "Error creating/importing view $ViewName : $_" -ForegroundColor Red
    }
}

# Create custom views directory if it doesn't exist
if (-not (Test-Path $CustomViewsPath)) {
    New-Item -ItemType Directory -Path $CustomViewsPath -Force | Out-Null
}

# Validate required event logs
$requiredLogs = @("Security", "System", "Application")
$logsEnabled = $true

foreach ($log in $requiredLogs) {
    if (-not (Test-EventLogAvailability -LogName $log)) {
        $logsEnabled = $false
        Write-Host "Required event log '$log' is not enabled. Some views may not work correctly." -ForegroundColor Yellow
    }
}

# Define event queries for each category using native XML query syntax
$AuthenticationEvents = @"
<QueryList>
  <Query Id="0">
    <Select Path="Security">*[System[(EventID=4624 or EventID=4625 or EventID=4634 or EventID=4647 or EventID=4648)]]</Select>
  </Query>
</QueryList>
"@

$FileAccessEvents = @"
<QueryList>
  <Query Id="0">
    <Select Path="Security">*[System[(EventID=4656 or EventID=4658 or EventID=4663 or EventID=4660)]]</Select>
  </Query>
</QueryList>
"@

$RemovableDeviceEvents = @"
<QueryList>
  <Query Id="0">
    <Select Path="Security">*[System[(EventID=4663)]] and *[EventData[Data[@Name='ObjectType']='File']]</Select>
  </Query>
</QueryList>
"@

$UserGroupManagementEvents = @"
<QueryList>
  <Query Id="0">
    <Select Path="Security">*[System[(EventID=4720 or EventID=4722 or EventID=4724 or EventID=4725 or EventID=4726 or EventID=4732 or EventID=4733)]]</Select>
  </Query>
</QueryList>
"@

$PrivilegedOperationsEvents = @"
<QueryList>
  <Query Id="0">
    <Select Path="Security">*[System[(EventID=4672 or EventID=4673 or EventID=4674 or EventID=4688)]]</Select>
  </Query>
</QueryList>
"@

$AuditLogEvents = @"
<QueryList>
  <Query Id="0">
    <Select Path="Security">*[System[(EventID=1102 or EventID=4719 or EventID=4902 or EventID=4904 or EventID=4905 or EventID=4906 or EventID=4907 or EventID=4908)]]</Select>
  </Query>
</QueryList>
"@

$SystemEvents = @"
<QueryList>
  <Query Id="0">
    <Select Path="Security">*[System[(EventID=4608 or EventID=4609 or EventID=4610 or EventID=4611 or EventID=4612 or EventID=4614 or EventID=4615 or EventID=4616 or EventID=4618 or EventID=4621)]]</Select>
  </Query>
</QueryList>
"@

$ApplicationEvents = @"
<QueryList>
  <Query Id="0">
    <Select Path="Security">*[System[(EventID=4688 or EventID=4689 or EventID=4697 or EventID=4698 or EventID=4699 or EventID=4700 or EventID=4701 or EventID=4702)]]</Select>
  </Query>
</QueryList>
"@

$PrintEvents = @"
<QueryList>
  <Query Id="0">
    <Select Path="Security">*[System[(EventID=307)]]</Select>
  </Query>
</QueryList>
"@

# Consolidated view query
$ConsolidatedQuery = @"
<QueryList>
  <Query Id="0">
    <Select Path="Security">*[System[(EventID=4624 or EventID=4625 or EventID=4634 or EventID=4647 or EventID=4648 or EventID=4656 or EventID=4658 or EventID=4663 or EventID=4660 or EventID=4720 or EventID=4722 or EventID=4724 or EventID=4725 or EventID=4726 or EventID=4732 or EventID=4733 or EventID=4672 or EventID=4673 or EventID=4674 or EventID=4688 or EventID=1102 or EventID=4719 or EventID=4902 or EventID=4904 or EventID=4905 or EventID=4906 or EventID=4907 or EventID=4908 or EventID=307 or EventID=4608 or EventID=4609 or EventID=4610 or EventID=4611 or EventID=4612 or EventID=4614 or EventID=4615 or EventID=4616 or EventID=4618 or EventID=4621 or EventID=4688 or EventID=4689 or EventID=4697 or EventID=4698 or EventID=4699 or EventID=4700 or EventID=4701 or EventID=4702)]]</Select>
  </Query>
</QueryList>
"@

# Create individual custom views
New-CustomEventView -ViewName "Authentication Events" -Query $AuthenticationEvents -Description "Logon success/failure, logoffs, and authentication events"
New-CustomEventView -ViewName "File Access Events" -Query $FileAccessEvents -Description "File and object access activities"
New-CustomEventView -ViewName "Removable Device Events" -Query $RemovableDeviceEvents -Description "USB and removable device usage"
New-CustomEventView -ViewName "User Group Management" -Query $UserGroupManagementEvents -Description "User and group management changes"
New-CustomEventView -ViewName "Privileged Operations" -Query $PrivilegedOperationsEvents -Description "Privileged operations and escalations"
New-CustomEventView -ViewName "Audit Log Events" -Query $AuditLogEvents -Description "Audit log access and modifications"
New-CustomEventView -ViewName "System Events" -Query $SystemEvents -Description "System startup/shutdown events"
New-CustomEventView -ViewName "Application Events" -Query $ApplicationEvents -Description "Application execution and errors"
New-CustomEventView -ViewName "Print Events" -Query $PrintEvents -Description "Print activity monitoring"

# Create consolidated view
New-CustomEventView -ViewName $ConsolidatedViewName -Query $ConsolidatedQuery -Description "Comprehensive view of all JSIG AU-2 relevant events"

# Function to configure audit policies
function Set-AuditPolicies {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Not running as administrator. Skipping audit policy configuration." -ForegroundColor Yellow
        return
    }

    try {
        # Configure audit policies
        auditpol /set /category:"Account Logon" /success:enable /failure:enable
        auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
        auditpol /set /category:"Object Access" /success:enable /failure:enable
        auditpol /set /category:"Privilege Use" /success:enable /failure:enable
        auditpol /set /category:"Detailed Tracking" /success:enable /failure:enable
        auditpol /set /category:"Policy Change" /success:enable /failure:enable
        auditpol /set /category:"Account Management" /success:enable /failure:enable
        auditpol /set /category:"DS Access" /success:enable /failure:enable
        auditpol /set /category:"System" /success:enable /failure:enable
        
        Write-Host "Audit policies configured successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error configuring audit policies: $_" -ForegroundColor Red
    }
}

# Configure audit policies
Set-AuditPolicies

# Display summary
Write-Host "`nCustom views have been created and imported into Event Viewer" -ForegroundColor Cyan
Write-Host "To access these views in Event Viewer:" -ForegroundColor Cyan
Write-Host "1. Open Event Viewer" -ForegroundColor Cyan
Write-Host "2. Navigate to 'Custom Views' in the left pane" -ForegroundColor Cyan
Write-Host "3. The views will be automatically available" -ForegroundColor Cyan

if (-not $logsEnabled) {
    Write-Host "`nWarning: Some required event logs are not enabled. Please enable them for complete functionality." -ForegroundColor Red
}
