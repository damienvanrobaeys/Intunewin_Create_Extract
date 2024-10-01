#***************************************************************************************************************
# Author: Damien VAN ROBAEYS
# Website: http://www.systanddeploy.com
# Twitter: https://twitter.com/syst_and_deploy
#***************************************************************************************************************
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null

$Current_Folder = split-path $MyInvocation.MyCommand.Path
$Sources = $Current_Folder + "\" + "Sources\*"
If(test-path $Sources)
	{	
		$Destination_folder = "$env:LOCALAPPDATA\Intunewin_Build_Extract"

		If(test-path $Destination_folder){remove-item $Destination_folder -recurse -force | out-null}
		new-item $Destination_folder -type directory -force | out-null
		copy-item $Sources $Destination_folder -force -recurse
		
		$IntuneWinAppUtil_Link =  "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe"
		$IntuneWinAppUtil_File = "$Destination_folder\IntuneWinAppUtil.exe"
		Invoke-WebRequest -Uri $IntuneWinAppUtil_Link -OutFile $IntuneWinAppUtil_File -UseBasicParsing | out-null

		$Decode_Link = "https://github.com/okieselbach/Intune/raw/master/IntuneWinAppUtilDecoder/IntuneWinAppUtilDecoder/bin/Release/IntuneWinAppUtilDecoder.exe"
		$DecodeApp_File = "$Destination_folder\IntuneWinAppUtilDecoder.exe"
		Invoke-WebRequest -Uri $Decode_Link -OutFile $DecodeApp_File -UseBasicParsing | out-null
		
		Get-Childitem -Recurse $Destination_folder | Unblock-file	
		
		# Creatre the LNK file
		$LNK_File = "$Destination_folder\Intunewin Build and Extract.lnk"
		$WshShell = New-Object -comObject WScript.Shell
		$Shortcut = $WshShell.CreateShortcut("$LNK_File")
		$Target_Path = "C:\Windows\System32\cmd.exe"
		$Target_Arguments = "/c start /min powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File %LOCALAPPDATA%\Intunewin_Build_Extract\IntuneWin_Generator.ps1"
		$Shortcut.TargetPath = $Target_Path
		$Shortcut.Arguments = $Target_Arguments
		$shortcut.IconLocation = "$Destination_folder\logo.ico"
		$shortcut.WorkingDirectory = $Destination_folder		
		$Shortcut.Save()		

		$Get_Desktop_Profile = [environment]::GetFolderPath('Desktop')
		copy-item $LNK_File $Get_Desktop_Profile -Force

		[System.Windows.Forms.MessageBox]::Show("Intunewin Build and Extract has been installed`n`nA shortcut has been added on your Desktop")			
	}
Else
	{
		[System.Windows.Forms.MessageBox]::Show("It seems you don't have dowloaded all the folder structure.`nThe folder Sources is missing !!!")	
	}



