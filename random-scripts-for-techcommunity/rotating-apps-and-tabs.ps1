#this script was for https://techcommunity.microsoft.com/t5/windows-powershell/rotating-applications-on-desktop-using-windows-powershell/m-p/3938277
#someone wanted a script to automatically rotate between applications and browsertabs on their desktop


# This script will rotate between the specified applications

$AppNames = @( "edge","chrome","code" )
$wait_time=15
$global:counter=0

# Create a function to switch tabs in the browser
function Switch-BrowserTab($browsername) {
  $browser = New-Object -ComObject wscript.shell 
  if ($browser) {
    $browser.SendKeys('^{TAB}')
  }
}

function Activate-Window ($appname) {
  $app = New-Object -ComObject wscript.shell 
  $app.AppActivate($appname)
}

# Create a function to rotate between applications
function Rotate-Apps() {
  if ($global:counter -eq $AppNames.Length) {
    $global:counter=0
  }
  $global:counter
  Activate-Window -appname $AppNames[$global:counter]
  
  # Restore the current application window
  # Switch tabs in the browser
  Switch-BrowserTab -browsername $AppNames[$global:counter]
  $global:counter++
  # Wait for the specified time interval
  Start-Sleep -Seconds $waitTime

  
}

# Start the rotation loop

while ($true) {
  Rotate-Apps
}