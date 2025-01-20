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

# Function to prompt the user for a yes/no/all response
function Get-UserConfirmation {
    param (
        $message,
        $options
    )
    $response = Read-Host "$message $options"
    return $response
}

# Prompt the user to choose the folder location
try {
    $sptInstallationPath = Get-FolderPath
    Write-Host "`nSelected installation path: $sptInstallationPath"
} catch {
    Write-Host "`n$_"
    exit
}

# Create a log file with date and time in the name
$logFileName = "SyncLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$logFilePath = Join-Path -Path $PSScriptRoot -ChildPath $logFileName

# Function to log messages
function LOGGER {
    param (
        $message,
        $isImportant = $false
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp - $message"
    if ($isImportant) {
        Write-Host "`n$logEntry" -ForegroundColor Yellow
    }
    Add-Content -Path $logFilePath -Value $logEntry
}

# URL of the manifest file
$manifestUrl = "https://raw.githubusercontent.com/Brambler/Brambles-Mod-Sync/main/manifest.json"

# Download the manifest file
try {
    $manifestContent = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing
    $json = $manifestContent.Content | ConvertFrom-Json
    LOGGER "Manifest file downloaded successfully." $true
} catch {
    LOGGER "Error downloading manifest file: $($_)" $true
    exit
}

# Create a temporary extraction folder
$tmpPath = Join-Path -Path $PSScriptRoot -ChildPath "tmp"
if (-not (Test-Path -Path $tmpPath)) {
    New-Item -Path $tmpPath -ItemType Directory | Out-Null
    LOGGER "Temporary extraction folder created."
}

# Function to download and extract files with error handling and progress logging
function downloadExtract {
    param (
        $name,
        $url
    )
    $fileName = "$name.zip"
    $outputFile = Join-Path -Path $tmpPath -ChildPath $fileName
    $extractPath = Join-Path -Path $tmpPath -ChildPath $name
    LOGGER "Downloading $name from $url to $outputFile"

    try {
        Invoke-WebRequest -Uri $url -OutFile $outputFile -ErrorAction Stop -UseBasicParsing
        LOGGER "Download of $name completed successfully."
    } catch {
        LOGGER "Error downloading $name from $url`: $($_)" $true
        return
    }

    # Extract the zip file
    try {
        Expand-Archive -Path $outputFile -DestinationPath $extractPath -Force
        LOGGER "Extraction of $name completed successfully."
    } catch {
        LOGGER "Error extracting $name`: $($_)" $true
    }
}

# Iterate through Core components
foreach ($core in $json.Core) {
    downloadExtract -name $core.name -url $core.url
}

# Function to compare and move extracted folders to a different location with overwrite prompt for each file
function Compare-And-Move {
    param (
        $sourcePath,
        $destinationPath
    )
    $folders = Get-ChildItem -Path $sourcePath -Directory
    foreach ($folder in $folders) {
        $subFolders = Get-ChildItem -Path $folder.FullName -Directory
        foreach ($subFolder in $subFolders) {
            if ($subFolder.Name -eq "user" -or $subFolder.Name -eq "BepInEx") {
                $destFolder = Join-Path -Path $destinationPath -ChildPath $subFolder.Name
                $files = Get-ChildItem -Path $subFolder.FullName -Recurse -File
                $overwriteAll = $false
                foreach ($file in $files) {
                    $destFile = Join-Path -Path $destFolder -ChildPath $file.FullName.Substring($subFolder.FullName.Length + 1)
                    $destDir = Split-Path -Path $destFile -Parent
                    if (-not (Test-Path -Path $destDir)) {
                        New-Item -Path $destDir -ItemType Directory | Out-Null
                    }
                    if (Test-Path -Path $destFile) {
                        if (-not $overwriteAll) {
                            $response = Get-UserConfirmation -message "`nFile $destFile already exists. Do you want to overwrite it?" -options "(ALL/y/n)"
                            if ($response -eq 'n') {
                                LOGGER "Skipped overwriting $destFile"
                                continue
                            } elseif ($response -eq 'all') {
                                $overwriteAll = $true
                            }
                        }
                    }
                    Copy-Item -Path $file.FullName -Destination $destFile -Force
                    LOGGER "Copied $($file.FullName) to $destFile"
                }
            }
        }
    }
}

# Compare and move extracted folders to the selected installation path
Compare-And-Move -sourcePath $tmpPath -destinationPath $sptInstallationPath

# Prompt the user to delete the temporary extraction folder
if (Get-UserConfirmation -message "`nDo you want to delete the temporary extraction folder?" -options "(Y/n)") {
    Remove-Item -Path $tmpPath -Recurse -Force
    LOGGER "Temporary extraction folder deleted." $true
} else {
    LOGGER "Temporary extraction folder retained." $true
}

LOGGER "Script execution completed." $true