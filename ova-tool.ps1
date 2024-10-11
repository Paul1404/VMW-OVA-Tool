<#
.SYNOPSIS
    A PowerShell script to automate the use of VMware OVF Tool, handling installation, credential storage, and execution.

.DESCRIPTION
    This script checks if VMware OVF Tool is installed, and if not, downloads and installs it silently.
    It securely stores and retrieves credentials, prompts for the vCenter FQDN, VM path, and destination, and then dynamically crafts and executes the OVF Tool command.

.PARAMETER ClearCredentials
    If specified, this parameter clears the stored credentials.

.PARAMETER VerboseMode
    If specified, this parameter provides detailed logs of actions performed by the script.

.NOTES
    Author: Paul
    Date: 2024-10-10
    Version: 1.3
    PowerShell Version: 5.1 or higher
    Tested on: Windows 10

.LINK
    https://github.com/Paul1404/VMW-OVA-Tool
#>

param (
    [switch]$ClearCredentials,
    [switch]$VerboseMode
)

# Define the OVF Tool path (constant)
$OvfToolPath = "C:\Program Files\VMware\VMware OVF Tool\ovftool.exe"

# Verbose logging function
function Log-VerboseMessage {
    param ($Message)
    if ($VerboseMode) {
        Write-Host "[VERBOSE] $Message" -ForegroundColor Cyan
    }
}

# Function to clear stored credentials
function Clear-Credentials {
    <#
    .SYNOPSIS
        Clears the stored credentials.
    .DESCRIPTION
        Deletes the stored credentials file securely from the user's profile.
    #>
    
    $CredFile = "$env:USERPROFILE\vmware_creds.xml"
    if (Test-Path $CredFile) {
        Remove-Item $CredFile -Force
        Write-Host "Credentials cleared successfully." -ForegroundColor Green
    } else {
        Write-Host "No stored credentials found." -ForegroundColor Yellow
    }
}

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
            Log-VerboseMessage "Downloading the installer..."
            Invoke-WebRequest -Uri $DownloadLink -OutFile $InstallerPath
            Write-Host "Installer downloaded successfully." -ForegroundColor Green

            # Silent install the MSI
            Log-VerboseMessage "Installing OVF Tool..."
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
                Log-VerboseMessage "Cleaning up installer file..."
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

# Function to encode password for use in URL (handles special characters)
function Encode-Password {
    param ($Password)
    return [System.Web.HttpUtility]::UrlEncode($Password)
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
    $EncodedPassword = Encode-Password $Password

    # Prompt user for vCenter FQDN, VM path, and destination
    $vCenterFQDN = Read-Host "Enter the vCenter FQDN (e.g., vcenter.company.local)"
    $VMPath = Read-Host "Enter the full path to the VM (e.g., hldca-nested/vm/hldca-nested-vca-vms/TRITON)"
    $StoragePath = Read-Host "Enter the local storage path (e.g., C:\Users\pauld\Downloads)"

    # Craft the OVF Tool command (with encoded password)
    $SourceVM = "vi://${Username}:${EncodedPassword}@$vCenterFQDN/$VMPath"
    $Arguments = "$SourceVM $StoragePath"

    Write-Host "Executing OVF Tool with the following command:" -ForegroundColor Yellow
    Write-Host "`"$OvfToolPath`" $Arguments"

    try {
        # Use Start-Process to capture output and errors from the OVF Tool
        Start-Process -FilePath $OvfToolPath -ArgumentList $Arguments -NoNewWindow -Wait -PassThru | 
            ForEach-Object {
                $_.StandardOutput.ReadToEnd()
                $_.StandardError.ReadToEnd()
            }
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}


# Main Script Execution
if ($ClearCredentials) {
    Clear-Credentials
    exit 0
}

try {
    # Step 1: Check and install OVF Tool if necessary
    Install-OVFTool

    # Step 2: Run OVF Tool after confirming installation
    Invoke-OVFTool
} catch {
    Write-Host "Script encountered an error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

