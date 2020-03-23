clear

$groupName = "SG SETC Modern Workplace" #Read-Host -Prompt 'Please insert the group name..'
$newEmail = #Read-Host -Prompt 'Please insert the new email you want to use for the group..'

$userCredential = Get-Credential -UserName "ant.gatti@avanade.com" -Message "Type the password."
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session
Connect-MsolService -Credential $userCredential

#Import-module MSOnline
#Set-ExecutionPolicy Unrestricted
#Start-service winrm

Set-UnifiedGroup -Identity $groupName -EmailAddress: @{Add ="SGSETCModernWorkplace@avanade.com"}

#Promote alias as a primary SMTP address,
#Set-UnifiedGroup -Identity $groupName -PrimarySmtpAddress "RTprojects@rocktree.sg"
 
#if not required, you can remove aliases
#Set-UnifiedGroup -Identity $groupName  -EmailAddresses: @{Add='opopop@rocktree.sg'}

Remove-PSSession $Session