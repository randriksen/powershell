# Check if the mggraph module is already installed
if (-not (Get-Module -ListAvailable -Name mggraph)) {
    # If not installed, install the mggraph module
    Install-Module -Name mggraph -Force
}

# Import the mggraph module
Import-Module -Name mggraph

# Connect to the Microsoft Graph API with the required scopes
Connect-MgGraph -Scopes DeviceManagementServiceConfig.Read.All, DeviceManagementServiceConfig.ReadWrite.All

# Get a list of Autopilot devices
$autopilotDevices = Get-AutopilotDevice

# Filter devices that do not have a groupTag or purchaseOrderIdentifier
$devicesWithoutTagsOrPOI = $autopilotDevices | Where-Object { $_.GroupTag -eq $null -or $_.PurchaseOrderIdentifier -eq $null }

# Define the groupTag value to assign to devices without tags
$newGroupTag = "Tag"

# Loop through devices without tags or purchase order identifiers and set the groupTag
foreach ($device in $devicesWithoutTagsOrPOI) {
    Set-AutopilotDevice -DeviceId $device.DeviceId -GroupTag $newGroupTag
}

# Output a message indicating the completion of the operation
Write-Host "GroupTag has been set for devices without tags or purchase order identifiers."
