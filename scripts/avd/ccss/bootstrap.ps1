[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install NuGet
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Install WinGet
Install-Module -Name Microsoft.WinGet.Client -Force
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe

# Reset Windows Terminal
Get-AppxPackage Microsoft.WindowsTerminal -AllUsers | Reset-AppPackage

# Reset profile session
. $profile

# Install Basic WinGet Packages
# Microsoft.WindowsAppRuntime.1.5
winget install -e --id Microsoft.WindowsAppRuntime.1.5 --accept-source-agreements --accept-package-agreements
# 7zip
winget install -e --id mcmilk.7zip-zstd --accept-source-agreements --accept-package-agreements
# Notepad++
winget install -e --id Notepad++.Notepad++ --accept-source-agreements --accept-package-agreements
# Git
winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
# Git LFS
winget install -e --id GitHub.GitLFS --accept-source-agreements --accept-package-agreements
# Python 3.12
winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
# TexStudio
winget install -e --id TeXstudio.TeXstudio --accept-source-agreements --accept-package-agreements
# TortoiseSVN
winget install -e --id TortoiseSVN.TortoiseSVN --accept-source-agreements --accept-package-agreements

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
        Get-AppxPackage -AllUsers -Name $App.Name -PackageTypeFilter Bundle | Remove-AppxPackage -AllUsers
    }
}
