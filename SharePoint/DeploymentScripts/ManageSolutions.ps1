Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

#
# Wait the specified solutions to terminate the deploy process. Deploy or Retract depending on the $deploying parameter
#
function WaitDeployProcess($solutions, $deploying)
{
	$errorOccurred = $false
	Write-Host "Waiting operation to end" -NoNewline
	do
	{
		$Installed = $true
		foreach( $solution in $solutions) 
		{
			$SPsolution = Get-SPSolution -Identity $solution.GetAttribute("id") -ErrorAction SilentlyContinue 

			if ($SPsolution -eq $null)
			{ continue }
			
			if ($SPsolution.JobExists) 
			{ $Installed = $false }
		} 
		if ($Installed) { break }
		sleep -Seconds 5
		Write-Host "." -NoNewline
	}
	while($Installed -eq $false)
	
	# CHECK DEPLOY RESULT
	$errorOccurred = $false
	foreach( $solution in $solutions) 
	{
		$SPsolution = Get-SPSolution -Identity $solution.GetAttribute("id") -ErrorAction SilentlyContinue 

		if ($SPsolution -eq $null)
		{ continue }
		
		if (($deploying -and !$SPsolution.Deployed) -or (!$deploying -and $SPsolution.Deployed))
		{ $errorOccurred =$true }
	} 
	Write-Host ""
	if ($errorOccurred)
		{Write-Host "An error occurred during the solution deployment." -ForegroundColor Red}
	else
		{Write-Host "Finished"}
}

#
# Add a solution to the solution store in the farm
#
function AddSolution($SolutionId, $SolutionPath) 
{
    Write-Host "Adding solution " -NoNewline
	Write-Host $SolutionId
	$SPsolution = Get-SPSolution -Identity $SolutionId -ErrorAction SilentlyContinue
	if ($SPsolution -eq $null)
	{
		Add-SPSolution $SolutionPath -ErrorAction Continue
	}
	else
	{
		Write-Host ("Solution " + $SolutionId + " already added") -ForegroundColor Yellow
	}
}

#
# Add some solutions to the solution store in the farm
#
function AddSolution-Multi($SolutionNodes, $RootPath) 
{
	foreach( $solution in $SolutionNodes) 
	{
		AddSolution -SolutionId $solution.GetAttribute("id") -SolutionPath ($RootPath + $solution.GetAttribute("id"))
	}
}

#
# Install a solution from the solution store in the farm
#
function InstallSolution($SolutionId, $GacDeploy, $WebDeploy, $WebApp)
{
	Write-Host "Installing solution " -NoNewline
	Write-Host $SolutionId
	$SPsolution = Get-SPSolution -Identity $SolutionId -ErrorAction SilentlyContinue 
	if ($SPsolution -eq $null)
	{
		Write-Host ("Solution " + $SolutionId + " not present") -ForegroundColor Yellow
	}
	elseif ($SPsolution.Deployed)
	{
		Write-Host ("Solution " + $SolutionId + " already installed") -ForegroundColor Yellow
	}
	elseif ($WebDeploy -eq $true)
	{
		Install-SPSolution -Identity $SolutionId -GACDeployment:$GacDeploy -CASPolicies:$($SPsolution.ContainsCasPolicy) -WebApplication $WebApp -Confirm:$false
	}
	else
	{
		Install-SPSolution -Identity $SolutionId -GACDeployment:$GacDeploy -CASPolicies:$($SPsolution.ContainsCasPolicy) -Confirm:$false -force
    } 
}

#
# Install some solutions from the solution store in the farm and wait the end of the process
#
function InstallSolution-Multi($SolutionNodes, $RootPath, $WebApp )
{
	foreach( $solution in $SolutionNodes) 
	{
		[bool] $GacDeploy = [System.Convert]::ToBoolean($solution.GetAttribute("GACdeploy"))
		[bool] $WebDeploy = [System.Convert]::ToBoolean($solution.GetAttribute("webapp"))
		
		InstallSolution -SolutionId $solution.GetAttribute("id") -GacDeploy $GacDeploy -WebDeploy $WebDeploy -WebApp $WebApp 
	}
	
	WaitDeployProcess -solutions $SolutionNodes -deploying $true
	
}

