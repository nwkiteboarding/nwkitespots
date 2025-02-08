$kmlPath  = "c:\Code\Kiteboarding\Kiting spots.kml"

$kmlContent = Get-Content -Path $kmlPath
[xml]$kml = $kmlContent

$updateFailed = $false

foreach ($placemark in $kml.kml.Document.Placemark) {

    Write-Host $placemark.name

    if (!$placemark.description.HasChildNodes) {
        continue
    }

    if ($null -eq $placemark.Point.coordinates) {
        continue
    }

    try {
        $coordinates = $placemark.Point.coordinates.Split(",")
        if ($coordinates.Length -lt 2) {
            continue;
        }
    
        $lon = [double]$coordinates[0]
        $lat = [double]$coordinates[1]
    
        $windyHref = "https://www.windy.com/$lat/$lon/wind?$lat,$lon"
    
        Write-Host "Windy: $windyHref"
    
        $windyLink = "<a href=""$windyHref"">Windy</a><br>"
        $descriptionText = $placemark.description.FirstChild

        if ($descriptionText.NodeType -ne "CDATA") {
            continue;
        }
        $descriptionText.Value = $windyLink + $descriptionText.Value
        }
    catch {
        $updateFailed = $true
        Write-Error $_.Exception
        break
    }
}

if (!$updateFailed) {
    $kml.Save($kmlPath)
}