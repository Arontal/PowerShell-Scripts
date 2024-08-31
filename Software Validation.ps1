# Using the Registry to Valide whether software is installed. Intent is to mass replicate this information accross a Domain
#Tests whether the software is stored in the 64 bit directory.
Test-path HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ #Software PSPath
#Tests whether the software is stored in the x86 directory.
Test-path HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ #Software PSPath

#Another way to validate software
get-package -name "Google Chrome" # <-(Software Name in "")

# Discovery of various attributes of a program ex Google Chrome. 
Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ #Software PSPath"
Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome"


#Function to Loop against multiple assets 
#List of Active workstations to validate software against in a variable to be called. 
$workstations = Get-Content C:\Users\Public\Desktop\WS.txt | Where-Object ($_)
#Credentials should have elevated priviledges to gain access to each system 
$Creds = Get-Credential

#Foreach will loop through the workstations listed in the WS.txt and output a True or false statement.
foreach ($ws in $workstations){
    $session = Enter-PSSession -ComputerName $ws -Credential $Creds
    Invoke-Command -Session $session -ScriptBlock {
        Write-Host $env:COMPUTERNAME
        Test-path "HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome" -Verbose 
    }
}
