# Create Default User Profile registry settings
Function Set-RegistryValue {
    Param (
        [Parameter(Mandatory = $true)] [String] $Path,
        [Parameter(Mandatory = $true)] [String] $Name,
        [Parameter(Mandatory = $true)] $Value,
        [Parameter(Mandatory = $true)] [String] $Type
    )
    
    # Check if the registry path exists; if not, create it
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    # Set the property value
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
}

# Registry updates to be performed
$registryUpdates = @(
    # Enable Kerberos ticket retrieval for Azure Files
    @{
        Path  = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
        Name  = "CloudKerberosTicketRetrievalEnabled"
        Value = 1
        Type  = "DWord"
    },
    # Disable MSIX automatic updates # https://learn.microsoft.com/en-us/azure/virtual-desktop/app-attach-setup?tabs=portal&pivots=app-attach#disable-automatic-updates
    @{
        Path  = "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name  = "PreInstalledAppsEnabled"
        Value = "0"
        Type  = "DWord"
    },
    @{
        Path  = "HKLM:\SOFTWARE\FSLogix\Profiles"
        Name  = "SIDDirNamePattern"
        Value = "%username%" # use netID only
        Type  = "String"
    },
    @{
        Path  = "HKLM:\SOFTWARE\FSLogix\Profiles"
        Name  = "SIDDirNameMatch"
        Value = "%username%" # use netID only
        Type  = "String"
    },
    @{
        Path  = "HKLM:\SOFTWARE\FSLogix\Profiles"
        Name  = "VHDNamePattern"
        Value = "%username%" # use netID only
        Type  = "String"
    },
    @{
        Path  = "HKLM:\SOFTWARE\FSLogix\Profiles"
        Name  = "VHDNameMatch"
        Value = "%username%" # use netID only
        Type  = "String"
    }
)

foreach ($update in $registryUpdates) {
    Set-RegistryValue -Path $update.Path -Name $update.Name -Value $update.Value -Type $update.Type
}
