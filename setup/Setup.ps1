    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [string]$DestinationPath = '',   
        [Parameter(Mandatory=$false)]
        [string]$NotifierPath = ''
    )


function Initialize-BITSModule{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [string]$DestinationPath = '',   
        [Parameter(Mandatory=$false)]
        [string]$NotifierPath = ''
    )

    try{

        if($DestinationPath -eq ""){
            $DestinationPath = [Environment]::GetFolderPath("DesktopDirectory")
            $DestinationPath = Join-Path $DestinationPath 'BITSADMIN_DOWNLOADS'
            New-Item -Path $DestinationPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null 
        }else{
            if(-Not ($DestinationPath | Test-Path) ){
                throw "Folder does not exist"
            }
            if(-Not ($DestinationPath | Test-Path -PathType Container) ){
                throw "The Path argument must be a Directory. Files paths are not allowed."
            }
        }

        if($NotifierPath -eq ""){
            $NotifierPath=(Get-Command 'DownloadCompleted.exe' -ErrorAction Ignore).Source
            if($NotifierPath -eq $Null){
                $NotifierPath = (Resolve-Path "$Script:CurrentPath\bin").Path
                $NotifierPath = Join-Path $NotifierPath 'DownloadCompleted.exe'
            }

            if(-not(Test-Path $NotifierPath -PathType Leaf)){
                write-Host "[WARNING] " -f DarkRed -NoNewLine
                write-Host "CANNOT FIND NOTIFIER APPLICATION" -f DarkYellow
                $NotifierPath = ''
            }
        }else{
            if(-Not ($NotifierPath | Test-Path) ){
                throw "Folder does not exist"
            }
            if(-Not ($NotifierPath | Test-Path -PathType Leaf) ){
                throw "The Path argument must be a File."
            }
        }        

        $ModuleName = $ExecutionContext.SessionState.Module
        $RegPath = "$ENV:OrganizationHKCU\$ModuleName"
        $Script:CurrentPath   = Split-Path $Script:MyInvocation.MyCommand.Path
  
        Write-Host "`n===============================================================================" -f DarkRed
        Write-Host "CONFIGURATION OF POWERSHELL MODULE $ModuleName" -f DarkYellow;
        Write-Host "===============================================================================" -f DarkRed    
        Write-Host "Download Path    `t" -NoNewLine -f DarkYellow ; Write-Host "$DestinationPath" -f Gray 
        Write-Host "Notification App `t" -NoNewLine -f DarkYellow;  Write-Host "$NotifierPath" -f Gray 
        Write-Host "===============================================================================`n" -f DarkRed

        $null = (New-Item $RegPath -Force).Name
        $null = New-ItemProperty -Path $RegPath -Name 'DefaultDownloadPath' -Value "$DestinationPath" -Force
        Write-ChannelResult "DefaultDownloadPath $DestinationPath"
        $null = New-ItemProperty -Path $RegPath -Name 'NotificationAppPath' -Value "$NotifierPath" -Force
        Write-ChannelResult "NotificationAppPath $NotifierPath"
        $null = New-ItemProperty -Path $RegPath -Name 'Initialized' -Value 1 -Force
        Write-ChannelResult "Initialized"
       
        Write-ChannelResult "Setup Completed, exiting."
    }catch{
        write-error($_)
    }
}


<#This will self elevate the script so with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    Write-Host " Launching in Admin mode" -f DarkRed
    Start-Process pwsh.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}
#>

$Script:CurrentPath=$PSScriptRoot


Write-Host "===============================================================================" -f DarkRed
Write-Host "SETUP of DOWNLOADMODULE" -f DarkYellow;
Write-Host "===============================================================================" -f DarkRed    
Write-Host "Current Path `t" -NoNewLine -f DarkYellow ; Write-Host "$Script:CurrentPath" -f Gray 
Write-Host "TermScript   `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:TermScript" -f Gray 
Write-Host "WhatIf       `t" -NoNewLine -f DarkYellow;  Write-Host "$WhatIf" -f Gray 
Write-Host "Uninstall    `t" -NoNewLine -f DarkYellow;  Write-Host "$Uninstall" -f Gray 
Write-Host "Path         `t" -NoNewLine -f DarkYellow;  Write-Host "$Path" -f Gray 
Write-Host "Mode         `t" -NoNewLine -f DarkYellow;  Write-Host "$Mode" -f Gray 



Write-Host "Starting configuration" -f DarkYellow
Initialize-BITSModule -DestinationPath $DestinationPath -NotifierPath $NotifierPath
Write-Host "DONE" -f DarkGreen
Set-DefaultDownloadPath 'C:\Data\Download'
Set-NotifierAppPath "$ENV:ToolsRoot\DownloadCompleted.exe"
Read-Host 'Install Completed, Press Any key...'
