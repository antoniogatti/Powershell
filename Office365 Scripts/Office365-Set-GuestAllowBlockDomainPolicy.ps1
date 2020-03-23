# .SYNOPSIS
#   Helps admin to update the AzureADPolicy for Allow/Block domain list for inviting external Users.
#   Powershell must be connected to Azure AD Preview V2 before running this script.
#
#   Copyright (c) Microsoft Corporation. All rights reserved.
#
#   THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
#   OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#
# .PARAMETER Update
#    Parameter to update allow or block domain list.
#
# .PARAMETER Append
#    Parameter to append domains to an existing allow or block domain list.
#
# .PARAMETER AllowList
#    Parameter to specify list of allowed domains.
#
# .PARAMETER BlockList
#    Parameter to specify list of blocked domains.
#
# .PARAMETER MigrateFromSharepoint
#    Switch parameter to migrate AllowBlockDomainList from SPO.
#
# .PARAMETER Remove
#    Switch parameter to delete the existing policy.
#
# .PARAMETER QueryPolicy
#    Switch parameter to query the existing policy.
#
# .Example
#	Set-GuestAllowBlockDomainPolicy.ps1 -Update -AllowList @("contoso.com", "fabrikam.com")
#
# .Example
#	Set-GuestAllowBlockDomainPolicy.ps1 -Append -AllowList @("contoso.com")
#
# .Example
#	Set-GuestAllowBlockDomainPolicy.ps1 -Update -BlockList @("fabrikam.com", "contoso.com")
#
# .Example
#	Set-GuestAllowBlockDomainPolicy.ps1 -Append -BlockList @("fabrikam.com")
#
# .Example
#	Set-GuestAllowBlockDomainPolicy.ps1 -MigrateFromSharepoint
#
# .Example
#	Set-GuestAllowBlockDomainPolicy.ps1 -Remove
#
# .Example
#	Set-GuestAllowBlockDomainPolicy.ps1 -QueryPolicy
#
Param(
        [Parameter(Mandatory=$true, ParameterSetName="Update+BlockList")]
        [Parameter(Mandatory=$true, ParameterSetName="Update+AllowList")]
        [Switch] $Update,
        [Parameter(Mandatory=$true, ParameterSetName="Append+BlockList")]
        [Parameter(Mandatory=$true, ParameterSetName="Append+AllowList")]
        [Switch] $Append,
        [Parameter(Mandatory=$true, ParameterSetName="Append+BlockList")]
        [Parameter(Mandatory=$true, ParameterSetName="Update+BlockList")]
        [String[]] $BlockList,
        [Parameter(Mandatory=$true, ParameterSetName="Append+AllowList")]
        [Parameter(Mandatory=$true, ParameterSetName="Update+AllowList")]
        [String[]] $AllowList,
        [Parameter(Mandatory=$true, ParameterSetName="MigrateFromSPOSet")]
        [switch] $MigrateFromSharepoint,
        [Parameter(Mandatory=$true, ParameterSetName="ClearPolicySet")]
        [switch] $Remove,
        [Parameter(Mandatory=$true, ParameterSetName="ExistingPolicySet")]
        [switch] $QueryPolicy
)

# Gets Json for the policy with given Allowed and Blocked Domain List
function GetJSONForAllowBlockDomainPolicy([string[]] $AllowDomains = @(), [string[]] $BlockedDomains = @())
{
    # Remove any duplicate domains from Allowed or Blocked domains specified.
    $AllowDomains = $AllowDomains | select -uniq
    $BlockedDomains = $BlockedDomains | select -uniq

    return @{B2BManagementPolicy=@{InvitationsAllowedAndBlockedDomainsPolicy=@{AllowedDomains=@($AllowDomains); BlockedDomains=@($BlockedDomains)}}} | ConvertTo-Json -Depth 3 -Compress
}

