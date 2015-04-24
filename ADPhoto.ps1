<#
.SYNOPSIS


.EXAMPLE




if ($Install.IsPresent) {
	Install-AsPSModule $($Overwrite.IsPresent)
} elseif ($Path -eq "") {
} else {
	if (Test-Path $Path) {
		$ReadOnlyMode = $WhatIf.IsPresent
		if ($Force.IsPresent) {Write-Debug '"Force" switch exists. Exitsting photos will be overwrited'}
	} else {
	}
}

