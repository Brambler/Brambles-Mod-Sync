# URL of the manifest file
$manifestUrl = "https://raw.githubusercontent.com/Brambler/Brambles-Mod-Sync/main/manifest.json"

# Download the manifest file
$manifestContent = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing
$json = $manifestContent.Content | ConvertFrom-Json

# Create SyncDownloads folder if it doesn't exist
$downloadPath = Join-Path -Path $PSScriptRoot -ChildPath "SyncDownloads"
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -Path $downloadPath -ItemType Directory | Out-Null
}

# Create a temporary extraction folder
$tmpPath = Join-Path -Path $PSScriptRoot -ChildPath "TempExtract"
if (-not (Test-Path -Path $tmpPath)) {
    New-Item -Path $tmpPath -ItemType Directory | Out-Null
}

# Function to download and extract files
function downloadExtract {
    param (
        $name,
        $url
    )
    $fileName = [System.IO.Path]::GetFileName($url)
    $outputFile = Join-Path -Path $downloadPath -ChildPath $fileName
    Write-Output "Downloading $name from $url"
    Invoke-WebRequest -Uri $url -OutFile $outputFile

    # Extract the zip file
    Expand-Archive -Path $outputFile -DestinationPath $tmpPath -Force
}

# Iterate through Core components
foreach ($core in $json.Core) {
    downloadExtract -name $core.name -url $core.url
}

# Iterate through Mods components
foreach ($mod in $json.Mods) {
    downloadExtract -name $mod.name -url $mod.url
}

# Function to move extracted folders to a different location
function Move-ExtractedFolders {
    param (
        $sourcePath,
        $destinationPath
    )
    $folders = Get-ChildItem -Path $sourcePath -Directory
    foreach ($folder in $folders) {
        if ($folder.Name -eq "user" -or $folder.Name -eq "BepInEx") {
            $destFolder = Join-Path -Path $destinationPath -ChildPath $folder.Name
            Move-Item -Path $folder.FullName -Destination $destFolder -Force
        }
    }
}

# Example usage of Move-ExtractedFolders function
# $finalDestinationPath = "path\to\final\destination"
# Move-ExtractedFolders -sourcePath $tmpPath -destinationPath $finalDestinationPath