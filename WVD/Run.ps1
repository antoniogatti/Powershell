Import-Module -Name Microsoft.RDInfra.RDPowerShell  -Force

$configPath = "$PSScriptRoot\config.json"
$Config = Get-Content -Raw -Path $configPath | ConvertFrom-Json

Add-RdsAccount -DeploymentUrl $Config.VirtualDesktopDeploymentUrl
#Create Tenant
New-RdsTenant -Name $Config.TenantName -AadTenantId $Config.TenantId -AzureSubscriptionId $Config.SubscriptionId
#Create Host Pool -> Provision Host Pool using Azure Portal
$HostPoolObj = Get-RdsAppGroup $Config.TenantName $Config.HostPoolName

#Grant Users to Host Pool
if($Config.Users.Length -gt 0)
{
    foreach ($u in $Config.Users) {
        Add-RdsAppGroupUser $Config.TenantName $Config.HostPoolName $HostPoolObj.AppGroupName -UserPrincipalName $u
    }
}

#Create App Group
New-RdsAppGroup $Config.TenantName $Config.HostPoolName "New App Group" -ResourceType RemoteApp
#Get Virtual Machine Installed Apps
Get-RdsStartMenuApp $Config.TenantName $Config.HostPoolName "New App Group" | Select-Object FriendlyName, AppAlias
#Create Remote App
New-RdsRemoteApp $Config.TenantName $Config.HostPoolName "New App Group" -Name "My app" -AppAlias "MyApp"
#https://rdweb.wvd.microsoft.com/webclient