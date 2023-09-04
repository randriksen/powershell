# Connect to Microsoft Graph with specified scopes
Connect-MgGraph -Scopes Directory.Read.All,Directory.ReadWrite.All,Organization.Read.All,Organization.ReadWrite.All

# Define a function to create license parameters based on a license name/SkuPartNumber 
# This can be found by running Get-MgSubscribedSku
function make-licenceparameters ($license) {
    # Get the subscribed SKU matching the given license
    $sku = Get-MgSubscribedSku | where skupartnumber -eq $license
    
    # Define license parameters
    $params = @{
        addLicenses = @(
            @{
                disabledPlans = @(
                    # List of disabled plans (if any)
                )
                skuId = $sku.skuid
            }
        )
        removeLicenses = @(
            # List of licenses to remove (if any)
        )
    }
    return $params
}

# Define a function to recursively get subgroups with user members of a specified group
function Get-Subgroups {
    param (
        [string]$GroupId
    )

    $group = Get-MgGroup -GroupId $GroupId
    $groups = @()

    if ($group) {
        $subs = Get-MgGroupMember -groupid $group.Id

        foreach ($sub in $subs) {
            $subDetails = Get-MgUser -userid $sub.Id -ErrorAction SilentlyContinue


            if ($subDetails) { #if $sub is a user, add it to the list of groups
                $groups += $group
                break
            } else { # if $sub is a group, recusevly get subgroups
                $subGroupDetails = Get-MgGroup -groupId $sub.Id -ErrorAction SilentlyContinue

                if ($subGroupDetails) {
                    $groups += Get-Subgroups -GroupId $sub.Id
                }
            }
        }
    }

    return $groups 
}

# Define a function to apply a license to leaf groups in a hierarchy
function license-leafgroups {
    param (
        [string]$topGroupName, #name of the top-level group
        [string]$licenseName #SkuPartNumber / license name
    )
    
    # Get the top-level Azure AD group
 	$topGroup = Get-MgGroup -Filter "displayName eq '$topGroupName'"
	
    # Recursively retrieve subgroups
    $subgroups = Get-Subgroups ($topGroup.ObjectId)

    # Generate license parameters for the specified license
    $licenseParameters = make-licenceparameters $licenseName

    foreach ($sub in $subgroups) {
        Write-Host $sub.DisplayName
        # Apply the license to the subgroup using Microsoft Graph API
        Set-MgGroupLicense -GroupId $sub.Id -BodyParameter $licenseParameters -ErrorAction SilentlyContinue
    }
}