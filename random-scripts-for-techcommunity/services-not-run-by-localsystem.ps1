#this was for https://techcommunity.microsoft.com/t5/windows-powershell/powershell-to-export-list-of-all-services-not-running-as-system/m-p/3945374
#someone wanted a script to export a list of all services not running as the SYSTEM account on all computers in a domain

# Get a list of all computers in the domain (you may need to customize this query)
$Computers = Get-ADComputer -Filter * -SearchBase "OU=Citrix,OU=HCAA,DC=PACs,DC=local"

# Create a new CSV file
$CSVFile = "c:\temp\services_not_running_as_system.csv"
New-Item -ItemType File -Path $CSVFile

# Add the header row to the CSV file
Add-Content -Path $CSVFile -Value "SystemName,Name,DisplayName,StartMode,StartName,State"

# Iterate through each computer and get a list of all services not running as the SYSTEM account
foreach ($Computer in $Computers) {
    try {
        Invoke-Command -ComputerName ($Computer.name) -ScriptBlock {
            Get-CIMInstance -Class Win32_Service | where-object StartName -notlike 'LocalSystem' | where-object StartName -notlike 'NT Authority%' 
        } | Select-Object SystemName, Name, DisplayName, StartMode, StartName, State | Export-Csv -Path $CSVFile -Append -NoTypeInformation
    } catch {
        Write-Host "Error connecting to $($Computer.name)" -ForegroundColor Red
    }
}