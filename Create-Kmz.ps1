param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$DestinationPath
)

$zipPath = "$DestinationPath.zip"
Compress-Archive -Path "$Path\*" -DestinationPath $zipPath -Force
if (Test-Path -Path $DestinationPath) {
    Remove-Item -Path $DestinationPath -Force
}
Rename-Item -Path $zipPath -NewName $DestinationPath -Force
