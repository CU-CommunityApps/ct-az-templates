[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12  
  
# Define the log file path  
$logFile = "C:\bootstrap.log"
  
# Start logging everything to the transcript file  
Start-Transcript -Path $logFile -Append
    
# Install NuGet  
try {
    # mkdir "$Env:ProgramFiles\NuGet" -Force -Verbose
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Verbose
    # Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile "$Env:ProgramFiles\NuGet\nuget.exe" -Verbose
    Write-Output "NuGet installed successfully."
} catch {  
    Write-Output "Failed to install NuGet: $_"  
}

# # Install dotnet
# try {
#     Write-Output "Installing dotnet"
#     Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://dot.net/v1/dotnet-install.ps1'))
# } catch {
#     Write-Output "Failed to install dotnet: $_"
# }

# # Install Chocolatey
# try {
#     Write-Output "Installing Chocolatey"
#     Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
# } catch {
#     Write-Output "Failed to install Chocolatey: $_"
# }
  
# # Install WinGet  
# try {  
#     Install-Module -Name Microsoft.WinGet.Client -Force -Verbose
#     Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -Verbose
#     Write-Output "WinGet installed successfully."  
# } catch {  
#     Write-Output "Failed to install WinGet: $_"  
# }  
  
# Reset Windows Terminal  
try {  
    Get-AppxPackage Microsoft.WindowsTerminal -AllUsers | Reset-AppPackage -Verbose
    Write-Output "Windows Terminal reset successfully."  
} catch {  
    Write-Output "Failed to reset Windows Terminal: $_"  
}

# Install Basic Utility Packages

# Function to install a package and log results  
function Install-Package {  
    param (  
        [string]$packageId,
        [string]$URL,
        [string]$installParams
    )  
    try {
        Write-Output "Downloading package $packageId..."
        Start-BitsTransfer -Source $URL -Destination "$env:temp" -Verbose
        Write-Output "Installing package $packageId..."
        If ($URL.EndsWith(".msi")){Start-Process "msiexec.exe" -ArgumentList "/i $env:temp\$($url.Split("/")[-1]) /norestart /qn" -Wait}
        ElseIf ($URL.EndsWith(".exe")){Start-Process "$env:temp\$($url.Split("/")[-1])" -ArgumentList "$installParams" -Wait}
        Else {Write-Output "Incompatible installer file"}
        #cd "$env:ProgramFiles\NuGet"
        #.\nuget.exe install $packageId -Source "https://api.nuget.org/v3/index.json" -Verbosity detailed
        Write-Output "Installed package $packageId successfully."  
    } catch {  
        Write-Output "Failed to install package ${packageId}: $_"  
    }  
}  

# List of WinGet package IDs  
<#$packages = @(  
    "Microsoft.WindowsAppSDK",
    "7zip",
    "notepadplusplus",
    "GitForWindows",
    "python"
    "texstudio",
    "tortoisesvn"
)#> 

