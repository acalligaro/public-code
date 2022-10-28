$path = 'C:\ProgramData\AutoPilotConfig\W10BloatwareCleanup'
if (!(Test-Path 'C:\ProgramData\AutoPilotConfig')) { New-Item 'C:\ProgramData\AutoPilotConfig' -ItemType Directory }
if (!(Test-Path $path )) { New-Item $path -ItemType Directory }

Set-Content -Path "$path\W10BloatwareCleanup.tag" -Value 'Start' -Force

# Start logging
Start-Transcript "$path\W10BloatwareCleanup.log"

#region Appx

# List of built-in apps to remove
$UninstallPackages = @(
    'Microsoft.Getstarted'
    'Microsoft.GetHelp'
    'Microsoft.Getstarted'
    'Microsoft.Microsoft3DViewer'
    #"Microsoft.MicrosoftOfficeHub"
    'Microsoft.MicrosoftSolitaireCollection'
    'Microsoft.MixedReality.Portal'
    'Microsoft.Office.OneNote'
    'Microsoft.Office.Todo.List'
    'Microsoft.OneConnect'
    'Microsoft.MicrosoftOfficeHub'
    'Microsoft.SkypeApp'
    'Microsoft.WindowsFeedbackHub'
    'Microsoft.Xbox.TCUI'
    'Microsoft.XboxApp'
    'Microsoft.XboxGameOverlay'
    'Microsoft.XboxGamingOverlay'
    'Microsoft.XboxGameCallableUI'
    'Microsoft.XboxIdentityProvider'
    'Microsoft.XboxSpeechToTextOverlay'
    'Microsoft.YourPhone'
    'Microsoft.ZuneMusic'
    'Microsoft.ZuneVideo'
    'Microsoft.People'
    'Microsoft.Print3D'
    'Microsoft.WindowsMaps'
    'Microsoft.GamingApp'


)

# List of programs to uninstall
$UninstallPrograms = @(
)

$InstalledPackages = Get-AppxPackage -AllUsers | Where-Object { ($UninstallPackages -contains $_.Name) }

$ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object { ($UninstallPackages -contains $_.DisplayName) }

$InstalledPrograms = Get-Package | Where-Object { $UninstallPrograms -contains $_.Name }

# Remove provisioned packages first
ForEach ($ProvPackage in $ProvisionedPackages) {

    Write-Host -Object "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."

    Try {
        $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
        Write-Host -Object "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
    }
    Catch { Write-Warning -Message "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]" }
}

# Remove appx packages
ForEach ($AppxPackage in $InstalledPackages) {
                                            
    Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."

    Try {
        if (Get-AppxPackage $AppxPackage -AllUsers) {
            Write-Host -Object "-Package [$($AppxPackage.Name)] is installed, removing ..."
            $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
        }
    }
    Catch { Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]" }
}

# Remove installed programs
$InstalledPrograms | ForEach-Object {

    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."

    Try {
        $Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
    }
    Catch { Write-Warning -Message "Failed to uninstall: [$($_.Name)]" }
}

#endregion Appx

#Disables Windows Feedback Experience
Write-Host 'Disabling Windows Feedback Experience program'
$Advertising = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
If (Test-Path $Advertising) {
    Set-ItemProperty $Advertising Enabled -Value 0 
}
      
#Prevents bloatware applications from returning and removes Start Menu suggestions               
Write-Host 'Adding Registry key to prevent bloatware apps from returning'
$registryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
$registryOEM = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
If (!(Test-Path $registryPath)) { 
    New-Item $registryPath
}
Set-ItemProperty $registryPath DisableWindowsConsumerFeatures -Value 1 

If (!(Test-Path $registryOEM)) {
    New-Item $registryOEM
}
Set-ItemProperty $registryOEM ContentDeliveryAllowed -Value 0 
Set-ItemProperty $registryOEM OemPreInstalledAppsEnabled -Value 0 
Set-ItemProperty $registryOEM PreInstalledAppsEnabled -Value 0 
Set-ItemProperty $registryOEM PreInstalledAppsEverEnabled -Value 0 
Set-ItemProperty $registryOEM SilentInstalledAppsEnabled -Value 0 
Set-ItemProperty $registryOEM SystemPaneSuggestionsEnabled -Value 0    


#Removes 3D Objects from the 'My Computer' submenu in explorer
Write-Host "Removing 3D Objects from explorer 'My Computer' submenu"
$Objects32 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}'
$Objects64 = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}'
If (Test-Path $Objects32) {
    Remove-Item $Objects32 -Recurse 
}
If (Test-Path $Objects64) {
    Remove-Item $Objects64 -Recurse 
}



############################################################################################################
#                                        Remove Scheduled Tasks                                            #
#                                                                                                          #
############################################################################################################


#Disables scheduled tasks that are considered unnecessary 
Write-Host 'Disabling scheduled tasks'
$task1 = Get-ScheduledTask -TaskName XblGameSaveTaskLogon -ErrorAction SilentlyContinue
if ($null -ne $task1) {
    Get-ScheduledTask XblGameSaveTaskLogon | Disable-ScheduledTask -ErrorAction SilentlyContinue
}
$task2 = Get-ScheduledTask -TaskName XblGameSaveTask -ErrorAction SilentlyContinue
if ($null -ne $task2) {
    Get-ScheduledTask XblGameSaveTask | Disable-ScheduledTask -ErrorAction SilentlyContinue
}
$task3 = Get-ScheduledTask -TaskName Consolidator -ErrorAction SilentlyContinue
if ($null -ne $task3) {
    Get-ScheduledTask Consolidator | Disable-ScheduledTask -ErrorAction SilentlyContinue
}
$task4 = Get-ScheduledTask -TaskName UsbCeip -ErrorAction SilentlyContinue
if ($null -ne $task4) {
    Get-ScheduledTask UsbCeip | Disable-ScheduledTask -ErrorAction SilentlyContinue
}
   
Stop-Transcript
Set-Content -Path "$path\W10BloatwareCleanup.tag" -Value 'Success' -Force