# Converts Json to Object since ConvertFrom-Json does not support the depth parameter.
function GetObjectFromJson([string] $JsonString)
{
    ConvertFrom-Json -InputObject $JsonString |
        ForEach-Object {
            foreach ($property in ($_ | Get-Member -MemberType NoteProperty)) 
                {
                    $_.$($property.Name) | Add-Member -MemberType NoteProperty -Name 'Name' -Value $property.Name -PassThru
                }
        }
}

# Gets AllowBlockedList from SPO
function GetSPOPolicy
{
    try
    {
        $SPOTenantSettings = Get-SPOTenant
    }
    catch [System.InvalidOperationException]
    {
        Write-Error "You must call Connect-SPOService cmdlet before using this parameter."
        Exit;
    }

    # Return JSON for Allow\Block domain list in SPO
    switch($SPOTenantSettings.SharingDomainRestrictionMode)
    {
        "AllowList"
        {
            Write-Host "`nSPO Allowed DomainList:" $SPOTenantSettings.SharingAllowedDomainList
            $AllowDomainsList = $SPOTenantSettings.SharingAllowedDomainList.Split(' ')
            return  GetJSONForAllowBlockDomainPolicy -AllowDomains $AllowDomainsList
            break;
        }
        "BlockList"
        {
            Write-Host "`nSPO Blocked DomainList:" $SPOTenantSettings.SharingBlockedDomainList
            $BlockDomainsList = $SPOTenantSettings.SharingBlockedDomainList.Split(' ')
            return GetJSONForAllowBlockDomainPolicy -BlockedDomains $BlockDomainsList
            break;
        }
        "None"
        {
            Write-Error "There is no AllowBlockDomainList policy set for this SPO tenant."
            return $null
        }
    }
}

# Gets the existing AzureAD policy for AllowBlockedList if it exists
function GetExistingPolicy
{
    $currentpolicy = Get-AzureADPolicy | ?{$_.Type -eq 'B2BManagementPolicy'} | select -First 1

    return $currentpolicy;
}

# Print Allowed and Blocked Domain List for the given policy
function PrintAllowBlockedList([String] $defString)
{
    $policyObj = GetObjectFromJson $defString;

    Write-Host "AllowedDomains: " $policyObj.InvitationsAllowedAndBlockedDomainsPolicy.AllowedDomains
    Write-Host "BlockedDomains: " $policyObj.InvitationsAllowedAndBlockedDomainsPolicy.BlockedDomains
}

# Gets AllowDomainList from the existing policy
function GetExistingAllowedDomainList()
{
    $policy = GetExistingPolicy

    if($policy -ne $null)
    {
        $policyObject = GetObjectFromJson $policy.Definition[0];

        if($policyObject.InvitationsAllowedAndBlockedDomainsPolicy -ne $null -and $policyObject.InvitationsAllowedAndBlockedDomainsPolicy.AllowedDomains -ne $null)
        {
            Write-Host "Existing Allowed Domain List: " $policyObject.InvitationsAllowedAndBlockedDomainsPolicy.AllowedDomains
            return $policyObject.InvitationsAllowedAndBlockedDomainsPolicy.AllowedDomains;
        }
    }

    return $null
}

# Gets BlockDomainList from the existing policy
function GetExistingBlockedDomainList()
{
    $policy = GetExistingPolicy

    if($policy -ne $null)
    {
        $policyObject = GetObjectFromJson $policy.Definition[0];

        if($policyObject.InvitationsAllowedAndBlockedDomainsPolicy -ne $null -and $policyObject.InvitationsAllowedAndBlockedDomainsPolicy.BlockedDomains -ne $null)
        {
            Write-Host "Existing Blocked Domain List: " $policyObject.InvitationsAllowedAndBlockedDomainsPolicy.BlockedDomains
            return $policyObject.InvitationsAllowedAndBlockedDomainsPolicy.BlockedDomains;
        }
    }

    return $null
}

# Main Script which sets the Allow/Block domain list policy according to the parameters specified by the user.
try
{
    $currentpolicy = GetExistingPolicy;
}
catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException]
{
    Write-Error "You must call Connect-AzureAD cmdlet before running this script."
    Exit
}

