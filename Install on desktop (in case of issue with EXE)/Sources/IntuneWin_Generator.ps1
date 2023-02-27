#========================================================================
#
# Author 	: systanddeploy (Damien VAN ROBAEYS)
# Website	: http://www.systanddeploy.com/
#
#========================================================================

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.Application]::EnableVisualStyles()

$Global:Current_Folder = split-path $MyInvocation.MyCommand.Path

[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom("$Current_Folder\MahApps.Metro.dll") | out-null  
[System.Reflection.Assembly]::LoadFrom("$Current_Folder\MahApps.Metro.IconPacks.dll") | out-null  
[System.Reflection.Assembly]::LoadFrom("$Current_Folder\LoadingIndicators.WPF.dll") | out-null

$Global:pathPanel= split-path -parent $MyInvocation.MyCommand.Definition

function LoadXaml ($filename){
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}

$XamlMainWindow=LoadXaml($pathPanel+"\IntuneWin_Generator.xaml")
$reader = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form = [Windows.Markup.XamlReader]::Load($reader)

$XamlMainWindow.SelectNodes("//*[@Name]") | %{
    try {Set-Variable -Name "$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop}
    catch{throw}
}


#*******************************************************************************************************************************************************************************************************
#																						 BARRE DE PROGRESSION
#*******************************************************************************************************************************************************************************************************

$syncProgress = [hashtable]::Synchronized(@{})
$childRunspace = [runspacefactory]::CreateRunspace()
$childRunspace.ApartmentState = "STA"
$childRunspace.ThreadOptions = "ReuseThread"         
$childRunspace.Open()
$childRunspace.SessionStateProxy.SetVariable("syncProgress",$syncProgress)          
$PsChildCmd = [PowerShell]::Create().AddScript({   
    [xml]$xaml = @"
	<Controls:MetroWindow 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		xmlns:i="http://schemas.microsoft.com/expression/2010/interactivity"				
		xmlns:Controls="clr-namespace:MahApps.Metro.Controls;assembly=MahApps.Metro"	
		xmlns:loadin="clr-namespace:LoadingIndicators.WPF;assembly=LoadingIndicators.WPF"				
        Name="WindowProgress" 
		WindowStyle="None" AllowsTransparency="True" UseNoneWindowStyle="True"	
		Width="600" Height="300" 
		WindowStartupLocation ="CenterScreen" Topmost="true"
		BorderBrush="Gray" ResizeMode="NoResize"
		>

<Window.Resources>
	<ResourceDictionary>
		<ResourceDictionary.MergedDictionaries>
			<!-- LoadingIndicators resources -->
			<ResourceDictionary Source="pack://application:,,,/LoadingIndicators.WPF;component/Styles.xaml"/>	
			<!-- Mahapps resources -->
			<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Controls.xaml" />
			<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Fonts.xaml" />
			<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Colors.xaml" />
			<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Accents/Cobalt.xaml" />
			<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Accents/BaseDark.xaml" />		
		</ResourceDictionary.MergedDictionaries>
	</ResourceDictionary>
</Window.Resources>			

	<Window.Background>
		<SolidColorBrush Opacity="0.7" Color="#0077D6"/>
	</Window.Background>	
		
	<Grid>	
		<StackPanel Orientation="Vertical" VerticalAlignment="Center" HorizontalAlignment="Center">		
			<StackPanel Orientation="Vertical" HorizontalAlignment="Center" Margin="0,0,0,0">	
			<!--	<Controls:ProgressRing IsActive="True" Margin="0,0,0,0"  Foreground="White" Width="50"/> -->
				<loadin:LoadingIndicator Margin="0,5,0,0" Name="ArcsRing" SpeedRatio="1" Foreground="White" IsActive="True" Style="{DynamicResource LoadingIndicatorArcsRingStyle}"/>
			</StackPanel>								
			
			<StackPanel Orientation="Vertical" HorizontalAlignment="Center" Margin="0,20,0,0">				
				<Label Name="ProgressStep" Content="Getting latest IntuneWinAppUtil.exe version" FontSize="17" Margin="0,0,0,0" Foreground="White"/>	
				<Label HorizontalAlignment="Center" Content="Please wait ..." FontSize="17" Margin="0,0,0,0" Foreground="White"/>	

			</StackPanel>			
		</StackPanel>		
		
	</Grid>
</Controls:MetroWindow>
"@
  
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    $syncProgress.Window=[Windows.Markup.XamlReader]::Load( $reader )
    $syncProgress.Label = $syncProgress.window.FindName("ProgressStep")	

    $syncProgress.Window.ShowDialog() #| Out-Null
    $syncProgress.Error = $Error
})



################ Launch Progress Bar  ########################  
Function Launch_modal_progress{    
    $PsChildCmd.Runspace = $childRunspace
    $Script:Childproc = $PsChildCmd.BeginInvoke()
	
}

################ Close Progress Bar  ########################  
Function Close_modal_progress{
    $syncProgress.Window.Dispatcher.Invoke([action]{$syncProgress.Window.close()})
    $PsChildCmd.EndInvoke($Script:Childproc) | Out-Null
}


$browse_output_txtbox.IsEnabled = $False
$intunewin_sources_textbox.IsEnabled = $False
$browse_output_txtbox_inunewin.IsEnabled = $False

$object = New-Object -comObject Shell.Application  

# Launch_modal_progress

$IntuneWin_Folder = "$env:LOCALAPPDATA\Intunewin_Build_Extract"
$IntuneWinAppUtil_File = "$IntuneWin_Folder\IntuneWinAppUtil.exe"
$IntuneWinAppUtilDecoder = "$IntuneWin_Folder\IntuneWinAppUtilDecoder.exe"
$IntuneWin_Ver = "IntuneWinAppUtil: " + [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$IntuneWinAppUtil_File").FileVersion
$IntuneWinDecoder_Ver = "Decoder: " + [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$IntuneWinAppUtilDecoder").FileVersion
$IntuneWinApp_Ver.Content = $IntuneWin_Ver + " / " + $IntuneWinDecoder_Ver

# Close_modal_progress

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


$build.add_Click({

    Start-Process -WindowStyle hidden -FilePath $IntuneWinAppUtil_File -ArgumentList "-c `"$($Sources_Folder)`" -s `"$($Intunewin_File_To_Run)`" -o `"$($Package_output_folder)`" -q" -Wait
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

$extract.add_Click({
	& .\IntuneWinAppUtilDecoder.exe $Intunewin_Full_path -s	
	$Intunewin_Extract_Directory = (get-item $Intunewin_Full_path).Directory	
	$IntuneWin_File_Name = (get-item $Intunewin_Full_path).BaseName		
	$IntuneWinDecoded_File = "$Intunewin_Extract_Directory\$IntuneWin_File_Name.decoded.zip"	

	Expand-Archive -LiteralPath $IntuneWinDecoded_File -DestinationPath $Extract_File_path -Force
	
	Remove-Item $IntuneWinDecoded_File
	invoke-item $Extract_File_path
	
	[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Intunewin extraction","Your intunewin package has been correctly extracted")

})

$Download.Add_Click({
	$IntuneWinAppUtil_Link =  "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe"
	$IntuneWinAppUtil_File = "$IntuneWin_Folder\IntuneWinAppUtil.exe"
	Invoke-WebRequest -Uri $IntuneWinAppUtil_Link -OutFile $IntuneWinAppUtil_File -UseBasicParsing | out-null
	
	$Decode_Link = "https://github.com/okieselbach/Intune/raw/master/IntuneWinAppUtilDecoder/IntuneWinAppUtilDecoder/bin/Release/IntuneWinAppUtilDecoder.exe"
	$DecodeApp_File = "$IntuneWin_Folder\IntuneWinAppUtilDecoder.exe"
	Invoke-WebRequest -Uri $Decode_Link -OutFile $DecodeApp_File -UseBasicParsing | out-null
	
	Get-Childitem $IntuneWin_Folder -Recurse | Unblock-File

	$IntuneWin_Folder = "$env:LOCALAPPDATA\Intunewin_Build_Extract"
	$IntuneWinAppUtil_File = "$IntuneWin_Folder\IntuneWinAppUtil.exe"
	$IntuneWinAppUtilDecoder = "$IntuneWin_Folder\IntuneWinAppUtilDecoder.exe"
	$IntuneWin_Ver = "IntuneWinAppUtil: " + [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$IntuneWinAppUtil_File").FileVersion
	$IntuneWinDecoder_Ver = "Decoder: " + [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$IntuneWinAppUtilDecoder").FileVersion
	$IntuneWinApp_Ver.Content = $IntuneWin_Ver + " / " + $IntuneWinDecoder_Ver	
})

$Form.ShowDialog() | Out-Null