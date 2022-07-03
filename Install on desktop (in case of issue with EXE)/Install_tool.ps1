#***************************************************************************************************************
# Author: Damien VAN ROBAEYS
# Website: http://www.systanddeploy.com
# Twitter: https://twitter.com/syst_and_deploy
#***************************************************************************************************************
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null

$IntuneWinAppUtil_Link =  "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe"
Try
	{
		$IntuneWinAppUtil_File = "$env:temp\IntuneWinAppUtil.exe"
		Invoke-WebRequest -Uri $IntuneWinAppUtil_Link -OutFile $IntuneWinAppUtil_File -UseBasicParsing | out-null
		$Download_Status = $True
	}
Catch
	{
		$Download_Status = $False								
	}


$Current_Folder = split-path $MyInvocation.MyCommand.Path
$Sources = $Current_Folder + "\" + "Sources\*"
If(test-path $Sources)
	{	
		$ProgData = $env:ProgramData
		# $Destination_folder = "$ProgData\Intunewin_Build_Extract"
		$Destination_folder = "$env:LOCALAPPDATA\Intunewin_Build_Extract"

		If(test-path $Destination_folder){remove-item $Destination_folder -recurse -force | out-null}
		new-item $Destination_folder -type directory -force | out-null
		copy-item $Sources $Destination_folder -force -recurse
		copy-item $IntuneWinAppUtil_File $Destination_folder -force -recurse
		Get-Childitem -Recurse $Destination_folder | Unblock-file	
		
		$Get_Current_user = (gwmi win32_computersystem).username
		$Get_Current_user_Name = $Get_Current_user.Split("\")[1]		
		$User_Desktop_Profile = "C:\Users\$Get_Current_user_Name\Desktop"

		$Get_Tool_Shortcut = "$Destination_folder\Intunewin Build and Extract.lnk"		
		$Get_Desktop_Profile = [environment]::GetFolderPath('Desktop')
		$Desktop_LNK = "$Get_Desktop_Profile\Intunewin Build and Extract.lnk"
		copy-item $Get_Tool_Shortcut $Get_Desktop_Profile -Force
		
		$Shell = New-Object -ComObject ("WScript.Shell")
		$Shortcut = $Shell.CreateShortcut($Desktop_LNK)
		$shortcut.IconLocation = "$Destination_folder\logo.ico"
		$Shortcut.Save()
		
		[System.Windows.Forms.MessageBox]::Show("Intunewin Build and Extract has been installed`n`nA shortcut has been added on your Desktop")			
	}
Else
	{
		[System.Windows.Forms.MessageBox]::Show("It seems you don't have dowloaded all the folder structure.`nThe folder Sources is missing !!!")	
	}



