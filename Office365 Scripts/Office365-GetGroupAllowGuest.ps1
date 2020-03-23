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

Connect-SPOService -url https://rocktree-admin.sharepoint.com/ -Credential $Office365Credentials
Connect-AzureAD -Credential $Office365Credentials

Foreach ($g in Get-UnifiedGroup)
{
    $type = "Office 365 Group"
	$name = $g.DisplayName    
    $primary = $g.PrimarySmtpAddress
    $adresses = $g.EmailAddresses -replace "SMTP:", ""
    $spUrl = $g.SharePointSiteUrl

    $groupID= (Get-AzureADGroup -SearchString $g.EmailAddresses).ObjectId
    $allowGuest = Get-AzureADObjectSetting -TargetObjectId $groupID -TargetType Groups | fl 

    Write-Host "Processing " $type " " $name
}

#Clean up session 
Get-PSSession | Remove-PSSession 

