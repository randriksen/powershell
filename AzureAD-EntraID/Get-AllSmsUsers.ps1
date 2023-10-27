$users = Get-MgUser -All -filter "accountEnabled eq true" 

$usersWithOnlySMS = @()
$usersWithNoMFA = @()

$count = 0
foreach ($u in $users) {
    $count++
    if ($count % 25 -eq 0) {
        write-host "Processing user $count"
    }
    #write-host  $u.DisplayName
    

    $authenticationMethods = Get-MgUserAuthenticationMethod -UserId $u.Id
    if ($authenticationMethods.count -lt 1) {
        $usersWithNoMFA += $u
        continue
    }
    $phoneEnabled = $false
    $authentcatorEnabled = $false
    switch ($authenticationMethods.AdditionalProperties.'@odata.type') {
        "#microsoft.graph.passwordAuthenticationMethod" {
            #$authenticationMethods.AdditionalProperties
        }
        "#microsoft.graph.fido2AuthenticationMethod" {
            #$authenticationMethods.AdditionalProperties
        }
        "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" {
            $authentcatorEnabled = $true
        }
        "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" {
            #$authenticationMethods.AdditionalProperties
        }
        "#microsoft.graph.phoneAuthenticationMethod" {
            $phoneEnabled = $true
        }
        "#microsoft.graph.softwareOathAuthenticationMethod" {
            #$authenticationMethods.AdditionalProperties
        }
    
    }
    if ($phoneEnabled -and !$authentcatorEnabled) {
        $usersWithOnlySMS += $u
    }
}

$usersWithOnlySMS | select UserPrincipalName, DisplayName, MobilePhone | export-csv -Path "c:\temp\usersWithOnlySMS.csv"
$usersWithNoMFA | select UserPrincipalName, DisplayName, MobilePhone | export-csv -Path "c:\temp\usersWithNoMFA.csv" -NoTypeInformation
