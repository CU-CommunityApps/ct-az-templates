[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

param(
    [Parameter(Mandatory=$true)][string]$fsLogixVhdLocation,
    [Parameter(Mandatory=$true)][int]$SessionIdleTimeout,
    [Parameter(Mandatory=$true)][string]$ProjectShare,
    [Parameter(Mandatory=$true)][string]$DataShare
)
$ErrorActionPreference = 'Stop'

# Define the log file path  
$logFile = "C:\bootstrap.log"
  
# Start logging everything to the transcript file  
Start-Transcript -Path $logFile -Append

# Configure FSLogix and other settings
New-Item -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'VHDLocations' -Value "\\$fsLogixVhdLocation.file.core.windows.net\profiles" -Force

# Configure Cloud Kerberos
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters' -Name 'CloudKerberosTicketRetrievalEnabled' -Value 1 -Type DWord -Force

# Configure session timeout settings
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'MaxDisconnectionTime' -Value 86400000 -PropertyType DWord -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'MaxIdleTime' -Value $SessionIdleTimeout -PropertyType DWord -Force

# Map Azure File Shares at first user logon
reg load HKU\DefaultUser "C:\Users\Default\NTUSER.DAT"
reg add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v MapAzureFiles /t REG_SZ /d "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -Command "New-PSDrive -Name P -PSProvider FileSystem -Root "\\$ProjectShare.file.core.windows.net\project" -Persist;New-PSDrive -Name R -PSProvider FileSystem -Root "\\$DataShare.file.core.windows.net\data" -Persist"" /f
reg unload HKU\DefaultUser

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