
install-module mggraph
import-module mggraph


Connect-MgGraph -Scopes DeviceManagementServiceConfig.Read.All,DeviceManagementServiceConfig.ReadWrite.All

$autopilotdevices = Get-AutopilotDevice
$devicesWOTagsOrPOI = $autopilotdevices | where-object groupTag -like $null | where-object purchaseOrderIdentifier -like $null

foreach ($dev in $devicesWOTagsOrPOI) {
    set-autopilotdevice -deviceid $dev.deviceid -groupTag "Tag"
}