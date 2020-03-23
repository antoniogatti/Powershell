$o365DomainName="tenant" 
$SPOAdminCenterUrl="https://"+ $o365DomainName +"-admin.sharepoint.com/"  
$credential = Get-Credential -UserName administrator@rocktree.sg -Message "Type the password."
Connect-SPOService -Url $SPOAdminCenterUrl -Credential $credential

$makeUrl ="https://<tenantname>.sharepoint.com/sites/contosobeta" 
$sourcePath = "<FolderPath>\"; 
$topSPOFolder = "Shared Documents"; 
# install pnp powershell..? 
#Install-Module SharePointPnPPowerShellOnline 
# connect to spo online 
Connect-PnPOnline -Url $makeUrl -Credentials $cred 
$fileNames = Get-ChildItem -Path $sourcePath -Recurse ; 
foreach($aFileName in $fileNames) 
{ 
if($aFileName.GetType().Name -ne "DirectoryInfo")  
   { 
     $filepath= [System.IO.Path]::GetDirectoryName($aFileName.FullName) 
     $Urlpath= ($filepath.Replace($sourcePath, '')); 
     $foldername=$Urlpath.Replace("/","\"); 
     $fn=$topSPOFolder+"\"+$foldername; 

     $metadata = @{
            "createdate" = $aFileName.CreationTime
            "modifieddate" = $aFileName.LastWriteTime
            "owner"=  $aFileName.GetAccessControl().Owner
            
            }
     Add-PnPFile -Path $aFileName.FullName -Folder $fn -Values $metadata; 
     $fn=$null 
   } 
}  