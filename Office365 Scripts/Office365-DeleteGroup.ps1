$o365DomainName="tenant" 
$SPOAdminCenterUrl="https://"+ $o365DomainName +"-admin.sharepoint.com/"  
$credential = Get-Credential -UserName administrator@rocktree.sg -Message "Type the password."
Connect-SPOService -Url $SPOAdminCenterUrl -Credential $credential

#comment
#List all SharePoint sites
#$sites = Get-SPOSite
#Get-SPOSite  -Limit All | Format-Table –AutoSize

$s = Get-SPOSite -Identity  $site

if($s -eq $null)
{
    $s = get-SPODeletedSite | where{$_.url -eq $newFullSiteUrl}
}

#$sitesTable = @()

#Foreach ($s in $sites)
#{
#    Write-Host "Setting Ownwer for " $site
#    Set-SPOSite -Identity $s.Url -owner administrator@rocktree.sg

#    $row = New-Object System.Object 
#    $row | Add-Member -type NoteProperty -name "Site Name" -value $s.Title
#    $row | Add-Member -type NoteProperty -Name "Site URL" -Value $s.Url
#    $row | Add-Member -type NoteProperty -Name "Site Lock Status" -Value $s.LockState
#    $row | Add-Member -type NoteProperty -Name "Site Owner" -Value $s.Owner
#    $sitesTable += $row
#}

#$sitesTable | Format-Table –AutoSize

#Force unlock and set owner
Set-SPOSite -Identity $site -LockState Unlock
#Set-SPOSite -Identity $site -owner administrator@rocktree.sg


#Safe comment to avoid delete
if($s -ne $null)
{
    Remove-SPOSite $site
}