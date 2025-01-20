# Load the JSON file
$json = Get-Content -Raw -Path "path\to\manifest.json" | ConvertFrom-Json

# Function to construct the download URL
function Get-DownloadUrl {
    param (
        $baseUrl,
        $version,
        $fileName
    )
    return "$baseUrl$version/$fileName"
}

# Iterate through Core components
foreach ($core in $json.Core) {
    $downloadUrl = Get-DownloadUrl -baseUrl $core.url -version $core.version -fileName $core.'file-name'
    Write-Output "Downloading $($core.name) from $downloadUrl"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $core.'file-name'
}

# # Iterate through Mods components
# foreach ($mod in $json.Mods) {
#     $downloadUrl = Get-DownloadUrl -baseUrl $mod.url -version $mod.version -fileName $mod.'file-name'
#     Write-Output "Downloading $($mod.name) from $downloadUrl"
#     Invoke-WebRequest -Uri $downloadUrl -OutFile $mod.'file-name'
# }