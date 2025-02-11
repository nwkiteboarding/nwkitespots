param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$DestinationPath    
)

$encoding = [System.Text.Encoding]::GetEncoding("UTF-8")
$content = [System.IO.File]::ReadAllText($Path, $encoding)
$xmlDocument = New-Object System.Xml.XmlDocument
$xmlDocument.LoadXml($content)

$updateFailed = $false

# this function preserves the original Unix(LF)/UTF-8 encoding
# by default on Windows the encoding is changed to Windows(CRLF)/UTF-8 BOM which breaks the google map
function Save-UnixXml {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0)]
        [xml]$xml,

        [Parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 1)]
        [Alias('FilePath')]
        [string]$Path
    )
    try {
        $settings = [System.Xml.XmlWriterSettings]::new()
        $settings.Indent       = $true                                     # defaults to $false
        $settings.NewLineChars = "`n"                                      # defaults to "`r`n"
        $settings.Encoding     = [System.Text.UTF8Encoding]::new($false)   # $false means No BOM

        $xmlWriter = [System.Xml.XmlWriter]::Create($Path, $settings)

        $xml.WriteTo($xmlWriter)
        $xmlWriter.Flush()
    }
    finally {
        # cleanup
        if ($xmlWriter) { $xmlWriter.Dispose() }
    }
}

$namespace = New-Object System.Xml.XmlNamespaceManager($xmlDocument.NameTable)
$namespace.AddNamespace("kml", "http://www.opengis.net/kml/2.2")
$placemarks = $xmlDocument.SelectNodes("//kml:Placemark", $namespace)

# walk through all placemarks and update the description
foreach ($placemark in $placemarks) {

    $nameNode = $placemark.SelectSingleNode("./kml:name", $namespace);
    Write-Host $nameNode.InnerText

    $coordinatesNode = $placemark.SelectSingleNode("./kml:Point/kml:coordinates", $namespace);
    if ($null -eq $coordinatesNode) {
        continue;
    }

    $descriptionNode = $placemark.SelectSingleNode("./kml:description", $namespace);
    if ($null -eq $descriptionNode -or !$descriptionNode.HasChildNodes) {
        continue
    }

    $descriptionContent = $descriptionNode.FirstChild

    try {
        $coordinates = $coordinatesNode.InnerText.Split(",")
        if ($coordinates.Length -lt 2) {
            continue;
        }
    
        $lon = [double]$coordinates[0]
        $lat = [double]$coordinates[1]
    
        $windyLink = "https://www.windy.com/$lat/$lon/wind?$lat,$lon"
    
        Write-Host "Windy: $windyLink"

        $descriptionNode.InnerText = "$windyLink<br><br>" + $descriptionContent.InnerText

        #update style
        $styleUrlNode = $placemark.SelectSingleNode("./kml:styleUrl", $namespace);
        if ($null -ne $styleUrlNode -and $styleUrlNode.InnerText -eq "#icon-ci-1") {
            $styleUrlNode.InnerText = "#icon-22"
        }
    }
    catch {
        $updateFailed = $true
        Write-Error $_.Exception
        break
    }
}

if (!$updateFailed) {
    Save-UnixXml $xmlDocument -Path $DestinationPath
}