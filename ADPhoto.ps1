<#
.SYNOPSIS
ADPhoto v0.3
Uploading photos from files to Active Directory object
Загрузка фотографий пользователей/контактов в Active Directory

.DESCRIPTION
(English traslation comming soon.)
Модуль содержит функции для загрузки фотографий пользователей/контактов из файлов формата JPG в Active Directory в атрибут thumbnailPhoto
Поставляется в виде скрипта ADPhotos.ps1
Может использоваться как скрипт для загрузки фотографий либо автоматически устанавливать себя как модуль Powershell (см. параметры командной строки). Для установки модуля вручную: смените засширение файла на .psm1 и скопируйте его в папку, указанную и переменной среды окружения PSModulePath

Общий принцип работы функций модуля:
Фотографии пользователей будут взяты из пути, указанного в параметре Path, разрешение будет уменьшено до значения, указанного в параметре ResizeTo, имена файлов будут сопоставлены с учетными записями в AD по атрибуту, указанному в параметре ADAttr и, в итоге, фото будут записаны в атрибут thumbnailPhoto
Предварительные требования:
Необходимо подготовить файлы с фотографиями пользователей - имя файла должно совпадать со значением, передаваемым в параметре ADAttr. Тип файлов: JPG

.NOTES
You can use the common parameters -Debug and -WhatIf to turn on debug output and read-only mode, respectively.

.EXAMPLE
ADPhoto.ps1 -Path "c:\usersphotos\11223344.jpg"

Команда загрузить фото из файла "c:\usersphotos\11223344.jpg" в учетную запись, со значением атрибута employeeID (значение по умолчанию) равным 11223344, предварительно уменьшив размер фотографии до 128 пикселей по большей стороне (значение по умолчанию).

.EXAMPLE
ADPhoto.ps1 -Path "c:\usersphotos\*.jpg" -ResizeTo 192 -ADAttr EmployeeNumber -Force

Команда загружает все фотограции из пути "c:\usersphotos\*.jpg" (параметр -Path), сопоставляя имя файла с учетной записью по атрибуту "EmployeeNumber" (параметр -ADAttr). Фотографии будут отмасштабированы до размера максимум 192 пикселя по большей стороне (параметр -ResizeTo) и перезаписаны, если атрибут thumbnailPhoto уже был заполнен ранее (параметр -Force).

.EXAMPLE
ADPhoto.ps1 -Install -Overwrire

Команда устанавливает скрипт как модуль Powershell (параметр -Install), при необходимости перезаписывая ранее установлену версию модуля (параметр -Overwrite)

.LINK
For fresh versions, see https://github.com/uponom/ADPhoto
#>


#region Command line parameters
param (
	# Path to file(s) for upload to AD as thumbnailPhoto
	[string]$Path = "",
	# Max size of photo (no matter by X or Y) in pixels
	[int]$ResizeTo = 128,
	# AD account attribute for matching with filename
	[string]$ADAttr = "employeeID",
	# Overwrite photo if it exists in thumbnailPhoto
	[switch]$Force, 	
	# Install script as Powershell module
	[switch]$Install,	
	# Overwrite if same module is already exists
	[switch]$Overwrite,
	# Debug output mode
	[switch]$Debug,
	# Read-only mode
	[switch]$WhatIf
)

# TO DO: AD path to search under 
#	[string]$SearchBase = ""

#endregion Command line parameters

#region Global variables
$script:ResizeToHelpMsg = "Defines max size of resized picture in any dimension. Value 0 disables resizing."
$script:ADAttrHelpMsg 	= "AD User attribute to match with file name."
$script:ForceHelpMsg 	= "Force overwrite user's photo if it exists."
#endregion Global variables

