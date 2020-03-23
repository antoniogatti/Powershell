###################################################################
###################################################################
#### SCOPE: Migrate Office 365 group site to SharePoint Online ####
#### Migrate the site, permissions and contents                ####
###################################################################
###################################################################

$rootSite = "https://tenant.sharepoint.com/"

$o365DomainName="tenant" 
$SPOAdminCenterUrl="https://"+ $o365DomainName +"-admin.sharepoint.com/"  
$credential = Get-Credential -UserName administrator@rocktree.sg -Message "Type the password."
Connect-SPOService -Url $SPOAdminCenterUrl -Credential $credential  

Foreach ($g in Get-UnifiedGroup)
{
	$name = $g.DisplayName    
    #$primary = $g.PrimarySmtpAddress
    #$adresses = $g.EmailAddresses -replace "SMTP:", ""
    #$spUrl = $g.SharePointSiteUrl

    Write-Host "Processing " $name
    
    $Readhost = Read-Host "Do you want to create a SharePoint site for the group" $name " ( y / n ) " 
    Switch ($ReadHost) 
     { 
       Y 
        {
            Write-host "Creating the site " $name
        } 
       N 
        {
            Write-Host "Ok, the site will not be created"
        }
     } 


    #values to change for a new site
    $prefix = "sites/"
    $newSite = "SP" + $g.Name 
    $siteTitle = $g.DisplayName 


    $owner = "user@tenant.com"
    $storageQuota = 100000
    $resourceQuota = 50
    $template = "STS#0"
    $newFullSiteUrl = $rootSite + $prefix + $newSite



    #verify if site already exists in SharePoint Online
    $siteExists = get-SPOSite | where{$_.url -eq $newFullSiteUrl}
 
    #verify if site already exists in the recycle bin
    $siteExistsInRecycleBin = get-SPODeletedSite | where{$_.url -eq $newFullSiteUrl}

    #create site if it doesn't exists
    if (($siteExists -eq $null) -and ($siteExistsInRecycleBin -eq $null)) {

        write-host "Creating " $newFullSiteUrl -foregroundcolor green
        New-SPOSite -Url $newFullSiteUrl -title $siteTitle -Owner $owner -StorageQuota $storageQuota -ResourceQuota $resourceQuota -Template $template

        write-host "Populating the Owners and members groups" -foregroundcolor green
        $spGroups = Get-SPOSiteGroup -Site $newFullSiteUrl

        Foreach ($group in $spGroups)
        {
            $owners = Get-UnifiedGroupLinks -Identity $g.Alias -LinkType Owners
	        $members = Get-UnifiedGroupLinks -Identity $g.Alias -LinkType Members

            #Add owners
            if($group -like "Owners")
            {
                Foreach ($owner in $owners)
                {
                    Add-SPOUser -Site $newFullSiteUrl -LoginName $owner.PrimarySmtpAddress -Group $group.Title
                    write-host $owner.PrimarySmtpAddress " has been added in " $group.Title
                }
            }

            #Add members
            if($group -like "Members")
            {
                Foreach ($member in $members)
                {
                    Add-SPOUser -Site $newFullSiteUrl -LoginName $member.PrimarySmtpAddress -Group $group.Title
                    write-host $member.PrimarySmtpAddress " has been added in " $group.Title
                }
            }
        }

    }
    else
    {
        write-host "The site $($newFullSiteUrl) already exists" -foregroundcolor red
    }
}
