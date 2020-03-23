$o365DomainName="tenant" 
$SPOAdminCenterUrl="https://"+ $o365DomainName +"-admin.sharepoint.com/"  
$credential = Get-Credential -UserName administrator@rocktree.sg -Message "Type the password."
Connect-SPOService -Url $SPOAdminCenterUrl -Credential $credential
 
#Step3: To get all the Office 365 groups, we use “Get-UnifiedGroup” cmdlet, which depends on Exchange Online 
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $credential -Authentication Basic -AllowRedirection 
Import-PSSession $Session 
$SPO365GroupFilesUrl ="https://"+ $o365DomainName +".sharepoint.com/sites/" 
$Groups=Get-UnifiedGroup 
$Groups | Foreach-Object{ 
$Group = $_ 
$GName=$Group.Alias 
$site=Get-SPOSite -Identity $SPO365GroupFilesUrl$GName 
      New-Object -TypeName PSObject -Property @{ 
      GroupName=$site.Title 
      CurrentStorage=$site.StorageUsageCurrent 
      StorageQuota=$site.StorageQuota 
      StorageQuotaWarningLevel=$site.StorageQuotaWarningLevel 
}}|select GroupName, CurrentStorage, StorageQuota, StorageQuotaWarningLevel 