#region Install as PS module
# Installs currect script as Powershell module
#	Parameters:
#		$InstallPath - Module installation path
#		$Overwrite - Defines whether overwrite existing module or not
# 	If function called without parameters - it installs module to first path in
# 	PSModulePath enviroment variable and overwrite existing module if it present
# 	Function returns $true in case of successful installation
function Install-AsPSModule ([bool]$Overwrite=$true, [string]$InstallPath="") {
	$Result = $false
	if ($InstallPath -eq "") {
		if (($env:PSModulePath).Split(";").count -gt 0) {
			$InstallPath = ($env:PSModulePath).Split(";")[0]
		} else {
			$InstallPath = $env:PSModulePath
		}
	}
	$src = $MyInvocation.ScriptName
	$trgt = [System.IO.Path]::GetFileNameWithoutExtension($src) + ".psm1"
	$InstallPath = Join-Path $InstallPath $([System.IO.Path]::GetFileNameWithoutExtension($src))
	Write-Host "Intalling $src to $InstallPath as $trgt ..."
	if (-not (Test-Path $InstallPath)) { 
		New-Item -ItemType directory -Path $InstallPath -WhatIf:$WhatIfPreference | Out-Null
	}
	if ((-not (Test-Path $(Join-Path $InstallPath $trgt))) -or $Overwrite) {
		if ((Copy-Item $src $(Join-Path $InstallPath $trgt) -WhatIf:$WhatIfPreference -PassThru) -ne $null) {
			Write-Host "`nModule has been installed successfully"
			$Result = $true
		} else {Write-Host "Installation error"}
	} else { 
		Write-Host "Module file is already exists and Overwrite parameter is not true. Installation cancelled." 
	}
}
#endregion Install as PS module


<#
.SYNOPSIS
Bulk upload photo from files to AD accounts
.DESCRIPTION
Matching, resizing and uploading photos from defined path (wildcards are supported) to AD accounts (user or contact).
Сопоставление, ресайз и загрузка фотографий пользователей из указанного пути.
#>	
function Upload-PhotosToAD {
	param(
		[parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, 
		HelpMessage="Path to users' photo files (wildcards are supported) (Required parameter).")]
		[String]
		[ValidateNotNullOrEmpty()]
		$Path, 
		[parameter(Position=1, HelpMessage={$ResizeToHelpMsg})]
		[int]
		$ResizeTo = 128, 
		[parameter(Position=2, HelpMessage={$ADAttrHelpMsg})]
		[string]
		$ADAttr = "employeeID",
		[parameter(Position=3, HelpMessage={$ForceHelpMsg})]
		[switch]
		$Force
	)
	Write-Debug "Upload-PhotosToAD : Force switch = $($Force.IsPresent)"
	Get-ChildItem -Path $Path | Upload-ADPhoto -ResizeTo $ResizeTo -ADAttr $ADAttr -Force:$Force
}

