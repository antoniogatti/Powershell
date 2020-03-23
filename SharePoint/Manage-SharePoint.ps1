Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking


$o365DomainName="tenant" 
$SPOAdminCenterUrl="https://"+ $o365DomainName +"-admin.sharepoint.com/"  
$credential = Get-Credential -UserName administrator@rocktree.sg -Message "Type the password."
Connect-SPOService -Url $SPOAdminCenterUrl -Credential $credential

$SecurePassword = Read-Host "Enter Admin Password" -AsSecureString #$Password | ConvertTo-SecureString -AsPlainText -Force #Read-Host "Enter Admin Password" -AsSecureString

#$SPOCredentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)


function ConnectToSharePoint()
{
param(
   $Url = $(throw "Please provide a Site Collection Url"),
   $credential = $(throw "Please provide a Credentials")
)
	Try{
		Connect-SPOService -Url $AdminUrl -Credential $Credentials
		return $true;
	}Catch{
		 Write-Host "Error. Cannot Connect-SPOService because $_"
		 return $false;
	}
}


function ListAllSiteCollections(){

	#Retrieve all site collection infos
	
	$sites = Get-SPOSite 

	#Retrieve and print all sites
	foreach ($site in $sites)
	{
	   Write-Host 'Site collection:' $site.Url     
	   
	} 
}

function CreateNewSiteCollection(){
param(
   #$Url = $(throw "Please provide a Site Collection Url"),
   $NewSiteName = $(throw "Please provide a Site name")
)

	$prefix = "sites/"
    #$newSite = "SP" + $g.Name 
    $siteTitle = "test" 


    $owner = $UserName
    $storageQuota = 100000
    $resourceQuota = 50
    $template = "STS#0"
    $newFullSiteUrl = $rootSite + $prefix + $NewSiteName

	

    #verify if site already exists in SharePoint Online
    $siteExists = get-SPOSite | where{$_.url -eq $newFullSiteUrl}
 
    #verify if site already exists in the recycle bin
    $siteExistsInRecycleBin = get-SPODeletedSite | where{$_.url -eq $newFullSiteUrl}

    #create site if it doesn't exists
    if (($siteExists -eq $null) -and ($siteExistsInRecycleBin -eq $null)) {

        write-host "Creating " $newFullSiteUrl -foregroundcolor green
        New-SPOSite -Url $newFullSiteUrl -title $siteTitle -Owner $owner -StorageQuota $storageQuota -ResourceQuota $resourceQuota -Template $template

    }
    else
    {
        write-host "The site $($newFullSiteUrl) already exists" -foregroundcolor red
    }
	
	

}

function RemoveSiteCollection(){
param(
   #$Url = $(throw "Please provide a Site Collection Url"),
   $SiteName = $(throw "Please provide a Site name")
)

	$prefix = "sites/"
    #$newSite = "SP" + $g.Name 
    $siteTitle = "test" 


    $owner = $UserName
    $storageQuota = 100000
    $resourceQuota = 50
    $template = "STS#0"
    $fullSiteUrl = $rootSite + $prefix + $SiteName

	

    #verify if site already exists in SharePoint Online
    $siteExists = get-SPOSite | where{$_.url -eq $fullSiteUrl}
 
    #verify if site already exists in the recycle bin
    $siteExistsInRecycleBin = get-SPODeletedSite | where{$_.url -eq $fullSiteUrl}

    #create site if it doesn't exists
    if (!($siteExists -eq $null) -or !($siteExistsInRecycleBin -eq $null)) {

        write-host "Removing " $fullSiteUrl -foregroundcolor green
		Remove-SPOSite -Identity $fullSiteUrl -NoWait
       
    }
    else
    {
        write-host "The site $($fullSiteUrl) does not exists" -foregroundcolor red
    }
	
}

function EmptyRecyleBin(){
	$selection = Read-Host "Are you sure you want to empty recycle bin? (Y) Yes / (N) No"

	Switch ($selection){
		Y{
			$DeletedSiteCollURLs = Get-SPODeletedSite | Select URL

			foreach($url in $DeletedSiteCollURLs){
				Write-Host "Deleting "$url.Url" ..."
				Remove-SPODeletedSite -Identity $url.Url -Confirm:$False
			}
		}
	}
}

function Main(){
	Do {
		clear
		Write-Host "1. List All Site Collections"
		Write-Host "2. Create a new Site Collection"
		Write-Host "3. Delete a Site Collection"
		Write-Host "4. Empty Recycle Bin"
		Write-Host "0. Exit"
		$selection = Read-Host "Select your option "

		Switch ($selection) 
		 { 
		   1 
			{
				ListAllSiteCollections
			} 
		   2
			{
				$siteName = Read-Host 'Enter Site Name '
				CreateNewSiteCollection -newSite $siteName 
			  
			}
		   3	
			{		
				 $siteName = Read-Host 'Enter Site Name '
				RemoveSiteCollection -SiteName $siteName 
			}
			4
			{		
				EmptyRecyleBin
			}
		 } 
		 
		if($selection -ne "0"){
		Write-Host -NoNewLine 'Press any key to continue...';
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
		}

	} # End of 'Do'
	Until ($selection -eq "0")
}


if(ConnectToSharePoint -Url $AdminUrl -Credential $SPOCredentials){
	Main
}
else{
	Write-Host -NoNewLine 'Unable to connect to $AdminUrl ...';
}





