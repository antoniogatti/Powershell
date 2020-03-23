$o365DomainName="tenant" 
$SPOAdminCenterUrl="https://"+ $o365DomainName +"-admin.sharepoint.com/"  
$credential = Get-Credential -UserName administrator@rocktree.sg -Message "Type the password."
Connect-SPOService -Url $SPOAdminCenterUrl -Credential $credential

#List all SharePoint sites
#Get-SPOSite  -Limit All | Format-Table –AutoSize
#Get-SPOSite -Identity  $site

$sites = Get-SPOSite

$sitesTable = @()
Foreach ($s in $sites)
{
    Write-Host "Setting Owner for " $s.Url
    Set-SPOSite -Identity $s.Url -owner administrator@rocktree.sg

    $row = New-Object System.Object 
    $row | Add-Member -type NoteProperty -name "Site Name" -value $s.Title
    $row | Add-Member -type NoteProperty -Name "Site URL" -Value $s.Url
    $row | Add-Member -type NoteProperty -Name "Site Lock Status" -Value $s.LockState
    $row | Add-Member -type NoteProperty -Name "Site Owner" -Value $s.Owner
    $sitesTable += $row
}

#Print table
$sitesTable | Format-Table –AutoSize

#Force unlock and set owner
#Set-SPOSite -Identity $site -LockState Unlock

#Delete Group
#Remove-SPOSite $groupSiteToDelete