$packages = @(
    @{
        packageId = "Microsoft.WindowsAppSDK"
        URL = "https://aka.ms/windowsappsdk/1.4/1.4.240802001/windowsappruntimeinstall-x64.exe"
        installParams = "--quiet --force --msix"
    },
    @{
        packageId = "7zip"
        URL = "https://www.7-zip.org/$((iwr -Uri "https://www.7-zip.org/download.html" -UseBasicParsing | Select -ExpandProperty Links | Where -Property href -like "*-x64.msi")[0].href)"
        installParams = ""
    },
    @{
        packageId = "NotePad++"
        URL = $(((iwr -URI $("https://notepad-plus-plus.org$(((iwr -Uri "https://notepad-plus-plus.org" -UseBasicParsing) | Select -ExpandProperty links | Where -Property href -like "/downloads/v*").href)") -UseBasicParsing) | Select -ExpandProperty links | Where -Property href -like "*npp.*.installer.x64.exe").href | Select -Index 0)
        installParams = "/S"
    },
    @{
        packageId = "Python"
        URL = "https://www.python.org/ftp/python/3.12.4/python-3.12.4.exe"
        installParams = "/quiet InstallAllUsers=1 PrependPath=1 Include_pip=1"
    },
    @{
        packageId = "Git"
        URL = "https://github.com/git-for-windows/git/releases/download/v2.45.2.windows.1/Git-2.45.2-64-bit.exe"
        installParams = "/VERYSILENT /NORESTART"
    },
    @{
        packageId = "JAGS"
        URL = "https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Windows/JAGS-4.3.1.exe"
        installParams = "/S"
    }
)

# Loop through each package and install it  
foreach ($package in $packages) {  
    Install-Package -packageId $package.packageId -URL $package.URL -installParams $package.installParams
}

# Remove Windows Bloatware
##Get appx Packages
$Packages = Get-AppxPackage

##Create Your allowlist
$AllowList = @(
    '*WindowsCalculator*',
    '*Office.OneNote*',
    '*Microsoft.net*',
    '*WindowsStore*',
    '*WindowsTerminal*',
    '*WindowsNotepad*',
    '*Paint*',
    '*Microsoft.PowerAutomateDesktop*',
    '*Microsoft.CompanyPortal*',
    '*Microsoft.Windows.Photos*',
    '*Microsoft.HEIFImageExtension*',
    '*Microsoft.HEVCVideoExtension*',
    '*Microsoft.RawImageExtension*',
    '*Microsoft.VP9VideoExtensions*',
    '*Microsoft.WebMediaExtensions*',
    '*Microsoft.WebpImageExtension*',
    '*Microsoft.WindowsAppRuntime*'
)

###Get All Dependencies
ForEach($Dependency in $AllowList){
    (Get-AppxPackage  -Name “$Dependency”).dependencies | ForEach-Object{
        $NewAdd = "*" + $_.Name + "*"
        if($_.name -ne $null -and $AllowList -notcontains $NewAdd){
            $AllowList += $NewAdd
       }
    }
}

##View all applications not in your allowlist
ForEach($App in $Packages){
    $Matched = $false
    Foreach($Item in $AllowList){
        If($App -like $Item){
            $Matched = $true
            break
        }
    }
    ###Nonremovable attribute does not exist before 1809, so if you are running this on an earlier build, remove “-and $app.NonRemovable -eq $false” rt; it attempts to remove everything
    if($matched -eq $false -and $app.NonRemovable -eq $false){
        Get-AppxPackage -AllUsers -Name $App.Name -PackageTypeFilter Bundle | Remove-AppxPackage -AllUsers -Verbose
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

# Registry updates to be performed
$registryUpdates = @(
    # Enable Kerberos ticket retrieval for Azure Files
    @{
        Path  = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
        Name  = "CloudKerberosTicketRetrievalEnabled"
        Value = 1
        Type  = "DWord"
    },
    # Disable Windows Copilot
    @{
        Path  = "Registry::HKEY_USERS\.DEFAULT\Software\Policies\Microsoft\Windows\WindowsCopilot"
        Name  = "TurnOffWindowsCopilot"
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
    }
)

foreach ($update in $registryUpdates) {
    Set-RegistryValue -Path $update.Path -Name $update.Name -Value $update.Value -Type $update.Type
}

# Copy icon and create shortcut
Start-BitsTransfer -Source "https://raw.githubusercontent.com/CU-CommunityApps/ct-az-templates/master/scripts/avd/ccss/signout.ico" -Destination "$env:windir\system32\signout.ico" -Verbose

# Create executable shortcut
$shell = New-Object -comObject WScript.Shell
$shortcut = $shell.CreateShortcut("$env:public\desktop\Sign out.lnk")
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments =  "-Command `"logoff`""
$shortcut.IconLocation = "$env:windir\system32\signout.ico"
$shortcut.WindowStyle = 7
$shortcut.Save()

# Stop the transcript  
Stop-Transcript