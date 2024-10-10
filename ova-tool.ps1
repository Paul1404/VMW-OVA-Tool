<#
.SYNOPSIS
    A PowerShell script to automate the use of VMware OVF Tool, handling installation, credential storage, and execution.

.DESCRIPTION
    This script checks if VMware OVF Tool is installed, and if not, downloads and installs it silently.
    It securely stores and retrieves credentials, prompts for the VM path and destination, and then dynamically crafts and executes the OVF Tool command.
    
.NOTES
    Author: Paul
    Date: 2024-10-10
    PowerShell Version: 5.1 or higher
#>

# Define the OVF Tool path (constant)
$OvfToolPath = "C:\Program Files\VMware\VMware OVF Tool\ovftool.exe"

# Function to check and install OVF Tool if necessary
function Install-OVFTool {
    if (-Not (Test-Path $OvfToolPath)) {
        Write-Host "OVF Tool not found. Downloading and installing..."

        # Define the MSI download link and local download path
        $DownloadLink = "https://armann-systems.com/download/vmware-ovftool-4-2-64bit-for-windows/?wpdmdl=2725&refresh=67065749a24b01728468809"
        $InstallerPath = "$env:TEMP\VMware-ovftool-4.6.3.msi"
        
        try {
            # Download the MSI installer
            Invoke-WebRequest -Uri $DownloadLink -OutFile $InstallerPath
            Write-Host "Installer downloaded successfully."

            # Silent install the MSI
            Write-Host "Installing OVF Tool..."
            Start-Process msiexec.exe -ArgumentList "/i `"$InstallerPath`" /quiet /norestart" -Wait

            # Verify the installation
            if (Test-Path $OvfToolPath) {
                Write-Host "OVF Tool installed successfully."
            } else {
                throw "OVF Tool installation failed."
            }
        } catch {
            Write-Host "Error: $($_.Exception.Message)"
            exit 1
        } finally {
            # Clean up the installer
            if (Test-Path $InstallerPath) {
                Remove-Item $InstallerPath -Force
            }
        }
    } else {
        Write-Host "OVF Tool is already installed."
    }
}

# Function to store credentials securely
function Save-Credentials {
    $Username = Read-Host "Enter your username"
    $Password = Read-Host "Enter your password" -AsSecureString

    # Create a PSCredential object
    $Cred = New-Object System.Management.Automation.PSCredential($Username, $Password)

    # Encrypt and store credentials in a file
    $Cred | Export-CliXML -Path "$env:USERPROFILE\vmware_creds.xml"

    Write-Host "Credentials saved securely."
}

# Function to load credentials securely
function Get-Credentials {
    if (Test-Path "$env:USERPROFILE\vmware_creds.xml") {
        try {
            # Load encrypted credentials
            $Cred = Import-CliXML "$env:USERPROFILE\vmware_creds.xml"
            Write-Host "Credentials loaded successfully."
            return $Cred
        } catch {
            Write-Host "Error: Failed to load credentials. $_.Exception.Message"
            exit 1
        }
    } else {
        Write-Host "Credentials not found. Please enter and save them."
        Save-Credentials
        return Get-Credentials  # Re-run after saving
    }
}

# Function to dynamically craft and execute OVF Tool command
function Invoke-OVFTool {
    # Load credentials
    $Cred = Get-Credentials
    $Username = $Cred.UserName
    $Password = $Cred.GetNetworkCredential().Password

    # Prompt user for VM path and destination
    $VMPath = Read-Host "Enter the full path to the VM (e.g., hldca-nested/vm/hldca-nested-vca-vms/TRITON)"
    $StoragePath = Read-Host "Enter the local storage path (e.g., C:\Users\pauld\Downloads)"

    # Craft the OVF Tool command
    $SourceVM = "vi://${Username}:${Password}@hldca-vca-17825.home.local/$VMPath"
    $OvfCommand = "`"$OvfToolPath`" $SourceVM $StoragePath"

    Write-Host "Executing OVF Tool with the following command:"
    Write-Host $OvfCommand

    try {
        # Run the crafted command
        Invoke-Expression $OvfCommand
    } catch {
        Write-Host "Error: $($_.Exception.Message)"
        exit 1
    }
}

# Main Script Execution
try {
    # Step 1: Check and install OVF Tool if necessary
    Install-OVFTool

    # Step 2: Run OVF Tool after confirming installation
    Invoke-OVFTool
} catch {
    Write-Host "Script encountered an error: $($_.Exception.Message)"
    exit 1
}
