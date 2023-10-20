connect-mggraph

# Get a list of subscribed SKUs (licenses)
$licenses = Get-MgSubscribedSku -All

# Define an array of license SKUs to exclude from further analysis
$exclude = @("VISIOCLIENT", "PROJECTPREMIUM", "MEETING_ROOM", "EMSPREMIUM_EDU_FACULTY", "PROJECTPROFESSIONAL", "RMSBASIC")

# Filter licenses that are running out
$runningOut = $licenses | where-object SkuPartNumber -NotIn $exclude | select SkuPartNumber, ConsumedUnits, @{label="Enabled"; expression={$_.PrepaidUnits.Enabled}} | where-object {$_.ConsumedUnits -gt ($_.enabled-3)}

# Check if there are licenses running out
if (!$null -eq $runningOut) {
    # If there are licenses running out do something
    write-host $runningOut
}