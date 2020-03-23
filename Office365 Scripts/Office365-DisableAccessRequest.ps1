$o365DomainName="tenant" 
 
#Step2: Connect to SharePoint Online using “Connect-SPOService” cmdlet 
$SPOAdminCenterUrl="https://"+ $o365DomainName +"-admin.sharepoint.com/"  
$credential = Get-Credential -UserName administrator@rocktree.sg -Message "Type the password."
Connect-SPOService -Url $SPOAdminCenterUrl -Credential $credential  
 
#Step3: To get all the Office 365 groups, we use “Get-UnifiedGroup” cmdlet, which depends on Exchange Online 
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $credential -Authentication Basic -AllowRedirection 
Import-PSSession $Session 

$Groups=Get-UnifiedGroup 

Add-Type -Path "C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Microsoft.SharePoint.Client\v4.0_16.0.0.0__71e9bce111e9429c\Microsoft.SharePoint.Client.dll"  
Add-Type -Path "C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Microsoft.SharePoint.Client.Runtime\v4.0_16.0.0.0__71e9bce111e9429c\Microsoft.SharePoint.Client.Runtime.dll"  
 
$username = "administrator@rocktree.sg" 
$password = Read-Host -Prompt "Enter password" -AsSecureString 


foreach($group in $groups) 
{ 
    $ctx = New-Object Microsoft.SharePoint.Client.ClientContext($group.SharePointSiteUrl)   
    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $password) 
    $ctx.Credentials = $credentials

    $ctx.Load($ctx.Web) 
    $ctx.ExecuteQuery() 

    $ctx.Load($ctx.Web.AllProperties)
    $ctx.ExecuteQuery() 
}

Remove-PSSession $Session