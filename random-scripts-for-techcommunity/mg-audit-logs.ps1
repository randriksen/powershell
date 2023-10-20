# for https://techcommunity.microsoft.com/t5/windows-powershell/how-can-i-pull-up-os-versions-a-teams-device-is-installed/m-p/3948556#M7221
Import-Module Microsoft.Graph.Reports
Connect-MgGraph -Scope AuditLog.Read.All,Directory.Read.All
Get-MgAuditLogSignIn -filter 'contains(appDisplayName,"Teams")' | select -Unique userprincipalname, appdisplayname, @{label="OS"; expression={$_.devicedetail.operatingsystem} }