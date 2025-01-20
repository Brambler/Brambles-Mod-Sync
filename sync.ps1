# Function to prompt the user to choose a folder
function Get-FolderPath {
    Add-Type -AssemblyName System.Windows.Forms
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select the folder for installation"
    $folderBrowser.ShowNewFolderButton = $true

    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    } else {
        throw "Folder selection was canceled."
    }
}

# Prompt the user to choose the folder location
try {
    $sptInstallationPath = Get-FolderPath
    Write-Output "Selected installation path: $sptInstallationPath"
} catch {
    Write-Output $_
    exit
}

# URL of the manifest file
$manifestUrl = "https://raw.githubusercontent.com/Brambler/Brambles-Mod-Sync/main/manifest.json"

# Download the manifest file
$manifestContent = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing
$json = $manifestContent.Content | ConvertFrom-Json

# Create a temporary extraction folder
$tmpPath = Join-Path -Path $PSScriptRoot -ChildPath "tmp"
if (-not (Test-Path -Path $tmpPath)) {
    New-Item -Path $tmpPath -ItemType Directory | Out-Null
}

# Function to download and extract files with error handling and progress logging
function downloadExtract {
    param (
        $name,
        $url
    )
    $fileName = "$name.zip"
    $outputFile = Join-Path -Path $tmpPath -ChildPath $fileName
    Write-Output "Downloading $name from $url to $outputFile"

    try {
        Invoke-WebRequest -Uri $url -OutFile $outputFile -ErrorAction Stop -UseBasicParsing -Verbose -OutVariable downloadLog
        Write-Output "Download of $name completed successfully."
    } catch {
        Write-Output "Error downloading $name from $url`: $($_)"
        return
    }

    # Extract the zip file
    try {
        Expand-Archive -Path $outputFile -DestinationPath $tmpPath -Force
        Write-Output "Extraction of $name completed successfully."
    } catch {
        Write-Output "Error extracting $name`: $($_)"
    }
}

# Iterate through Core components
foreach ($core in $json.Core) {
    downloadExtract -name $core.name -url $core.url
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

# Move extracted folders to the selected installation path
Move-ExtractedFolders -sourcePath $tmpPath -destinationPath $sptInstallationPath

# Delete the temporary extraction folder
Remove-Item -Path $tmpPath -Recurse -Force
Write-Output "Temporary extraction folder deleted."