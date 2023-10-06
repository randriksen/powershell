#this script was for https://techcommunity.microsoft.com/t5/windows-powershell/powershell-script/m-p/3947118/highlight/false#M7212
#someone wanted a script to send an email when a user was locked out of their account

#make a scheduled task triggered on the event and then have it run this script


$alert = Get-EventLog -LogName security -instanceid 4740 -Newest 1
$body = $alert.message



#Send email with the report
$smtpServer = "yourmailserver"
$smtpPort = 25
#$smtpUsername = "email address removed for privacy reasons"
#$smtpPassword = "your_email_password"
             
$to = "sendto"
$from = "sendrom"
$event = $alert.entrytype
$time = $alert.TimeGenerated
$subject = "$event - $time"
             
$message = New-Object System.Net.Mail.MailMessage $from, $to
$message.Subject = $subject
$message.Body = $body
#$message.IsBodyHtml = $true
             
$smtp = New-Object System.Net.Mail.SmtpClient $smtpServer, $smtpPort
#$smtp.EnableSsl = $true
#$smtp.Credentials = New-Object System.Net.NetworkCredential $smtpUsername, $smtpPassword

$smtp.Send($message)