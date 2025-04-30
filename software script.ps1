# Software and Update Inventory Script

$executionType = Read-Host "Scan (1) Local or (2) Remote machines? (1/2)"
$computers = @()

if ($executionType -eq "1") {
    $computers += $env:COMPUTERNAME
} elseif ($executionType -eq "2") {
    Write-Host "`nEnter the path to a text file containing computer names (one per line)"
    Write-Host "Example: C:\temp\computers.txt"
    Write-Host "Example file contents:"
    Write-Host "COMPUTER1"
    Write-Host "COMPUTER2"
    Write-Host "COMPUTER3`n"
    $computers = Get-Content (Read-Host "Enter path to computer list file")
} else {
    Write-Error "Invalid selection. Use 1 or 2."
    exit
}

$OutputPath = Read-Host "Enter output path (default: .\SoftwareInventory.csv)"
if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = ".\SoftwareInventory.csv" }

$softwareResults = @()
$updateResults = @()

foreach ($computer in $computers) {
    if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
        Write-Host "Processing $computer..."
        
        $softwareResults += Get-WmiObject -Class Win32_Product -ComputerName $computer | 
            Select-Object @{Name='ComputerName'; Expression={$computer}},
                        @{Name='ApplicationName'; Expression={$_.Name}},
                        @{Name='Version'; Expression={$_.Version}},
                        @{Name='InstallDate'; Expression={$_.InstallDate}}
        
        $updateResults += Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName $computer |
            Select-Object @{Name='ComputerName'; Expression={$computer}},
                        @{Name='HotFixID'; Expression={$_.HotFixID}},
                        @{Name='Description'; Expression={$_.Description}},
                        @{Name='InstalledOn'; Expression={$_.InstalledOn}}
    } else {
        Write-Warning "Could not connect to $computer"
    }
}

# Create Excel workbook
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$workbook = $excel.Workbooks.Add()

# Add software data
$worksheet1 = $workbook.Worksheets.Item(1)
$worksheet1.Name = "Installed Software"
$worksheet1.Cells.Item(1, 1).EntireRow.Font.Bold = $true
$worksheet1.QueryTables.Add("TEXT;$(($softwareResults | ConvertTo-Csv -NoTypeInformation | Out-String))", $worksheet1.Range("A1")).Refresh()

# Add updates data
$worksheet2 = $workbook.Worksheets.Add()
$worksheet2.Name = "Windows Updates"
$worksheet2.Cells.Item(1, 1).EntireRow.Font.Bold = $true
$worksheet2.QueryTables.Add("TEXT;$(($updateResults | ConvertTo-Csv -NoTypeInformation | Out-String))", $worksheet2.Range("A1")).Refresh()

# Format and save
$worksheet1.UsedRange.EntireColumn.AutoFit()
$worksheet2.UsedRange.EntireColumn.AutoFit()
$workbook.SaveAs($OutputPath)
$workbook.Close()
$excel.Quit()

# Cleanup
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet1) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet2) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

Write-Host "Results saved to $OutputPath"