<#
.SYNOPSIS
Upload photo from file to AD account
.DESCRIPTION
Matching, optional resizing and uploading photo from defined file into AD account
Returns ADAccount object if photo uploaded successfull. Otherwise $null
Сопоставление, ресайз и загрузка фотографии пользователя из указанного файла
#>
function Upload-ADPhoto {
	param(
		[parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, 
		HelpMessage="Path to file which contains user's photo (Required parameter)")]
		[String]
		[ValidateNotNullOrEmpty()]
		$File, 
		[parameter(Position=1, HelpMessage={$ResizeToHelpMsg})]
		[int]
		$ResizeTo = 128, 
		[parameter(Position=2, HelpMessage={$ADAttrHelpMsg})]
		[string]
		$ADAttr = "employeeID",
		[parameter(Position=3, HelpMessage={$ForceHelpMsg})]
		[switch]
		$Force,
		[parameter(Position=4, HelpMessage="Jpeg encoding quality")]
		[byte]
		$JpegQuality = 80
	)
	begin {
		Write-Debug "Upload-ADPhoto : Resize photos to: $ResizeTo pixels `tMatch filename with AD attribute: $ADAttr"
		Write-Debug "Upload-ADPhoto : Force switch: $($Force.IsPresent)"
		Write-Debug "Upload-ADPhoto : Read-only mode: $ReadOnlyMode"
		Add-Type -AssemblyName system.drawing
		Function Get-ImageEncoder ([System.Drawing.Imaging.Imageformat]$format)	{
			[System.Drawing.Imaging.ImageCodecInfo]::GetImageDecoders() | ?{$_.formatid -eq $format.guid}
		}
		$FileAccessMode = [System.IO.FileMode]::Open
	}
	process {
		Write-Debug "Upload-ADPhoto : $File"
		$ImgFileStream = New-Object System.IO.FileStream($File, $FileAccessMode)
		if ($ImgFileStream.Length -gt 0) {
			$ImgStream = New-Object System.IO.MemoryStream
			$ImgFileStream.CopyTo($ImgStream)
			$ImgFileStream.Dispose()
			if ($ResizeTo -gt 0) { # resizing
				$fullimg = New-Object System.Drawing.Bitmap($ImgStream)
				if ($fullimg.width -gt $fullimg.height) {
					[double]$ratio=$ResizeTo/$fullimg.width
				}
				else {
					[double]$ratio=$ResizeTo/$fullimg.height
				}
				[int]$newwidth = $fullimg.width * $ratio
				[int]$newheight = $fullimg.height * $ratio

				<# Short way (but poor quality) - resize at load time
				#$RImg = New-Object System.Drawing.Bitmap($fullimg, $newwidth, $newheight)
				#$RImg.Save($NewImgStream, $(Get-ImageEncoder jpeg), $myEncoderParams)
				#>
				
				$newImg = New-Object System.Drawing.Bitmap($newwidth, $newheight)
				$gr = [System.Drawing.Graphics]::FromImage($newImg)
				$gr.InterpolationMode = [System.Drawing.drawing2d.InterpolationMode]::HighQualityBicubic
				$gr.SmoothingMode = [System.Drawing.drawing2d.SmoothingMode]::HighQuality
				$gr.PixelOffsetMode = [System.Drawing.drawing2d.PixelOffsetMode]::HighQuality
				$gr.CompositingQuality = [System.Drawing.drawing2d.CompositingQuality]::HighQuality
				$gr.DrawImage($fullImg, 0, 0, $newwidth, $newheight)
				$gr.Dispose()
				$fullimg.Dispose()
				$myEncoderParams = New-Object System.Drawing.Imaging.EncoderParameters (1)
				$myEncoderParams.Param[0] = new-object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 80)
				$NewImgStream = New-Object System.IO.MemoryStream
				$newImg.save($NewImgStream,$(Get-ImageEncoder jpeg), $myEncoderParams) 
				Write-Debug "Upload-ADPhoto : Resized photo: $($NewImgStream.Length) bytes"
				$photo = $NewImgStream.ToArray()
				$NewImgStream.Dispose()
			} else { # using original file without resizing
				$photo = $ImgStream.ToArray()
			}
			$ImgStream.Dispose()
			Write-Debug "Upload-ADPhoto : Uploading $($photo.Length) bytes..."
			# uploading to AD
			$ID = [io.path]::GetFileNameWithoutExtension($File)
			$Employee = $null
			$Employee = Get-ADObject -filter {$ADAttr -eq $ID -and (objectclass -eq 'contact' -or objectclass -eq 'user')} `
							-ErrorAction SilentlyContinue -Properties thumbnailphoto |
								?{($_.objectclass -eq 'contact') -or ($_.objectclass -eq 'user')}
			if ( $Employee -ne $null ) {
				Write-Debug "Upload-ADPhoto : Account name: $($Employee.Name)"
				if ( ($Employee.thumbnailphoto -ne $null) -and (-not $Force) ) {
					Write-Debug "Upload-ADPhoto ! Skipped: thumbnailPhoto exists and no Force switch"
					return $null 
				}
				$Employee | Set-ADobject -Replace @{thumbnailphoto=$photo} -WhatIf:$WhatIfPreference
			} else { Write-Debug "Upload-ADPhoto ! $ADAttr `"$ID`' has not matches"	}
		} else { throw "Can't load file $File" }
		return $Employee
	}
	end {}
}


################################################################################

if ($Debug) {$DebugPreference = "Continue"}
if ($WhatIf) {$WhatIfPreference = $true}

if ($Install.IsPresent) {
	Install-AsPSModule $($Overwrite.IsPresent)
} elseif ($Path -eq "") {
	throw "Required parameter does not exist"
} else {
	if (Test-Path $Path) {
		$ReadOnlyMode = $WhatIf.IsPresent
		if ($Force.IsPresent) {Write-Debug '"Force" switch exists. Exitsting photos will be overwrited'}
		Upload-PhotosToAD -Path $Path -ResizeTo $ResizeTo -ADAttr $ADAttr -Force: $($Force.IsPresent)
	} else {
		Write-Error "Path does not exists"
	}
}
