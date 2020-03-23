################################################################
### MAKE SURE TO UPDATE THE PARAMETERS BEFORE RUN THE SCRIPT ###
################################################################

#region PARAMETERS
$GroupDisplayName = "Office group name"
$EmailAlias = "officegroup"

#Owners (use ; more multiple useers)
$Owners = "user1@tenant.com;user2@tenant.com"
#Members (use ; more multiple useers)
$Members = "user1@tenant.com;user2@tenant.com"

#endregion

$o365DomainName="tenant" 
 
#Step2: Connect to SharePoint Online using “Connect-SPOService” cmdlet 
$SPOAdminCenterUrl="https://"+ $o365DomainName +"-admin.sharepoint.com/"  
$credential = Get-Credential -UserName administrator@rocktree.sg -Message "Type the password."
Connect-SPOService -Url $SPOAdminCenterUrl -Credential $credential  

#Create remote Powershell session 
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Office365credentials -Authentication Basic –AllowRedirection         
#Import the session 
Import-PSSession $Session -AllowClobber | Out-Null 

#Check if the group email already exist as Distribution list
$objDistributionGroup = Get-DistributionGroup | where {$_.PrimarySMTPAddress -eq $EmailAlias + "@rocktree.sg"}

#Email alias does exist, needs to delete the distribution list first
if($objDistributionGroup -ne $null)
{
    $Readhost = Read-Host "Do you want to delete the distribution list " $objDistributionGroup.PrimarySMTPAddress " ( y / n ) " 
    Switch ($ReadHost) 
     { 
       Y 
        {
            Remove-DistributionGroup -Identity $objDistributionGroup.PrimarySMTPAddress -Confirm: $false
            Write-Host "Distribution list " $objDistributionGroup.PrimarySMTPAddress " has been deleted."
        } 
       N 
        {
            Write-Host "Ok, the distribution list will not be deleted"
        }
     }
}

Write-Host "Creating " $GroupDisplayName " group"
$newGroup = New-UnifiedGroup –DisplayName $GroupDisplayName -Alias $EmailAlias -AccessType Private
#$newGroup = Get-SPOSite | where {$_.Url -like "*testt"}
Set-UnifiedGroup -Identity $newGroup.Name -RequireSenderAuthenticationEnabled $false
Write-Host "Created!"

#Permissions
Write-Host "Adding permission"

#Add Mermbers
Foreach($user in ($Owners + ";" + $Members) -split ";" | select -uniq)
{
    Write-Host "Adding permission as MEMBER " $user
    Add-UnifiedGroupLinks –Identity $newGroup.Name –LinkType Members –Links $user
    Write-Host "Member Added!"
}


#Add Owners
Foreach($user in $Owners -split ";" )
{
    Write-Host "Adding permission as OWNER " $user
    Add-UnifiedGroupLinks –Identity $newGroup.Name –LinkType Owners –Links $user
    Write-Host "Owner Added!"
}

Remove-PSSession $Session