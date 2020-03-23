$o365DomainName="tenant" 
$SPOAdminCenterUrl="https://"+ $o365DomainName +"-admin.sharepoint.com/"  
$credential = Get-Credential -UserName administrator@rocktree.sg -Message "Type the password."
Connect-SPOService -Url $SPOAdminCenterUrl -Credential $credential

$TimezoneValue= "(UTC+08:00) Kuala Lumpur, Singapore"
$localeid = 1033
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $cred -Authentication Basic -AllowRedirection 
Import-PSSession $Session

#Add references to SharePoint client assemblies
Add-Type -Path ([System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client").location)
Add-Type -Path ([System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.runtime").location)

$Groups =Get-UnifiedGroup |Where-Object {$_.SharePointSiteUrl -ne $null}|select SharePointSiteUrl

foreach($Group in $Groups.SharePointSiteUrl)
{
    #Authenticate to Site
    $Username =$cred.UserName.ToString()
    $Password = $cred.GetNetworkCredential().Password 
    $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
    $Site = $Group
    $Context = New-Object Microsoft.SharePoint.Client.ClientContext($Site)
    $Creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Username,$SecurePassword)
    $Context.Credentials = $Creds

    $TimeZones = $Context.Web.RegionalSettings.TimeZones
    $Context.Load($TimeZones)
    $Context.ExecuteQuery()

    #Changing  the timezone
    $RegionalSettings = $Context.Web.RegionalSettings
    $Context.Load($RegionalSettings)
    $Context.ExecuteQuery()
    $TimeZone = $TimeZones | Where {$_.Description -eq $TimezoneValue}
    $RegionalSettings.TimeZone = $TimeZone
    $RegionalSettings.Localeid = $localeid
    $Context.Web.Update()
    $Context.ExecuteQuery()

    Write-Host "Time Zone successfully updated for $($site) "
} 