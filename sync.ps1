# URL of the manifest file
$manifestUrl = "https://raw.githubusercontent.com/Brambler/Brambles-Mod-Sync/main/manifest.json"

# Download the manifest file
$manifestContent = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing
$json = $manifestContent.Content | ConvertFrom-Json

# Function to construct the download URL
function Get-DownloadUrl {
    param (
        $baseUrl,
        $version,
        $fileName
    )
    return "$baseUrl$version/$fileName"
}

# Create SyncDownloads folder if it doesn't exist
$downloadPath = Join-Path -Path $PSScriptRoot -ChildPath "SyncDownloads"
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -Path $downloadPath -ItemType Directory | Out-Null
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