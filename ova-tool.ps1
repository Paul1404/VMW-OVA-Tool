<#
.SYNOPSIS
    A PowerShell script to automate the use of VMware OVF Tool, handling installation, credential storage, and execution.

.DESCRIPTION
    This script checks if VMware OVF Tool is installed, and if not, downloads and installs it silently.
    It securely stores and retrieves credentials, prompts for the vCenter FQDN, VM path, and destination, and then dynamically crafts and executes the OVF Tool command.

.PARAMETER None
    No parameters are required to run this script interactively.

.NOTES
    Author: Paul
    Date: 2024-10-10
    Version: 1.1
    PowerShell Version: 5.1 or higher
    Tested on: Windows 10

.LINK
    https://github.com/Paul1404/VMW-OVA-Tool
#>

# Define the OVF Tool path (constant)
$OvfToolPath = "C:\Program Files\VMware\VMware OVF Tool\ovftool.exe"

# Function to check and install OVF Tool if necessary
function Install-OVFTool {
    <#
    .SYNOPSIS
        Installs the VMware OVF Tool if not already installed.
    .DESCRIPTION
        This function checks if the VMware OVF Tool is installed in the default directory.
        If not, it downloads the installer and performs a silent installation.
    #>
    
    if (-Not (Test-Path $OvfToolPath)) {
        Write-Host "OVF Tool not found. Downloading and installing..."

        # Define the MSI download link and local download path
        $DownloadLink = "https://armann-systems.com/download/vmware-ovftool-4-2-64bit-for-windows/?wpdmdl=2725&refresh=67065749a24b01728468809"
        $InstallerPath = "$env:TEMP\VMware-ovftool-4.6.3.msi"
        
        try {
            # Download the MSI installer
            Write-Host "Downloading the installer..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $DownloadLink -OutFile $InstallerPath
            Write-Host "Installer downloaded successfully." -ForegroundColor Green

            # Silent install the MSI
            Write-Host "Installing OVF Tool..." -ForegroundColor Yellow
            Start-Process msiexec.exe -ArgumentList "/i `"$InstallerPath`" /quiet /norestart" -Wait

            # Verify the installation
            if (Test-Path $OvfToolPath) {
                Write-Host "OVF Tool installed successfully." -ForegroundColor Green
            } else {
                throw "OVF Tool installation failed."
            }
        } catch {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        } finally {
            # Clean up the installer
            if (Test-Path $InstallerPath) {
                Write-Host "Cleaning up installer file..." -ForegroundColor Yellow
                Remove-Item $InstallerPath -Force
            }
        }
    } else {
        Write-Host "OVF Tool is already installed." -ForegroundColor Green
    }
}

# Function to store credentials securely
function Save-Credentials {
    <#
    .SYNOPSIS
        Prompts the user for credentials and stores them securely.
    .DESCRIPTION
        This function prompts the user to enter a username and password.
        The credentials are stored securely in the user's profile folder.
    #>

    $Username = Read-Host "Enter your username"
    $Password = Read-Host "Enter your password" -AsSecureString

    # Create a PSCredential object
    $Cred = New-Object System.Management.Automation.PSCredential($Username, $Password)

    # Encrypt and store credentials in a file
    $Cred | Export-CliXML -Path "$env:USERPROFILE\vmware_creds.xml"

    Write-Host "Credentials saved securely." -ForegroundColor Green
}

# Function to load credentials securely
function Get-Credentials {
    <#
    .SYNOPSIS
        Loads stored credentials from a secure file.
    .DESCRIPTION
        This function checks if encrypted credentials are stored. If not, it prompts the user to enter and save them.
        The credentials are securely retrieved from the user's profile folder.
    #>

    if (Test-Path "$env:USERPROFILE\vmware_creds.xml") {
        try {
            # Load encrypted credentials
            $Cred = Import-CliXML "$env:USERPROFILE\vmware_creds.xml"
            Write-Host "Credentials loaded successfully." -ForegroundColor Green
            return $Cred
        } catch {
            Write-Host "Error: Failed to load credentials. $_.Exception.Message" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Credentials not found. Please enter and save them." -ForegroundColor Yellow
        Save-Credentials
        return Get-Credentials  # Re-run after saving
    }
}

# Function to dynamically craft and execute OVF Tool command
function Invoke-OVFTool {
    <#
    .SYNOPSIS
        Prompts for vCenter FQDN, VM and storage paths, and executes the OVF Tool command.
    .DESCRIPTION
        This function dynamically builds the OVF Tool command using stored credentials and user input for the vCenter FQDN, VM path, and storage destination.
        It then executes the command to export the VM to the specified destination.
    #>

    # Load credentials
    $Cred = Get-Credentials
    $Username = $Cred.UserName
    $Password = $Cred.GetNetworkCredential().Password

    # Prompt user for vCenter FQDN, VM path, and destination
    $vCenterFQDN = Read-Host "Enter the vCenter FQDN (e.g., vcenter.company.local)"
    $VMPath = Read-Host "Enter the full path to the VM (e.g., hldca-nested/vm/hldca-nested-vca-vms/TRITON)"
    $StoragePath = Read-Host "Enter the local storage path (e.g., C:\Users\pauld\Downloads)"

    # Craft the OVF Tool command
    $SourceVM = "vi://${Username}:${Password}@$vCenterFQDN/$VMPath"
    $OvfCommand = "`"$OvfToolPath`" $SourceVM $StoragePath"

    Write-Host "Executing OVF Tool with the following command:" -ForegroundColor Yellow
    Write-Host $OvfCommand

    try {
        # Run the crafted command
        Invoke-Expression $OvfCommand
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
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
    Write-Host "Script encountered an error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

