# Connect to Microsoft Graph with specified scopes
# Connect-MgGraph -Scopes Directory.Read.All, Directory.ReadWrite.All, Organization.Read.All, Organization.ReadWrite.All, Application.ReadWrite.All, User.ReadWrite.All




# Define a function to recursively get subgroups with user members of a specified group
function Get-Subgroups {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$GroupId
    )

    $group = Get-MgGroup -GroupId $GroupId
    $groups = @()

    if ($group) {
        $subs = Get-MgGroupMember -GroupId $group.Id

        foreach ($sub in $subs) {
            $subDetails = Get-MgUser -UserId $sub.Id -ErrorAction SilentlyContinue

            if ($subDetails) {
                # If $sub is a user, add it to the list of groups
                $groups += $group
            }
            else {
                # If $sub is a group, recursively get subgroups
                $subGroupDetails = Get-MgGroup -GroupId $sub.Id -ErrorAction SilentlyContinue

                if ($subGroupDetails) {
                    $groups += Get-Subgroups -GroupId $sub.Id
                }
            }
        }
    }
    $groups = $groups | select-object displayname, id | Get-Unique -AsString
    return $groups
}

# Define a function to apply a license to leaf groups in a hierarchy
function Grant-LicenseToSubgroups {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TopGroupName, # Name of the top-level group
        [Parameter(Mandatory = $true)]
        [string]$LicenseName # SkuPartNumber / license name
    )

    # Get the top-level Azure AD group
    $topGroup = Get-MgGroup -Filter "displayName eq '$TopGroupName'"

    $Sku = Get-MgSubscribedSku -All | Where-object SkuPartNumber -eq $LicenseName

    if ($topGroup) {
        # Recursively retrieve subgroups
        $subgroups = Get-Subgroups -GroupId $topGroup.ObjectId



        foreach ($subgroup in $subgroups) {
            Write-Host "Applying license to $($subgroup.DisplayName)"
            # Apply the license to the subgroup using Microsoft Graph API
            Set-MgGroupLicense -GroupId $subgroup.Id -AddLicenses $Sku.SkuId -RemoveLicenses $()
        }
    }
    else {
        Write-Host "Top-level group '$TopGroupName' not found."
    }
}

function Revoke-LicenseFromSubgroups {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TopGroupName, # Name of the top-level group
        [Parameter(Mandatory = $true)]
        [string]$LicenseName # SkuPartNumber / license name
    )

    # Get the top-level Azure AD group
    $topGroup = Get-MgGroup -Filter "displayName eq '$TopGroupName'"

    if ($topGroup) {
        # Recursively retrieve subgroups
        $subgroups = Get-Subgroups -GroupId $topGroup.ObjectId

        $sku = Get-MgSubscribedSku -All | Where-object SkuPartNumber -eq $LicenseName
     

        foreach ($subgroup in $subgroups) {
            Write-Host "Revoking license from $($subgroup.DisplayName)"
            # Revoke the license from the subgroup using Microsoft Graph API
            Set-MgGroupLicense -GroupId $subgroup.Id -AddLicenses @() -RemoveLicenses $sku.SkuId
        }
    }
    else {
        Write-Host "Top-level group '$TopGroupName' not found."
    }
}

