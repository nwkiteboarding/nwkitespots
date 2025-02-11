param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$DestinationPath
)

$zipPath = "$Path.zip"

Rename-Item -Path $Path -NewName $zipPath
Expand-Archive -Path $zipPath -DestinationPath "Kiting spots" -Force
Rename-Item -Path $zipPath -NewName $Path
