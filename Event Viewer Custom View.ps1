# Event Viewer Custom View Creator
# This script creates custom view XML files that can be imported into Event Viewer

# Function to check if required event logs are enabled
function Test-EventLogsEnabled {
  $requiredLogs = @(
      "Security",
      "System",
      "Application"
  )
  
  $missingLogs = @()
  foreach ($log in $requiredLogs) {
      try {
          $logStatus = Get-WinEvent -ListLog $log -ErrorAction Stop
          if (-not $logStatus.IsEnabled) {
              $missingLogs += $log
          }
      }
      catch {
          $missingLogs += $log
      }
  }
  
  if ($missingLogs.Count -gt 0) {
      Write-Host "Warning: The following required event logs are not enabled:" -ForegroundColor Yellow
      $missingLogs | ForEach-Object { Write-Host "- $_" -ForegroundColor Yellow }
      Write-Host "Please enable these logs before creating custom views." -ForegroundColor Yellow
      return $false
  }
  return $true
}

# Define the path for saving custom views
$CustomViewsPath = "$env:USERPROFILE\Documents\EventViewerCustomViews"

# Function to create a custom view XML file
function New-EventViewerCustomView {
  param (
      [string]$ViewName,
      [string]$LogName,
      [string]$FilterXPath,
      [string]$Description
  )
  
  try {
      # Create the custom views directory if it doesn't exist
      if (-not (Test-Path $CustomViewsPath)) {
          New-Item -ItemType Directory -Path $CustomViewsPath -Force | Out-Null
      }
      
      # Create the XML file for the view
      $viewPath = Join-Path $CustomViewsPath "$ViewName.xml"
      
      # Extract Event IDs from the XPath query for the Simple section
      $eventIds = @()
      if ($FilterXPath -match "EventID=(\d+)") {
          $matches | ForEach-Object {
              if ($_ -match "EventID=(\d+)") {
                  $eventIds += $matches[1]
              }
          }
      }
      $eventIdString = $eventIds -join ","

      # Create the custom view XML with proper formatting
      $xmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<ViewerConfig>
    <QueryConfig>
        <QueryParams>
            <Simple>
                <Channel>$LogName</Channel>
                <EventId>$eventIdString</EventId>
                <Level>1,2,3,4,0,5</Level>
                <RelativeTimeInfo>0</RelativeTimeInfo>
                <BySource>False</BySource>
            </Simple>
        </QueryParams>
        <QueryNode>
            <Name>$ViewName</Name>
            <QueryList>
                <Query Id="0" Path="$LogName">
                    <Select Path="$LogName">*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5) and ($($FilterXPath -replace '^\*\[System\[\(', '' -replace '\)\]\]$', ''))]]</Select>
                </Query>
            </QueryList>
        </QueryNode>
    </QueryConfig>
</ViewerConfig>
"@
      
      # Save the XML file
      $xmlContent | Out-File -FilePath $viewPath -Encoding UTF8
      
      Write-Host "Created custom view XML: $ViewName" -ForegroundColor Green
      Write-Host "View saved to: $viewPath" -ForegroundColor Cyan
      return $true
  }
  catch {
      Write-Host "Error creating view $ViewName : $_" -ForegroundColor Red
      return $false
  }
}

# Check if required event logs are enabled
if (-not (Test-EventLogsEnabled)) {
  Write-Host "Please enable the required event logs and run the script again." -ForegroundColor Red
  exit
}

# Hard-coded event data with updated event IDs
$eventData = @(
    @{ Category = "Auth"; EventIDs = @(4624, 4625, 4634, 4647, 4648, 4768, 4769, 4771, 4776, 4778, 4779) },
    @{ Category = "FileObject"; EventIDs = @(4656, 4663, 4659, 4660, 4670, 4657, 5140, 5145) },
    @{ Category = "Export"; EventIDs = @(4656, 4663) },
    @{ Category = "Import"; EventIDs = @(4656, 4663) },
    @{ Category = "UserGroup"; EventIDs = @(4720, 4722, 4723, 4724, 4725, 4726, 4738, 4740, 4731, 4732, 4733, 4735, 4737, 4727, 4728, 4729, 4730, 4780, 4781) },
    @{ Category = "Privileged"; EventIDs = @(4672, 4673, 4719, 4907, 4704, 4705, 4902, 4904) },
    @{ Category = "AdminAccess"; EventIDs = @(4672) },
    @{ Category = "PrivilegeEscalation"; EventIDs = @(4672, 4673) },
    @{ Category = "AuditLog"; EventIDs = @(1100, 1102, 1101) },
    @{ Category = "SystemReboot"; EventIDs = @(6005, 6006, 6008, 1074, 1076, 6009) },
    @{ Category = "PrintDevice"; EventIDs = @(307, 805) },
    @{ Category = "PrintFile"; EventIDs = @(307, 805) },
    @{ Category = "AppInit"; EventIDs = @(4688, 4697) }
)

# Create custom views for each category
foreach ($group in $eventData) {
    $categoryName = $group.Category
    $eventIdString = $group.EventIDs -join " or EventID="
    
    # Define the XPath query
    $filterXPath = "*[System[(EventID=$eventIdString)]]"
    
    # Create the custom view XML file
    New-EventViewerCustomView -ViewName $categoryName -LogName "Security" -FilterXPath $filterXPath -Description "Events for $categoryName"
}

# Display summary
Write-Host "`nCustom View Creation Summary:" -ForegroundColor Cyan
Write-Host "Successfully created custom view XML files for each hard-coded category." -ForegroundColor Cyan
Write-Host "`nThe custom view XML files have been saved to:" -ForegroundColor Cyan
Write-Host "$CustomViewsPath" -ForegroundColor Cyan
Write-Host "`nTo import these views in Event Viewer:" -ForegroundColor Cyan
Write-Host "1. Open Event Viewer" -ForegroundColor Cyan
Write-Host "2. Right-click 'Custom Views' in the left pane" -ForegroundColor Cyan
Write-Host "3. Select 'Import Custom View...'" -ForegroundColor Cyan
Write-Host "4. Navigate to: $CustomViewsPath" -ForegroundColor Cyan
Write-Host "5. Select the desired .xml file(s)" -ForegroundColor Cyan
Write-Host "`nNote: Each view can be customized further in Event Viewer by right-clicking the view and selecting 'Properties'" -ForegroundColor Yellow


