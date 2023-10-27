# Define variables
$url = "your server url"
$regtoken = "your registration token"
$description = "your runner description"
$tags = "your runner tags"
$username = "your service user"
$password = "your service user password"

$serviceuser = $true

$modules = @("Az", "SqlServer", "Microsoft.Graph", "Microsoft.PowerShell.SecretManagement", "Microsoft.PowerShell.SecretStore")
$features = @("RSAT-AD-PowerShell", "RSAT-DHCP")

# Function to grant the "Log on as a service" right
function Grant-ServiceUserLogon {
    <#
.Synopsis
  Grant logon as a service right to the defined user.
.Description
  Stolen from : https://stackoverflow.com/questions/313831/using-powershell-how-do-i-grant-log-on-as-service-to-an-account
.Parameter computerName
  Defines the name of the computer where the user right should be granted.
  Default is the local computer on which the script is run.
.Parameter username
  Defines the username under which the service should run.
  Use the form: domain\username.
  Default is the user under which the script is run.
.Example
  Usage:
  .\Grant-ServiceUserLogon -computerName hostname.domain.com -username "domain\username"
#>
param(
    [string] $computerName = ("{0}.{1}" -f $env:COMPUTERNAME.ToLower(), $env:USERDNSDOMAIN.ToLower()),
    [string] $username = ("{0}\{1}" -f $env:USERDOMAIN, $env:USERNAME)
  )
  Invoke-Command -ComputerName $computerName -Script {
    param([string] $username)
    $tempPath = [System.IO.Path]::GetTempPath()
    $import = Join-Path -Path $tempPath -ChildPath "import.inf"
    if(Test-Path $import) { Remove-Item -Path $import -Force }
    $export = Join-Path -Path $tempPath -ChildPath "export.inf"
    if(Test-Path $export) { Remove-Item -Path $export -Force }
    $secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
    if(Test-Path $secedt) { Remove-Item -Path $secedt -Force }
    try {
      Write-Host ("Granting SeServiceLogonRight to user account: {0} on host: {1}." -f $username, $computerName)
      $sid = ((New-Object System.Security.Principal.NTAccount($username)).Translate([System.Security.Principal.SecurityIdentifier])).Value
      secedit /export /cfg $export
      $sids = (Select-String $export -Pattern "SeServiceLogonRight").Line
      foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsAService security template", "[Privilege Rights]", "$sids,*$sid")){
        Add-Content $import $line
      }
      secedit /import /db $secedt /cfg $import
      secedit /configure /db $secedt
      gpupdate /force
      Remove-Item -Path $import -Force
      Remove-Item -Path $export -Force
      Remove-Item -Path $secedt -Force
    } catch {
      Write-Host ("Failed to grant SeServiceLogonRight to user account: {0} on host: {1}." -f $username, $computerName)
      $error[0]
    }
  } -ArgumentList $username
}

# Function to install GitLab Runner
function install-GitlabRunner {
    Param (
        [Parameter(Mandatory = $false)]
        [string]$user,
        [Parameter(Mandatory = $false)]
        [string]$password,
        [Parameter(Mandatory = $true)]
        [string]$url,
        [Parameter(Mandatory = $true)]
        [string]$regtoken,
        [Parameter(Mandatory = $false)]
        [string]$tags = "powershell",
        [Parameter(Mandatory = $false)]
        [string]$name = "gitlab-runner",      
        [Parameter(Mandatory = $false)]
        [bool]$serviceuser = $false,
        [Parameter(Mandatory = $false)]
        [string]$installPath = "C:\GitLab-Runner",
        [Parameter(Mandatory = $false)]
        [string]$psversion = "7"

    )

    # Run PowerShell as administrator
    # Create a folder for GitLab Runner
    New-Item -Path $installPath -ItemType Directory

    # Change to the folder
    cd $installPath

    # Download GitLab Runner binary
    Invoke-WebRequest -Uri "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe" -OutFile "gitlab-runner.exe"

    # Register the runner
    .\gitlab-runner.exe install --user $user --password $password 
    .\gitlab-runner.exe start

    # Register the runner with GitLab
    .\gitlab-runner.exe register --url $url --registration-token $regtoken --executor shell --tag-list $tags --name $name  -n

    if ($psversion -ne "7") {
        # Change the shell to PowerShell 5.1
        $config = Get-Content .\config.toml
        $config = $config -replace "shell = ""pwsh""", "shell = ""powershell"""
        $config | Set-Content .\config.toml
    }
}

# Function to install Git
function install-git {
    # Install Git
    invoke-webrequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe" -OutFile "$env:TEMP\git.exe"
    .$env:TEMP\git.exe /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh" /DIR="C:\Program Files\Git"
}

# Function to install PowerShell modules
function install-modules {
    Param (
        [Parameter(Mandatory = $false)]
        [string]$psversion = "7",
        [Parameter(Mandatory = $true)]
        [string[]]$modules
    )
    # Install modules
    
    foreach ($module in $modules) {
        if (!(Get-Module -Name $module -ListAvailable)) {
            Install-Module -Name $module -Scope AllUsers -force 
        }
    }
}

# Function to install Windows features
function install-features {
    Param (
        [Parameter(Mandatory = $true)]
        [string[]]$features
    )
    
    Install-WindowsFeature $features
}

function install-ps7 {
    # Install PowerShell 7
    Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.3.8/PowerShell-7.3.8-win-x64.msi" -OutFile "$env:TEMP\pwsh.msi"
    msiexec.exe /i $env:TEMP\pwsh.msi /qn /norestart
}

# Check if a service user is provided
if ($serviceuser) {
    # Grant the "Log on as a service" right to the service user
    Grant-ServiceUserLogon -Username $username
    
    # Install GitLab Runner for the service user
    install-GitlabRunner -user $username -password $password -url $url -regtoken $regtoken  -serviceuser $serviceuser
}
else {
    # Install GitLab Runner without a service user
    install-GitlabRunner -url $url -regtoken $regtoken -serviceuser $serviceuser
}

if ($psversion -eq "7") {
    # Install PowerShell 7
    install-ps7
}
# Install Git, PowerShell modules, and Windows features
install-git
install-modules -modules $modules
install-features -features $features
restart-service gitlab-runner
