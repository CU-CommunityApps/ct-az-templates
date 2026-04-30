[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12  
$ErrorActionPreference = 'Stop'

param(
    [Parameter(Mandatory = $true)] [string]$FslogixStorageAccountPath,
    [Parameter(Mandatory = $true)] [string]$TenantId,
    [Parameter(Mandatory = $true)] [string]$CCSSAdminStorageAccountName
)

$script:TranscriptStarted = $false

function Start-BootstrapTranscript {
    param(
        [Parameter(Mandatory = $true)] [string] $Path
    )

    Start-Transcript -Path $Path -Append
    $script:TranscriptStarted = $true
}

function Invoke-ProcessAndAssert {
    param(
        [Parameter(Mandatory = $true)] [string] $FilePath,
        [string] $ArgumentList,
        [string] $WorkingDirectory
    )

    $startParams = @{
        FilePath = $FilePath
        Wait = $true
        PassThru = $true
        ErrorAction = 'Stop'
    }

    if ($null -ne $ArgumentList -and $ArgumentList -ne '') {
        $startParams.ArgumentList = $ArgumentList
    }

    if ($null -ne $WorkingDirectory -and $WorkingDirectory -ne '') {
        $startParams.WorkingDirectory = $WorkingDirectory
    }

    $process = Start-Process @startParams
    if ($process.ExitCode -ne 0) {
        throw "Process '$FilePath' failed with exit code $($process.ExitCode)."
    }
}

function Install-PackageProviderModule {
    param (
        [Parameter(Mandatory = $true)] [string] $Name,
        [string] $MinimumVersion
    )

    try {
        $installParams = @{
            Name = $Name
            Force = $true
            Verbose = $true
        }

        if ($MinimumVersion) {
            $installParams.MinimumVersion = $MinimumVersion
        }

        Install-PackageProvider @installParams
        Write-Output "$Name provider installed successfully."
    }
    catch {
        Write-Error "Failed to install ${Name} provider: $_"
        throw
    }
}

function Install-UtilityPackage {
    param (
        [Parameter(Mandatory = $true)] [string] $PackageId,
        [Parameter(Mandatory = $true)] [string] $Url,
        [string] $InstallParams
    )

    try {
        Write-Output "Downloading package $PackageId..."
        $installerName = [System.IO.Path]::GetFileName(([System.Uri] $Url).AbsolutePath)
        if ([string]::IsNullOrWhiteSpace($installerName)) {
            throw "Unable to resolve a download file name for package '${PackageId}' from URL '$Url'."
        }

        $installerPath = Join-Path -Path $env:temp -ChildPath $installerName

        Start-BitsTransfer -Source $Url -Destination $installerPath -Verbose

        Write-Output "Installing package $PackageId..."
        if ($installerPath.EndsWith(".msi")) {
            Invoke-ProcessAndAssert -FilePath "msiexec.exe" -ArgumentList "/i $installerPath /norestart /qn"
        }
        elseif ($installerPath.EndsWith(".exe")) {
            Invoke-ProcessAndAssert -FilePath $installerPath -ArgumentList $InstallParams
        }
        else {
            throw "Incompatible installer file for ${PackageId}: $installerPath"
        }

        Write-Output "Installed package $PackageId successfully."
    }
    catch {
        Write-Error "Failed to install package ${PackageId}: $_"
        throw
    }
}

function Get-UtilityPackages {
    return @(
        # @{
        #     packageId = "Microsoft.WindowsAppSDK"
        #     URL = "https://aka.ms/windowsappsdk/1.4/1.4.240802001/windowsappruntimeinstall-x64.exe"
        #     installParams = "--quiet --force --msix"
        # },
        # @{
        #     packageId = "Microsoft Windows Desktop Runtime"
        #     URL = "https://download.visualstudio.microsoft.com/download/pr/f1e7ffc8-c278-4339-b460-517420724524/f36bb75b2e86a52338c4d3a90f8dac9b/windowsdesktop-runtime-8.0.12-win-x64.exe"
        #     installParams = "/install /quiet /norestart"
        # },
        @{
            packageId = "7zip"
            URL = (Invoke-WebRequest -Uri "https://www.7-zip.org/download.html" -UseBasicParsing | 
                Select-Object -ExpandProperty Links | 
                Where-Object -Property href -like "*-x64.msi")[0].href
            installParams = ""
        },
        @{
            packageId = "NotePad++"
            URL = (Invoke-WebRequest -Uri "https://notepad-plus-plus.org$((Invoke-WebRequest -Uri "https://notepad-plus-plus.org" -UseBasicParsing | 
                Select-Object -ExpandProperty links | 
                Where-Object -Property href -like "/downloads/v*").href)" -UseBasicParsing | 
                Select-Object -ExpandProperty links | 
                Where-Object -Property href -like "*npp.*.installer.x64.exe").href | 
                Select-Object -Index 0
            installParams = "/S /noUpdater"
        },
        @{
            packageId = "Mozilla Firefox"
            URL = (Invoke-WebRequest -Uri "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US" -Method Head -MaximumRedirection 5 -UseBasicParsing).BaseResponse.ResponseUri.AbsoluteUri
            installParams = "/S"
        }
        # @{
        #     packageId = "Python"
        #     URL = "https://www.python.org/ftp/python/3.13.3/python-3.13.3-amd64.exe"
        #     installParams = "/quiet InstallAllUsers=1 PrependPath=1 Include_pip=1"
        # },
        # @{
        #     packageId = "Git"
        #     URL = "https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/Git-2.49.0-64-bit.exe"
        #     installParams = "/VERYSILENT /NORESTART"
        # },
        # @{
        #     packageId = "JAGS"
        #     URL = "https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Windows/JAGS-4.3.1.exe"
        #     installParams = "/S"
        # }
    )
}

