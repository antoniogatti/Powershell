Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

#
# Format a string with the specified length, fill the rest with the specified characters
#
function FormatString($StringValue, $MaxLength, $Left, $FillChar)
{
	if ($StringValue -eq $null)
	{ $StringValue = "" }
	
	if ($StringValue.Length > $MaxLength)
	{ $StringValue = $StringValue.Substring(0, $MaxLength)}
	
	if ($Left)
	{return $StringValue.PadLeft($MaxLength, $FillChar)}
	else
	{return $StringValue.PadRight($MaxLength, $FillChar)}
}

#
# Print the available list of features 
#
function PrintFeatures($FeatureNodes, $AppUrl)
{
	$i = 1
	foreach( $feature in $FeatureNodes) 
	{
		$SPfeature = Get-SPFeature -Identity $feature.GetAttribute("id") -Site $AppUrl -ErrorAction SilentlyContinue
		$featureName = FormatString -StringValue $feature.GetAttribute("id") -MaxLength 50 -Left $false -FillChar ' '
		Write-Host ([System.Convert]::ToString($i) + ") " + $featureName + " ") -NoNewline
		if ($SPfeature -eq $null)
		{
			Write-Host "Not Activated" -ForegroundColor Red
		}
		else
		{
			Write-Host "Activated" -ForegroundColor Green
		}
		
		$i = $i + 1
	}
}

#
# Activate a feature
#
function ActivateFeature($FeatureId, $AppUrl) 
{
	Write-Host ""
    Write-Host "Activating feature " -NoNewline
	Write-Host $FeatureId
	$SPfeature = Get-SPFeature -Identity $FeatureId -Site $AppUrl -ErrorAction SilentlyContinue
	if ($SPfeature -eq $null)
	{
		Enable-SPFeature -Identity $FeatureId -Url $AppUrl -ErrorVariable $err -ErrorAction SilentlyContinue
	}
	else
	{
		Write-Host ("Feature " + $FeatureId + " already activated") -ForegroundColor Yellow
	}
}

#
# Activate multiple features
#
function ActivateFeature-Multi($FeatureNodes, $AppUrl) 
{
	foreach( $Feature in $FeatureNodes) 
	{
		ActivateFeature -FeatureId $Feature.GetAttribute("id") -AppUrl $AppUrl
	}
}

#
# Deactivate a feature
#
function DeactivateFeature($FeatureId, $AppUrl) 
{
	Write-Host ""	
    Write-Host "Deactivating feature " -NoNewline
	Write-Host $FeatureId
	$SPfeature = Get-SPFeature -Identity $FeatureId -Site $AppUrl -ErrorAction SilentlyContinue
	if ($SPfeature -eq $null)
	{
		Write-Host ("Feature " + $FeatureId + " not available at this scope") -ForegroundColor Yellow
	}
	else
	{
		Disable-SPFeature -Identity $FeatureId -Url $AppUrl -Force -ErrorAction Continue
	}
}

#
# Deactivate multiple features
#
function DeactivateFeature-Multi($FeatureNodes, $AppUrl) 
{
	foreach( $Feature in $FeatureNodes) 
	{
		DeactivateFeature -FeatureId $Feature.GetAttribute("id") -AppUrl $AppUrl
	}
}

function Main($RootPath)
{
	# 1. Loading configuration file.
	write-host "1. Loading configuration file " -NoNewline
	$ConfigPath = $RootPath + "\Config.xml"
	Write-Host $ConfigPath

	[xml]$ConfigFile = Get-Content $ConfigPath -ErrorAction SilentlyContinue
	if ($ConfigFile -eq $null)
	{
		Write-Host -Fore Red "Unable to read config file"
	    Exit 1
	}

	write-host "Selected environment is:   " -NoNewline
	write-host $ConfigFile.config.environment -ForegroundColor Yellow

	$CMAUrl = $ConfigFile.config.URL
	Write-Host "Source application URL is: "-NoNewline
	Write-host $CMAUrl -ForegroundColor Yellow
	$WebApp = Get-SPWebApplication -Identity $CMAUrl -ErrorAction SilentlyContinue
	if ($WebApp -eq $null)
	{
		Write-Host "Web Application $CMAUrl not found. Aborting." -ForegroundColor Red
		Exit 1
	}

	do
	{
		Write-Host (FormatString -StringValue "" -MaxLength 79 -Left $false -FillChar '-')
		Write-Host "Select one of the available options:"
		Write-Host (FormatString -StringValue "" -MaxLength 79 -Left $false -FillChar '-')
		Write-Host "1) Activate All"
		Write-Host "2) Deactivate All"
		Write-Host "3) Activate single"
		Write-Host "4) Deactivate single"
		Write-Host "0) Exit"
		Write-Host (FormatString -StringValue "" -MaxLength 79 -Left $false -FillChar '-')
		$OpChoice = Read-Host 
		Write-Host (FormatString -StringValue "" -MaxLength 79 -Left $false -FillChar '-')

		if ($OpChoice -eq "0")
		{
			Exit 0
		}
		elseif (($OpChoice -eq "1") -or ($OpChoice -eq "2"))
		{
			$xPathExpr = "config/features/feature"
		}
		elseif (($OpChoice -eq "3") -or ($OpChoice -eq "4"))
		{
			Write-Host "Select one of the available feature:"
			Write-Host (FormatString -StringValue "" -MaxLength 79 -Left $false -FillChar '-')
			Printfeatures -FeatureNodes $ConfigFile.config.features.feature -AppUrl $CMAUrl
			Write-Host "0) Back"
			Write-Host (FormatString -StringValue "" -MaxLength 79 -Left $false -FillChar '-')
			$FeatChoice = Read-Host 
			Write-Host (FormatString -StringValue "" -MaxLength 79 -Left $false -FillChar '-')
			if ($FeatChoice -eq "0")
			{
				continue
			}
			$xPathExpr = ("config/features/feature[" + $FeatChoice + "]")
		}
		else
		{
			Write-Host "Unknown option"
			continue
		}
		
		$features = $ConfigFile.SelectNodes($xPathExpr)
		
		if (($OpChoice -eq "1") -or ($OpChoice -eq "3"))
		{
			activatefeature-multi -FeatureNodes $features -AppUrl $CMAUrl
		}
		elseif (($OpChoice -eq "2") -or ($OpChoice -eq "4"))
		{
			deactivatefeature-multi -FeatureNodes $features -AppUrl $CMAUrl		
		}
	}
	while (1)
}

main -RootPath ($myinvocation.mycommand.path | Split-Path)
