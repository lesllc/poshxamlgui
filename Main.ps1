Add-Type -AssemblyName PresentationFramework

################################################################################
# define your functions here
Function Get-FixedDisk {
	[CmdletBinding()]
	param (
	<# This parameter accets the name of the target computer. This parameter is
	   mandatory.
	#>
	[Parameter(Mandatory)]
	[string]$Computer
	)

	<# WMI query to get the list of ligical disks #>
	$DiskInfo = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter 'DriveType=3'
	return $DiskInfo
}

################################################################################
# where is the XAML file?
$xamlFile = ".\MainWindow.xaml"

################################################################################
# create window and mangle the xaml
$inputXML = Get-Content $xamlFile -Raw
$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[XML]$xaml = $inputXML

################################################################################
#Read XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
	$window = [Windows.Markup.XamlReader]::Load( $reader)
} catch {
	Write-Warning $_.Exception
	throw
}

################################################################################
# Create variables based on form control names
# Variable will be named as 'var_<control name>'
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
	#"trying item $($_.Name)"
	try {
		Set-Variable -Name "var_$($_.Name)" -Value $window.FindName($_.Name) -ErrorAction Stop
	} catch {
		throw
	}
}

################################################################################
# get all of the variables…
Get-Variable var_*

################################################################################
# Add event handlers here…

$var_btnQuery.Add_Click( {
	#clear the result box
	$var_txtResults.Text = ""
	if ($result = Get-FixedDisk -Computer $var_txtComputer.Text) {
		foreach ($item in $result) {
			$var_txtResults.Text = $var_txtResults.Text + "DeviceID: $($item.DeviceID)`n"
			$var_txtResults.Text = $var_txtResults.Text + "VolumeName: $($item.VolumeName)`n"
			$var_txtResults.Text = $var_txtResults.Text + "FreeSpace: $($item.FreeSpace)`n"
			$var_txtResults.Text = $var_txtResults.Text + "Size: $($item.Size)`n`n"
		}
	} else {
		echo "womp womp"
	}
})

$var_txtComputer.Text = $env:COMPUTERNAME

# vvv this must always be the last line in the script vvv
$Null = $window.ShowDialog()