function Install-UtilityPackages {
    $packages = Get-UtilityPackages
    foreach ($package in $packages) {
        Install-UtilityPackage -PackageId $package.packageId -Url $package.URL -InstallParams $package.installParams
    }
}

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

function Get-RegistryUpdates {
    return @(
    # # Disable Windows Copilot
    # @{
    #     Path  = "Registry::HKEY_USERS\.DEFAULT\Software\Policies\Microsoft\Windows\WindowsCopilot"
    #     Name  = "TurnOffWindowsCopilot"
    #     Value = 1
    #     Type  = "DWord"
    # },
    # Disable MSIX automatic updates # https://learn.microsoft.com/en-us/azure/virtual-desktop/app-attach-setup?tabs=portal&pivots=app-attach#disable-automatic-updates
    @{
        Path  = "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Name  = "PreInstalledAppsEnabled"
        Value = "0"
        Type  = "DWord"
    },
    # Set default terminal app to Windows Terminal
    @{
        Path  = "Registry::HKEY_USERS\.DEFAULT\Console\%%Startup"
        Name  = "DelegationConsole"
        Value = "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}"
        Type  = "String"
    },
    @{
        Path  = "Registry::HKEY_USERS\.DEFAULT\Console\%%Startup"
        Name  = "DelegationTerminal"
        Value = "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}"
        Type  = "String"
    },
    # Set desktop wallpaper stlye to "Fit"
    # @{
    #     Path  = "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop"
    #     Name  = "WallpaperStyle"
    #     Value = "3" # 3 = fit
    #     Type  = "String"
    # },
    @{
        Path  = "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Policies\System"
        Name  = "WallpaperStyle"
        Value = "3" # 3 = fit
        Type  = "String"
    },
    @{
        Path  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
        Name  = "WallpaperStyle"
        Value = "3" # 3 = fit
        Type  = "String"
    },
    @{
        Path  = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
        Name  = "WallpaperStyle"
        Value = "3" # 3 = fit
        Type  = "String"
    },
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
        Path  = "HKLM:\SOFTWARE\FSLogix\Apps"
        Name  = "CleanupInvalidSessions"
        Value = "1" # Cleans out registry keys in the HKEY_LOCAL_MACHINE hive that refer to a users SID. 
        Type  = "DWord"
    },
    @{
        Path  = "HKLM:\SOFTWARE\FSLogix\Profiles"
        Name  = "Enabled"
        Value = "1" # Controls whether or not the Profiles feature is active 
        Type  = "DWord"
    },
    @{
        Path  = "HKLM:\SOFTWARE\FSLogix\Profiles"
        Name  = "KeepLocalDir"
        Value = "0" # The 'local_%username%' folder will be left on the system after logoff and will also be used again if the same user logs on again 
        Type  = "DWord"
    },
    @{
        Path  = "HKLM:\SOFTWARE\FSLogix\Profiles"
        Name  = "PreventLoginWithFailure"
        Value = "1" # Prevent user login when a failure occurs while attaching an FSLogix container
        Type  = "DWord"
    },
    @{
        Path  = "HKLM:\SOFTWARE\FSLogix\Profiles"
        Name  = "PreventLoginWithTempProfile"
        Value = "1" # Prevent user login when a user receives a temporary Windows profile
        Type  = "DWord"
    },
    @{
        Path  = "HKLM:\SOFTWARE\FSLogix\Profiles"
        Name  = "VHDLocations"
        Value = $FslogixStorageAccountPath # The location where FSLogix Profile VHDs are stored
        Type  = "String"
    },
    @{
        Path  = "HKLM:\SOFTWARE\FSLogix\Profiles"
        Name  = "SizeInMBs"
        Value = 30000   # quota in MB (e.g. 10000 = 10 GB)
        Type  = "DWord"
    },
    @{
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
        Name  = "KFMSilentOptIn"
        Value = $TenantId # Tenant ID
        Type  = "String"
    },
    @{
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
        Name  = "KFMSilentOptInWithNotification"
        Value = "0" # Hide success notification after move
        Type  = "DWord"
    },
    @{
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
        Name  = "KFMSilentOptInDesktop"
        Value = "1" # Automatically move the Desktop folder to OneDrive without prompting the user
        Type  = "DWord"
    },
    @{
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
        Name  = "KFMSilentOptInDocuments"
        Value = "1" # Automatically move the Documents folder to OneDrive without prompting the user
        Type  = "DWord"
    },
    @{
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
        Name  = "KFMSilentOptInPictures"
        Value = "1" # Automatically move the Pictures folder to OneDrive without prompting the user
        Type  = "DWord"
    },
    @{
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
        Name  = "FilesOnDemandEnabled"
        Value = "1" # Enable OneDrive Files On-Demand, which allows users to access all their files in OneDrive without having to download them and use storage space on their device
        Type  = "DWord"
    },
    # Storage Sense – Allow Storage Sense (Global)
    @{
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense"
        Name  = "AllowStorageSenseGlobal"
        Value = 1   # 1 = Enabled
        Type  = "DWord"
    },
    # Storage Sense – Allow Temporary Files Cleanup
    @{
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense"
        Name  = "AllowStorageSenseTemporaryFilesCleanup"
        Value = 1   # 1 = Enabled
        Type  = "DWord"
    },
    # Storage Sense – Cloud content dehydration threshold (OneDrive)
    # "Delete unused cloud‑backed content" after N days (here: 1 day)
    @{
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense"
        Name  = "ConfigStorageSenseCloudContentDehydrationThreshold"
        Value = 30   # days
        Type  = "DWord"
    },
    # Storage Sense – Recycle Bin cleanup threshold
    # "Delete files in Recycle Bin if they've been there for N days" (here: 7 days)
    @{
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense"
        Name  = "ConfigStorageSenseRecycleBinCleanupThreshold"
        Value = 7   # days
        Type  = "DWord"
    },
    @{
        Path  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        Name  = "MapDrive"
        Value = "cmd /c start /min "" powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""\\$CCSSAdminStorageAccountName.file.core.windows.net\admin\MapDrive\mapdrive.ps1"""
        Type  = "String"
    },
    @{
        Path  = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\windows.net\$CCSSAdminStorageAccountName.file.core"
        Name  = "file"
        Value = 2
        Type  = "DWord"
    }
    )
}