#
# Remove a solution from the solution store in the farm
#
function RemoveSolution($SolutionId) 
{
    Write-Host "Removing solution " -NoNewline
	Write-Host $SolutionId
	$SPsolution = Get-SPSolution -Identity $SolutionId -ErrorAction SilentlyContinue
	if ($SPsolution -eq $null)
	{
		Write-Host ("Solution " + $SolutionId + " not present") -ForegroundColor Yellow
	}
	else
	{
    	Remove-SPSolution -Identity $SolutionId -ErrorAction Continue
	}
}

#
# Remove some solutions from the solution store in the farm
#
function RemoveSolution-Multi($SolutionNodes) 
{
	foreach($solution in $SolutionNodes) 
	{
		RemoveSolution -SolutionId $solution.GetAttribute("id")
	}
}

#
# Uninstall a solution from the solution store in the farm
#
function UninstallSolution($SolutionId)
{
	Write-Host "Uninstalling solution " -NoNewline
	Write-Host $SolutionId
	$SPsolution = Get-SPSolution -Identity $SolutionId -ErrorAction SilentlyContinue 
	if ($SPsolution -eq $null)
	{
		Write-Host ("Solution " + $SolutionId + " not present") -ForegroundColor Yellow
	}
	elseif (!$SPsolution.Deployed)
	{
		Write-Host ("Solution " + $SolutionId + " not installed") -ForegroundColor Yellow
	}
	elseif ($SPsolution.ContainsWebApplicationResource)
	{
		Uninstall-SPSolution -Identity $SolutionId -AllWebApplications -Confirm:$false
	}
	else
	{
		Uninstall-SPSolution -Identity $SolutionId -Confirm:$false
	}
}

#
# Uninstall some solution from the solution store in the farm and wait the end of the process
#
function UninstallSolution-Multi($SolutionNodes)
{
	foreach( $solution in $SolutionNodes) 
	{
		UninstallSolution -SolutionId $solution.GetAttribute("id")
	}
	
	WaitDeployProcess -solutions $SolutionNodes -deploying $false 
}

#
# Update a solution in the solution store in the farm
#
function UpdateSolution($SolutionId, $SolutionPath) 
{
    Write-Host "Updating solution " -NoNewline
	Write-Host $SolutionId
	$SPsolution = Get-SPSolution -Identity $SolutionId -ErrorAction SilentlyContinue
	if ($SPsolution -eq $null)
	{
		Write-Host ("Solution " + $SolutionId + " not present") -ForegroundColor Yellow
	}
	else
	{
		Update-SPSolution –Identity $SolutionId -LiteralPath $SolutionPath -CASPolicies:$($SPsolution.ContainsCasPolicy) -GACDeployment:$($SPsolution.ContainsGlobalAssembly) -ErrorAction Continue
	}
}

#
# Update some solution in the solution store in the farm and wait the end of the process
#
function UpdateSolution-Multi($SolutionNodes, $RootPath) 
{
	foreach( $solution in $SolutionNodes) 
	{
		UpdateSolution -SolutionId $solution.GetAttribute("id") -SolutionPath ($RootPath + $solution.GetAttribute("id"))
	}
	WaitDeployProcess -solutions $SolutionNodes -deploying $true 
}

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
# Print the list of the solutions taken from the xml nodes
#
function PrintSolutions($SolutionNodes)
{
	$i = 1
	foreach( $solution in $SolutionNodes) 
	{
		$SPsolution = Get-SPSolution -Identity $solution.GetAttribute("id") -ErrorAction SilentlyContinue 
		
		$index = ([System.Convert]::ToString($i))
		$solutionName = FormatString -StringValue $solution.GetAttribute("id") -MaxLength 40 -Left $false -FillChar ' '
		
		Write-Host ($index + ") " + $solutionName + " ") -NoNewline
		if ($SPsolution -eq $null)
		{
			Write-Host "Not Existing" -ForegroundColor Red
		}
		elseif ($SPsolution.Deployed)
		{
			Write-Host $SPsolution.DeploymentState -ForegroundColor Green
		}
		else
		{
			Write-Host $SPsolution.DeploymentState -ForegroundColor Yellow
		}
					
		$i = $i + 1
	}
}

