[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install NuGet
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Install WinGet
Install-Module -Name Microsoft.WinGet.Client -Force

# Reset Windows Terminal
Get-AppxPackage Microsoft.WindowsTerminal | Reset-AppPackage

