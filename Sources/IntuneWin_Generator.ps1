#========================================================================
#
# Author 	: systanddeploy (Damien VAN ROBAEYS)
# Website	: http://www.systanddeploy.com/
#
#========================================================================

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.Application]::EnableVisualStyles()

# $Run_As_Admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
# If($Run_As_Admin -eq $False)
	# {
		# [System.Windows.Forms.MessageBox]::Show("Please run the tool with admin rights")
		# break		
	# }


$Global:Current_Folder = split-path $MyInvocation.MyCommand.Path

[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom("$Current_Folder\MahApps.Metro.dll") | out-null  
[System.Reflection.Assembly]::LoadFrom("$Current_Folder\MahApps.Metro.IconPacks.dll") | out-null  

#########################################################################
#                        Load Main Panel                                #
#########################################################################

$Global:pathPanel= split-path -parent $MyInvocation.MyCommand.Definition
$Global:Current_Folder = split-path $MyInvocation.MyCommand.Path

function LoadXaml ($filename){
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}


$XamlMainWindow=LoadXaml($pathPanel+"\IntuneWin_Generator.xaml")
$reader = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form = [Windows.Markup.XamlReader]::Load($reader)


$browse_package_folder = $Form.FindName("browse_package_folder") 
$Change_Theme = $Form.FindName("Change_Theme") 
$browse_package_folder_textbox = $Form.FindName("browse_package_folder_textbox") 
$file_to_run = $Form.FindName("file_to_run") 
$browse_output = $Form.FindName("browse_output") 
$browse_output_txtbox = $Form.FindName("browse_output_txtbox") 
$build = $Form.FindName("build") 
$package_name = $Form.FindName("package_name") 



$browse_intunewin = $Form.FindName("browse_intunewin") 
$intunewin_sources_textbox = $Form.FindName("intunewin_sources_textbox") 
$browse_output_intunewin = $Form.FindName("browse_output_intunewin") 
$browse_output_txtbox_inunewin = $Form.FindName("browse_output_txtbox_inunewin") 
$extract = $Form.FindName("extract") 


$browse_output_txtbox.IsEnabled = $False
$intunewin_sources_textbox.IsEnabled = $False
$browse_output_txtbox_inunewin.IsEnabled = $False

$object = New-Object -comObject Shell.Application  

	
#===========================================================================
# Declare the change_theme button and action on this button
#===========================================================================
$Change_Theme = $Form.FindName("Change_Theme")
$Change_Theme.Add_Click({
	$Theme = [MahApps.Metro.ThemeManager]::DetectAppStyle($form)	
	$my_theme = ($Theme.Item1).name
	If($my_theme -eq "BaseLight")
		{			
			[MahApps.Metro.ThemeManager]::ChangeAppStyle($form, $Theme.Item2, [MahApps.Metro.ThemeManager]::GetAppTheme("BaseDark"));								
		}
	ElseIf($my_theme -eq "BaseDark")
		{								
			[MahApps.Metro.ThemeManager]::ChangeAppStyle($form, $Theme.Item2, [MahApps.Metro.ThemeManager]::GetAppTheme("BaseLight"));			
		}		
})	
#===========================================================================
# Declare the change_theme button and action on this button
#===========================================================================




$browse_package_folder.Add_Click({		
	$folder = $object.BrowseForFolder(0, $message, 0, 0) 
	If ($folder -ne $null) 
		{ 		
			$Global:Sources_Folder = $folder.self.Path 
			$browse_package_folder_textbox.Text = $Sources_Folder	

			$Script:Folder_name = Split-Path -leaf -path $Sources_Folder			
										
			$Dir_Sources_Folder = get-childitem $Sources_Folder -recurse
			$List_All_Files = $Dir_Sources_Folder | where { ! $_.PSIsContainer }			
			foreach ($File in $List_All_Files)
				{
					$file_to_run.Items.Add($File)	
					$Script:Intunewin_File_To_Run = $file_to_run.SelectedItem	
					$Script:File_Full_Path = $File.FullName					
				}	
			$Global:File_Path = "$Sources_Folder\$Intunewin_File_To_Run"
				
			$file_to_run.add_SelectionChanged({
				$Script:Intunewin_File_To_Run = $file_to_run.SelectedItem
				$Global:File_Path = "$Sources_Folder\$Intunewin_File_To_Run"
			})	
		}
})	




$browse_output.Add_Click({		
	$output_folder = $object.BrowseForFolder(0, $message, 0, 0) 
	If ($output_folder -ne $null) 
		{ 		
			$Script:Package_output_folder = $output_folder.self.Path 
			$browse_output_txtbox.Text = $Package_output_folder	

			$Script:Folder_name = Split-Path -leaf -path $Package_output_folder			
		}
})	


$browse_intunewin.Add_Click({
	$File_Dialog = New-Object System.Windows.Forms.OpenFileDialog
	$File_Dialog.Filter = "Intunewin File (.intunewin)|*.intunewin"
	$File_Dialog.title = "Choose the intunewin file"	
	$File_Dialog.ShowHelp = $True	
	$File_Dialog.initialDirectory = [Environment]::GetFolderPath("Desktop")
	$File_Dialog.ShowDialog() | Out-Null
		
	$Script:Intunewin_Full_path = $File_Dialog.filename	
	$intunewin_sources_textbox.Text = $Intunewin_Full_path
})

$browse_output_intunewin.Add_Click({
	Add-Type -AssemblyName System.Windows.Forms
	$Folder_Object = New-Object System.Windows.Forms.FolderBrowserDialog
	[void]$Folder_Object.ShowDialog()	
	$Script:Extract_File_path = $Folder_Object.SelectedPath	
	$browse_output_txtbox_inunewin.Text = $Extract_File_path	
})


$extract.add_Click({
	& .\IntuneWinAppUtilDecoder.exe $Intunewin_Full_path -s	
	$Intunewin_Extract_Directory = (get-item $Intunewin_Full_path).Directory	
	$IntuneWin_File_Name = (get-item $Intunewin_Full_path).Name		
	$IntuneWinDecoded_File_Name = "$Intunewin_Extract_Directory\$IntuneWin_File_Name.decoded"	
	
	$IntuneWin_Rename = "$IntuneWin_File_Name.zip"
	Rename-Item $IntuneWinDecoded_File_Name $IntuneWin_Rename -force
	
	Expand-Archive -LiteralPath "$Intunewin_Extract_Directory\$IntuneWin_Rename" -DestinationPath $Extract_File_path -Force
	
	Remove-Item "$Intunewin_Extract_Directory\$IntuneWin_Rename" -force
	invoke-item $Extract_File_path
	
	[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Intunewin extraction","Your intunewin package has been correctly extracted")

})





$build.add_Click({
    Start-Process -WindowStyle hidden -FilePath "$Current_Folder\IntuneWinAppUtil.exe" -ArgumentList "-c `"$($Sources_Folder)`" -s `"$($Intunewin_File_To_Run)`" -o `"$($Package_output_folder)`" -q" -Wait
	$PackageNewName = $package_name.Text.ToString()
	If($PackageNewName -ne "")
		{
			$Get_File_ShortName = (get-item $File_Path).BaseName			
			$IntuneWin_FileToRename = "$Package_output_folder\$Get_File_ShortName.intunewin"
			$Intunewin_NewName = "$PackageNewName.intunewin"
			Rename-Item $IntuneWin_FileToRename $Intunewin_NewName -Force			
		}
	[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Intunewin creation","Your intunewin package has been correctly created")
})







$Form.ShowDialog() | Out-Null