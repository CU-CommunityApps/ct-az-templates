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
    },
    @{
        Path  = "HKLM\SOFTWARE\FSLogix\Apps"
        Name  = "CleanupInvalidSessions"
        Value = "1" # Cleans out registry keys in the HKEY_LOCAL_MACHINE hive that refer to a users SID. 
        Type  = "DWord"
    },
    @{
        Path  = "HKLM\SOFTWARE\FSLogix\Profiles"
        Name  = "Enabled"
        Value = "1" # Controls whether or not the Profiles feature is active 
        Type  = "DWord"
    },
    @{
        Path  = "HKLM\SOFTWARE\FSLogix\Profiles"
        Name  = "KeepLocalDir"
        Value = "0" # The 'local_%username%' folder will be left on the system after logoff and will also be used again if the same user logs on again 
        Type  = "DWord"
    },
    @{
        Path  = "HKLM\SOFTWARE\FSLogix\Profiles"
        Name  = "PreventLoginWithFailure"
        Value = "1" # Prevent user login when a failure occurs while attaching an FSLogix container
        Type  = "DWord"
    },
    @{
        Path  = "HKLM\SOFTWARE\FSLogix\Profiles"
        Name  = "PreventLoginWithTempProfile"
        Value = "1" # Prevent user login when a user receives a temporary Windows profile
        Type  = "DWord"
    }.
    @{
        Path  = "HKLM\SOFTWARE\FSLogix\Profiles"
        Name  = "VHDLocations"
        Value = "FSLogixStorageAccountPATH" # The location where FSLogix Profile VHDs are stored (CHECKING IF SENSITIVE)
        Type  = "String"
    },
    @{
        Path  = "HKLM\SOFTWARE\Policies\Microsoft\OneDrive"
        Name  = "KFMSilentOptIn"
        Value = "0" # Tenant ID (CHECKING IF SENSITIVE)
        Type  = "String"
    },
    @{
        Path  = "HKLM\SOFTWARE\Policies\Microsoft\OneDrive"
        Name  = "KFMSilentOptInWithNotification"
        Value = "0" # Hide success notification after move
        Type  = "DWord"
    },
    @{
        Path  = "HKLM\SOFTWARE\Policies\Microsoft\OneDrive"
        Name  = "KFMSilentOptInDesktop"
        Value = "1" # Automatically move the Desktop folder to OneDrive without prompting the user
        Type  = "DWord"
    },
    @{
        Path  = "HKLM\SOFTWARE\Policies\Microsoft\OneDrive"
        Name  = "KFMSilentOptInDocuments"
        Value = "1" # Automatically move the Documents folder to OneDrive without prompting the user
        Type  = "DWord"
    },
    @{
        Path  = "HKLM\SOFTWARE\Policies\Microsoft\OneDrive"
        Name  = "KFMSilentOptInPictures"
        Value = "1" # Automatically move the Pictures folder to OneDrive without prompting the user
        Type  = "DWord"
    }
)

foreach ($update in $registryUpdates) {
    Set-RegistryValue -Path $update.Path -Name $update.Name -Value $update.Value -Type $update.Type
}