$policyExist = ($currentpolicy -ne $null)

switch ($PSCmdlet.ParameterSetName)
{
    "Update+BlockList"
    {
        Write-Host "Setting BlockDomainsList for B2BManagementPolicy";
        $policyValue = GetJSONForAllowBlockDomainPolicy -BlockedDomains $BlockList

        break;
    }
    "Update+AllowList"
    {
        Write-Host "Setting AllowedDomainList for B2BManagementPolicy";
        $policyValue = GetJSONForAllowBlockDomainPolicy -AllowDomains $AllowList

        break;
    }
    "Append+BlockList"
    {
        $ExistingBlockList = GetExistingBlockedDomainList

        if($ExistingBlockList -ne $null)
        {
            Write-Host "Appending Block Domain List to the current BlockDomainPolicy."
            $BlockList = $BlockList + $ExistingBlockList
        }
        else
        {
            Write-Host "Existing Block List is empty. Adding the domain list specified."
        }

        $policyValue = GetJSONForAllowBlockDomainPolicy -BlockedDomains $BlockList

        break;
    }
    "Append+AllowList"
    {
        $ExistingAllowList = GetExistingAllowedDomainList

        if($ExistingAllowList -ne $null)
        {
            Write-Host "Appending Allow Domain List to the current AllowDomainPolicy."
            $AllowList = $AllowList + $ExistingAllowList
            Write-Host $AllowList
        }
        else
        {
            Write-Host "Existing Allow List is empty. Adding the domain list specified."
        }

        $policyValue = GetJSONForAllowBlockDomainPolicy -AllowDomains $AllowList

        break;
    }
    "MigrateFromSPOSet"
    {
        $policyValue = GetSPOPolicy

        break;
    }
    "ClearPolicySet"
    {
        if($policyExist -eq $true)
        {
            Write-Host "Removing AzureAd Policy.";
            Remove-AzureADPolicy -Id $currentpolicy.Id | Out-Null
        }
        else
        {
            Write-Host "No policy to Remove."
        }

        Exit
    }
    "ExistingPolicySet"
    {
        if($currentpolicy -ne $null)
        {
            Write-Information "`nCurrent Allow/Block domain list policy:`n"
            PrintAllowBlockedList $currentpolicy.Definition[0];
        }
        else
        {
            Write-Host "No policy found for Allow/Block domain list in AzureAD."
        }

        Exit
    }
    "None"
    {
        Write-Error "`n`tPlease specify valid Parameters!`n`tExecute 'help GuestAllowBlockDomainPolicy.ps1 -examples' for examples."
        Exit
    }
}

if($policyExist -and $policyValue -ne $null)
{
    Write-Host "There is already an existing Policy for Allow/Block domain list."
    Write-Output "`nDetails for the Existing Policy in Azure AD: "
    PrintAllowBlockedList $currentpolicy.Definition[0];

    Write-Host "`nNew Policy Changes:"
    PrintAllowBlockedList $policyValue;

    $title = "Policy Change";
    $message = "Do you want to continue changing existing policy?";
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "Y"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "N"

    [System.Management.Automation.Host.ChoiceDescription[]]$options = $no,$yes;
    $confirmation = $host.ui.PromptForChoice($title, $message, $options, 0);

    if ($confirmation -eq 0)
    {
        Exit
    }
    else
    {
        Write-Host "Executing User command."
    }

    Set-AzureADPolicy -Definition $policyValue -Id $currentpolicy.Id | Out-Null
}
else
{
    New-AzureADPolicy -Definition $policyValue -DisplayName B2BManagementPolicy -Type B2BManagementPolicy -IsOrganizationDefault $true -InformationAction Ignore | Out-Null
}

Write-Output "`nNew AzureAD Policy: "
$currentPolicy = GetExistingPolicy;
PrintAllowBlockedList $currentpolicy.Definition[0];

Exit