#
# Collect built files from solution
#
function CollectFiles($SolutionNodes, $srcPath, $destFolder, $ext, $reldbg)
{
	foreach( $solution in $SolutionNodes) 
	{
		$SolutionId = $solution.GetAttribute("id")
		$SolWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($SolutionId)

		if ( -not (Test-Path $destFolder) ) {New-Item $destFolder  -Type Directory  | Out-Null}
		if ( -not (Test-Path ($destFolder + $reldbg )) ) {New-Item ($destFolder + $reldbg) -Type Directory  | Out-Null}

		$destFile = $destFolder + $reldbg + "\" + $SolWithoutExt + "." + $ext
		$srcFile = $srcPath + "\" + $SolWithoutExt + "\bin\" + $reldbg + "\" + $SolWithoutExt + "." + $ext
		
		Write-Host "Copying $SolutionId"
		Copy-Item -LiteralPath $srcFile -Destination  $destFile -Force -ErrorAction Continue 
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

	write-host "Selected environment  : " -NoNewline
	write-host $ConfigFile.config.environment -ForegroundColor Yellow

	$CMAUrl = $ConfigFile.config.URL
	$ConfName = $ConfigFile.config.configuration
	
	Write-Host "Source application URL: "-NoNewline
	Write-host $CMAUrl -ForegroundColor Yellow
	Write-Host "Current Configuration : "-NoNewline
	Write-host $ConfName -ForegroundColor Yellow
	
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
		Write-Host "1) Collect WSPs"
		Write-Host "2) Collect DLLs"
		Write-Host "3) Install All"
		Write-Host "4) Uninstall All"
		Write-Host "5) Update All"
		Write-Host "6) Install single"
		Write-Host "7) Uninstall single"
		Write-Host "8) Update single"
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
			$xPathExpr = "config/solutions/solution"
		}
		elseif (($OpChoice -eq "3") -or ($OpChoice -eq "4") -or ($OpChoice -eq "5"))
		{
			$xPathExpr = "config/solutions/solution[@toDeploy='true']"
		}
		elseif (($OpChoice -eq "6") -or ($OpChoice -eq "7") -or ($OpChoice -eq "8"))
		{
			$xPathExpr = "config/solutions/solution[@toDeploy='true']"
			$solutions = $ConfigFile.SelectNodes($xPathExpr)
			
			Write-Host "Select one of the available solutions:"
			Write-Host (FormatString -StringValue "" -MaxLength 79 -Left $false -FillChar '-')
			PrintSolutions -SolutionNodes $solutions
			Write-Host "0) Back"
			Write-Host (FormatString -StringValue "" -MaxLength 79 -Left $false -FillChar '-')
			$SolChoice = Read-Host 
			Write-Host (FormatString -StringValue "" -MaxLength 79 -Left $false -FillChar '-')
			if ($SolChoice -eq "0")
			{
				continue
			}
			$solution = $solutions.Item($SolChoice-1)
			$xPathExpr = ("config/solutions/solution[@id='" + $solution.GetAttribute("id") + "']")
		}
		else
		{
			Write-Host "Unknown option"
			continue
		}
		
		$solutions = $ConfigFile.SelectNodes($xPathExpr)
		$WspPath = $RootPath + $ConfigFile.config.wsp_path 
		$DllPath = $RootPath + $ConfigFile.config.dll_path
		
		$WspPathConf = $WspPath + $ConfName + "\"
		
		if ($OpChoice -eq "1")
		{
			CollectFiles -destFolder $WspPath -reldbg $ConfName -ext "wsp" -SolutionNodes $solutions -srcPath $ConfigFile.config.solution_path.InnerText
		}
		elseif ($OpChoice -eq "2")
		{
			CollectFiles -destFolder $DllPath -reldbg $ConfName -ext "dll" -SolutionNodes $solutions -srcPath $ConfigFile.config.solution_path.InnerText
		}
		elseif (($OpChoice -eq "3") -or ($OpChoice -eq "6"))
		{
			addsolution-multi -SolutionNodes $solutions -RootPath $WspPathConf
			InstallSolution-Multi -SolutionNodes $solutions -RootPath $WspPathConf -WebApp $WebApp
		}
		elseif (($OpChoice -eq "4") -or ($OpChoice -eq "7"))
		{
			uninstallsolution-multi -SolutionNodes $solutions 
			removesolution-multi -SolutionNodes $solutions
		}
		elseif (($OpChoice -eq "5") -or ($OpChoice -eq "8"))
		{
			UpdateSolution-Multi -SolutionNodes $solutions -RootPath $WspPathConf 
		}
	}
	while (1)
}

main -RootPath ($myinvocation.mycommand.path | Split-Path)


