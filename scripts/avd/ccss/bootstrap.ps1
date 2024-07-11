[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12  
  
# Define the log file path  
$logFile = "C:\bootstrap.log"  
  
# Start logging everything to the transcript file  
Start-Transcript -Path $logFile -Append
    
# Install NuGet  
try {  
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Verbose
    Write-Output "NuGet installed successfully."  
} catch {  
    Write-Output "Failed to install NuGet: $_"  
}  
  
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

# Install Basic WinGet Packages
# Locate winget.exe
try {
    $winget = (Resolve-Path "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe").Path + "\winget.exe"
} catch {
    Write-Output "Failed to find winget.exe: $_"
}

# Function to install a WinGet package and log results  
function Install-WinGetPackage {  
    param (  
        [string]$packageId  
    )  
    try {  
        Write-Output "Installing package $packageId..."  
        $winget install -e --id $packageId --accept-source-agreements --accept-package-agreements --scope 'machine' --verbose-logs  
        Write-Output "Installed package $packageId successfully."  
    } catch {  
        Write-Output "Failed to install package ${packageId}: $_"  
    }  
}  

# List of WinGet package IDs  
$packages = @(  
    "Microsoft.WindowsAppRuntime.1.5",  
    "mcmilk.7zip-zstd",  
    "Notepad++.Notepad++",  
    "Git.Git",  
    "GitHub.GitLFS",  
    "Python.Python.3.12",  
    "TeXstudio.TeXstudio",  
    "TortoiseSVN.TortoiseSVN"  
)  

# Loop through each package and install it  
foreach ($package in $packages) {  
    Install-WinGetPackage -packageId $package  
}

# Remove Windows Bloatware
##Get appx Packages
$Packages = Get-AppxPackage

##Create Your allowlist
$AllowList = @(
    '*WindowsCalculator*',
    '*Office.OneNote*',
    '*Microsoft.net*',
    '*MicrosoftEdge*',
    '*WindowsStore*',
    '*WindowsTerminal*',
    '*WindowsNotepad*',
    '*Paint*',
    '*Microsoft.PowerAutomateDesktop*',
    '*Microsoft.CompanyPortal*',
    '*Microsoft.WindowsMaps*',
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

# Stop the transcript  
Stop-Transcript 