function Apply-RegistryUpdates {
    $registryUpdates = Get-RegistryUpdates
    foreach ($update in $registryUpdates) {
        Set-RegistryValue -Path $update.Path -Name $update.Name -Value $update.Value -Type $update.Type
    }
}

function New-SignOutShortcut {
    Start-BitsTransfer -Source "https://raw.githubusercontent.com/CU-CommunityApps/ct-az-templates/master/scripts/avd/ccss/signout.ico" -Destination "$env:windir\system32\signout.ico" -Verbose

    $shell = New-Object -comObject WScript.Shell
    $shortcut = $shell.CreateShortcut("$env:public\desktop\Sign out.lnk")
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-Command `"logoff`""
    $shortcut.IconLocation = "$env:windir\system32\signout.ico"
    $shortcut.WindowStyle = 7
    $shortcut.Save()
}

function Invoke-Bootstrap {
    $logFile = "C:\bootstrap.log"
    Start-BootstrapTranscript -Path $logFile

    try {
        # Install-PackageProviderModule -Name NuGet -MinimumVersion 2.8.5.201
        Install-UtilityPackages
        Apply-RegistryUpdates
        New-SignOutShortcut
    }
    catch {
        Write-Error "Bootstrap failed: $_"
        throw
    }
    finally {
        if ($script:TranscriptStarted) {
            Stop-Transcript
        }
    }
}

Invoke-Bootstrap
