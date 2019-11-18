
###############################
##         HELPERS           ##
###############################
Function Enable-Autologon{
Param(
     [Parameter(Mandatory=$False )]
     [String] $LogonCount,
     [Parameter(Mandatory=$False)]
     [string] $AutostartScript,
     [Parameter(Mandatory=$False)]
     [string] $RunOnceautostartScript,
     [Parameter(Mandatory=$False )]
     [Switch] $Admin=$true
     )

     # by Andreas Nick https://www.software-virtualisierung.de/powershell/powershell-enable-and-disable-windows-autologon-with-automatic-generated-password.html
     $AutoLogonUser = "AutoLogonUser"
     $Autologon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
     $RunKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
     $RunOnce= "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\";

     #DeleteAutologonUser if exist    
     Get-LocalUser -Name $AutoLogonUser -ErrorAction SilentlyContinue | Remove-LocalUser

     #Create Autostart Useraccount
     [String] $Password = 'A'+ $(Get-Random -Maximum 9999999999999 -Minimum 1000000000000)
     [String] $Password+='$1'
     $SecPwd = ConvertTo-SecureString $Password -AsPlainText -Force
     New-LocalUser $AutoLogonUser -FullName $AutoLogonUser -Password $SecPwd 

     # Add to Administrtors 
     if ($admin){
         Add-LocalGroupMember -Name (Get-LocalGroup administ*).Name -Member $AutoLogonUser
     }

     #Enable Autologin
     If( $LogonCount){ Set-ItemProperty $Autologon "AutoLogonCount" -Value "$LogonCount" -type dword -Force } else {
         Set-ItemProperty $Autologon "AutoLogonCount" -Value "1" -type dword
     }

     #RunKey Script
     if($autostartScript){ Set-ItemProperty $RunKey "(Default)" -Value "$autostartScript" -type string }

     #RunOnceKey
     if($RunOnceautostartScript){ Set-ItemProperty $RunOnce "(Default)" -Value "$RunOnceautostartScript" -type string -Force }

     #Enable Autologon
     Set-ItemProperty $Autologon "AutoAdminLogon" -Value "1" -Type string
     Set-ItemProperty $Autologon "DefaultUsername" -Value $($env:COMPUTERNAME+'\'+$AutoLogonUser) -Type string
     Set-ItemProperty $Autologon "DefaultPassword" -Value $Password -Type string
}


Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

###############################
##         FUNCTIONS         ##
###############################
function extract {
	echo "Extracting update package"
	Unzip "C:\Win7-*.zip" "C:\Win7\"
}

function disableUAC {
	# disable UAC
	echo "Diable UAC"
	New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force
}

function disableFW {
	# disable firewall
	echo "Disable firewall"
	#Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
	netsh advfirewall set allprofiles state off
}

function leaveDom {
	# leave domain
	echo "Leaving Domain"
	#Remove-Computer -credential domain64\admin64 -passthru -verbose
	#by Rems https://www.petri.com/forums/forum/windows-scripting/general-scripting/66141-remove-pc-from-domain-without-being-connected-to-dc
	wmic.exe /interactive:off ComputerSystem Where "Name='$env:computername'" Call UnJoinDomainOrWorkgroup FUnjoinOptions=0
	wmic.exe /interactive:off ComputerSystem Where "Name='$env:computername'" Call JoinDomainOrWorkgroup name="WORKGROUP"
	wmic.exe /interactive:off ComputerSystem Where "Name='$env:computername'" Call Rename name="myPC1234"
}

function getAgent {
	# download cuckoo agent
	echo "Downloading Cuckoo Agent"
	$url = "https://raw.githubusercontent.com/cuckoosandbox/cuckoo/master/cuckoo/data/agent/agent.py"
	#$StartUp="$Env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
	$output = "C:\agent.py"

	$wc = New-Object System.Net.WebClient
	$wc.DownloadFile($url, $output)
}

function autoLogin {
	# auto login
	echo "Creating auto login user"
	Enable-Autologon -LogonCount 99999 -AutostartScript "C:\agent.py"
}

function autorunAgent {
	# autostart cuckoo agent
	echo "Autorun for agent"
	#$trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
	#echo "& C:\agent.py" > "C:\agent.ps1"
	#Register-ScheduledJob -Trigger $trigger -FilePath C:\agent.ps1 -Name StartCuckooAgent
	#get-job
	Copy-Item "C:\agent.py" -Destination "C:\Users\AutoLogonUser\"
}

function sysprep {
	C:\Windows\System32\sysprep\sysprep.exe /generalize /oobe /quiet /reboot
}

function setResolution {
	# set screen resolution
	echo "Set screen resolution"
	Set-DisplayResolution -Width 1280 -Height 1024 -Force
}

function startKillIexplore {
      $ie = New-Object -ComObject InternetExplorer.Application
      $ie.Visible = $true
      $ie.Navigate('about:blank')
      # sleep
      $ie.Quit()
}

function startKillApplication {
      $process = Start-Process "C:\Program Files (x86)\Internet Explorer\iexplore.exe" http://127.0.0.1 -PassThru
      # sleep
      $process.Kill()
}

function reboot {
	# reboot
	echo "reboot"
	restart-computer
}

###############################
##         ACTIONS           ##
###############################
$PSVersionTable.PSVersion
# https://github.com/PowerShell/PowerShell/releases
#extract
disableUAC
disableFW
leaveDom
#getAgent
#autoLogin # or manually via win+r autoplwiz
Enable-Autologon -LogonCount 99999 -AutostartScript "C:\startagent.bat"
#autorunAgent
#setResolution
#sysprep
reboot
