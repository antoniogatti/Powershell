#Constant Variables 
$OutputFile = "DistributionAndGroups.csv"   #The CSV Output file that is created, change for your purposes 
 
clear
#Remove all existing Powershell sessions 
Get-PSSession | Remove-PSSession 
 
#Build credentials object 
$Office365Credentials  = Get-Credential -UserName administrator@rocktree.sg -Message "Type the password."

#Create remote Powershell session 
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Office365credentials -Authentication Basic –AllowRedirection         
#Import the session 
Import-PSSession $Session -AllowClobber | Out-Null          
 
#Prepare Output file with headers 
Out-File -FilePath $OutputFile -InputObject "Type, Name, Primary Email, All Email addresses, URL, Owner Names, Owner Emails, Member Names, Member Emails" -Encoding UTF8 

#Get all Distribution Groups from Office 365 
$objDistributionGroups = Get-DistributionGroup -ResultSize Unlimited 
 
#Iterate through all groups, one at a time     
Foreach ($dl in $objDistributionGroups) 
{     
    $type = "Distrution List"
	$name = $dl.DisplayName
    $primary = $dl.PrimarySMTPAddress
    $adresses = $dl.EmailAddresses -replace "SMTP:", ""
    $spUrl = ""

    $ownerNames = ""
    $owner = ""
    $memberNames = (Get-DistributionGroupMember -Identity $dl.PrimarySMTPAddress).Name -join "; "
	$members = (Get-DistributionGroupMember -Identity $dl.PrimarySMTPAddress).PrimarySMTPAddress -join "; "

    Write-Host "Processing " $type " " $name
    Out-File -FilePath $OutputFile -InputObject "$type, $name, $primary, $adresses, $spUrl, $ownerNames, $owner, $memberNames, $members)" -Encoding UTF8 -append 
} 

Connect-SPOService -url https://rocktree-admin.sharepoint.com/ -Credential $Office365Credentials

Foreach ($g in Get-UnifiedGroup)
{
    $type = "Office 365 Group"
	$name = $g.DisplayName    
    $primary = $g.PrimarySmtpAddress
    $adresses = $g.EmailAddresses -replace "SMTP:", ""
    $spUrl = $g.SharePointSiteUrl

    $ownerNames = (Get-UnifiedGroupLinks -Identity $g.Alias -LinkType Owners).Name -join "; "
    $owner = (Get-UnifiedGroupLinks -Identity $g.Alias -LinkType Owners).PrimarySmtpAddress -join "; "
    $memberNames = (Get-UnifiedGroupLinks -Identity $g.Alias -LinkType Members).Name -join "; "
	$members = (Get-UnifiedGroupLinks -Identity $g.Alias -LinkType Members).PrimarySmtpAddress -join "; "

    Write-Host "Processing " $type " " $name
    Out-File -FilePath $OutputFile -InputObject "$type, $name, $primary, $adresses, $spUrl, $ownerNames, $owner, $memberNames, $members)" -Encoding UTF8 -append 
}

#Clean up session 
Get-PSSession | Remove-PSSession 