function Add-SubgroupsToEnterpriseApp {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $EnterpriseAppId, # ID or Name of the enterprise application
        [Parameter()]
        [string] $EnterpriseAppName, # ID or Name of the enterprise application
        [Parameter()]
        [string]$TopGroupName, # Name of the top-level group
        [Parameter()]
        [string]$TopGroupID # ID of the top-level group
    )

  
    process {
        try {
            if ($EnterpriseAppId -eq $null -and $EnterpriseAppName -eq $null) {
                Write-Host "Please specify either the EnterpriseAppId or EnterpriseAppName parameter."
                return
            }
            if ($EnterpriseAppId -eq $null) {
                $app = Get-mgapplication -Filter "displayName eq $EnterpriseAppName"
            }
            if ($TopGroupID -eq $null -and $TopGroupName -eq $null) {
                Write-Host "Please specify either the TopGroupID or TopGroupName parameter."
                return
            }
            if ($TopGroupID -eq "") {
                write-host "here"
                $TopGroupID = (Get-MgGroup -Filter "displayName eq '$TopGroupName'").Id
            }
        
            if ($null -eq $app ) {# Get the enterprise application
            $app = Get-mgapplication -ApplicationId $EnterpriseAppId
            }
            if ($app -eq $null) {
                Write-Host "Enterprise application '$EnterpriseAppId' not found."
                return
            }


            $appid = $app.AppId
            $serviceprincipal = Get-MgServicePrincipal -Filter "appId eq '$appid'"
            $approle = $serviceprincipal.approles | where-object DisplayName -eq "User"

            $params = @{
                principalId = ""
                resourceId  = $serviceprincipal.id
                appRoleId   = $approle.Id
            }    
            write-host $TopGroupID
            # Get the subgroup using the Get-Subgroups function
            $subgroups = Get-Subgroups -GroupId $TopGroupID

            if ($subgroups.Count -eq 0) {
                Write-Host "Subgroup '$subgroupId' not found or does not have subgroups."
                continue
            }

            # Add each subgroup as an owner or member to the enterprise application
            foreach ($subgroup in $subgroups) {
                $params.principalId = $subgroup.Id
                write-host $subgroup
                New-MgGroupAppRoleAssignment -BodyParameter $params -GroupId $subgroup.Id
                Write-Host "Added subgroup '$subgroup.DisplayName' to the enterprise application '$EnterpriseAppId'."
            }
            
        }
        catch {
            Write-Host "An error occurred: $_"
        }
    }
}

# Example usage:
# Add-SubgroupsToEnterpriseApp -EnterpriseAppId "YourAppId" -SubgroupIds @("Subgroup1", "Subgroup2")


function Remove-SubgroupsFromEnterpriseApp {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $EnterpriseAppId, # ID or Name of the enterprise application
        [Parameter()]
        [string] $EnterpriseAppName, # ID or Name of the enterprise application
        [Parameter()]
        [string]$TopGroupName, # Name of the top-level group
        [Parameter()]
        [string]$TopGroupID # ID of the top-level group
    )

    process {
        try {
            if ($EnterpriseAppId -eq $null -and $EnterpriseAppName -eq $null) {
                Write-Host "Please specify either the EnterpriseAppId or EnterpriseAppName parameter."
                return
            }
            if ($EnterpriseAppId -eq "") {
                $EnterpriseAppId = (Get-MgApplication -ConsistencyLevel eventual -Count appCount -Search "DisplayName:$EnterpriseAppName").Id
            }
            if ($TopGroupID -eq $null -and $TopGroupName -eq $null) {
                Write-Host "Please specify either the TopGroupID or TopGroupName parameter."
                return
            }
            if ($TopGroupID -eq "") {
                $TopGroupID = (Get-MgGroup -Filter "displayName eq '$TopGroupName'").Id
            }
            if ($null -eq $app) {
            # Get the enterprise application
            $app = Get-mgapplication -ApplicationId $EnterpriseAppId
            }   
            write-host $app
            if ($null -eq $app) {
                Write-Host "Enterprise application '$EnterpriseAppId' not found."
                return
            }

            $appid = $app.AppId
            $serviceprincipal = Get-MgServicePrincipal -Filter "appId eq '$appid'"
            $approle = $serviceprincipal.approles | where-object DisplayName -eq "User"

                           
            # Get the subgroup using the Get-Subgroups function
            $subgroups = Get-Subgroups -GroupId $TopGroupID

            if ($subgroups.Count -eq 0) {
                Write-Host "Subgroup '$TopGroupName' not found or does not have subgroups."
                return
            }
            foreach ($s in $subgroups) {
                $approleid = $approle.id
                $approleassignmentid = get-mggroupapproleassignment -GroupId $s.Id | where-object AppRoleId -eq $approleid
                foreach ($a in $approleassignmentid) {
                    Remove-MgGroupAppRoleAssignment -AppRoleAssignmentId $a.Id -GroupId $s.Id
                }
                
                Write-Host "Removed subgroup '$s.DisplayName' from the enterprise application '$EnterpriseAppId'."
            }

            
        }
        catch {
            Write-Host "An error occurred: $_"
        }
    }
}

# Example usage:
# Remove-SubgroupsFromEnterpriseApp -EnterpriseAppId "YourAppId" -TopGroupName "TopGroup"
