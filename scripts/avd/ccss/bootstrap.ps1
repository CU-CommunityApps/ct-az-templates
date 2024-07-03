[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install NuGet
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Install WinGet
Install-Module -Name Microsoft.WinGet.Client -Force

# Reset Windows Terminal
Get-AppxPackage Microsoft.WindowsTerminal | Reset-AppPackage

# Reset profile session
. $profile

# Install Basic WinGet Packages
# 7zip
winget install -e --id mcmilk.7zip-zstd
# Notepad++
winget install -e --id Notepad++.Notepad++
# Git
winget install -e --id Git.Git
# Git LFS
winget install -e --id GitHub.GitLFS
# Python 3.12
winget install -e --id Python.Python.3.12

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
