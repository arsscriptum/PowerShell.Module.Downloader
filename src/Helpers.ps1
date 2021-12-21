
<#
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

#===============================================================================
# ChannelProperties
#===============================================================================

class ChannelProperties
{
    #ChannelProperties
    [string]$Channel = 'BITSADMIN'
    [ConsoleColor]$TitleColor = 'Blue'
    [ConsoleColor]$MessageColor = 'DarkGray'
    [ConsoleColor]$ErrorColor = 'DarkRed'
    [ConsoleColor]$SuccessColor = 'DarkGreen'
    [ConsoleColor]$ErrorDescriptionColor = 'DarkYellow'
}
$Global:ChannelProps = [ChannelProperties]::new()


function Write-ChannelMessage{               # NOEXPORT   
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Message,
        [Parameter(Mandatory=$false,Position=1)]
        [string]$Optional
    )

    Write-Host "[$($Global:ChannelProps.Channel)] " -f $($Global:ChannelProps.TitleColor) -NoNewLine
    if($PSBoundParameters.ContainsKey('Optional')){
        Write-Host "$Message" -f $($Global:ChannelProps.MessageColor) -NoNewLine
        Write-Host "$Optional" -f $($Global:ChannelProps.SuccessColor)
    }else{
        Write-Host "$Message" -f $($Global:ChannelProps.MessageColor)
    }
}


function Write-ChannelResult{                        # NOEXPORT        
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Message,
        [switch]$Warning
    )

    if($Warning -eq $False){
        Write-Host "[$($Global:ChannelProps.Channel)] " -f $($Global:ChannelProps.TitleColor) -NoNewLine
        Write-Host "[ OK ] " -f $($Global:ChannelProps.SuccessColor) -NoNewLine
    }else{
        Write-Host "[WARN] " -f $($Global:ChannelProps.ErrorColor) -NoNewLine
    }
    
    Write-Host "$Message" -f $($Global:ChannelProps.MessageColor)
}



function Write-ChannelError{                # NOEXPORT                 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$Record
    )
    $formatstring = "{0}`n{1}"
    $fields = $Record.FullyQualifiedErrorId,$Record.Exception.ToString()
    $ExceptMsg=($formatstring -f $fields)
    Write-Host "[$($Global:ChannelProps.Channel)] " -f $($Global:ChannelProps.TitleColor) -NoNewLine
    Write-Host "[ERROR] " -f $($Global:ChannelProps.ErrorColor) -NoNewLine
    Write-Host "$ExceptMsg`n`n" -ForegroundColor DarkYellow
}

function Get-DefaultDownloadPath{                         # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $ModuleName = $ExecutionContext.SessionState.Module
    $RegPath = "$ENV:OrganizationHKCU\$ModuleName"
    $RegKeyName = 'DefaultDownloadPath'
    $Result =(Get-ItemProperty -Path $RegPath -Name $RegKeyName).DefaultDownloadPath
    return $Result
}


function Get-NotifierAppPath{                         # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $ModuleName = $ExecutionContext.SessionState.Module
    $RegPath = "$ENV:OrganizationHKCU\$ModuleName"
    $RegKeyName = 'NotificationAppPath'
    $Result = (Get-ItemProperty -Path $RegPath -Name $RegKeyName).NotificationAppPath
    return $Result
}


function New-DownloadJobEntry{                        # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param (
     [parameter(Position=0,Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [string]$Id,
     [parameter(Position=1,Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [string]$Name,
     [parameter(Position=2,Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [string]$Url,
     [parameter(Position=3,Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [string]$Status,     
     [parameter(Position=4,Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [string]$Notifier,
     [parameter(Position=5,Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [string]$DestinationPath,
     [parameter(Position=6,Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [string]$Priority,
     [parameter(Position=7,Mandatory=$false)]
     [ValidateNotNullOrEmpty()]
     [long]$FilesTransfered=0,
     [parameter(Position=8,Mandatory=$false)]
     [ValidateNotNullOrEmpty()]
     [long]$TotalFiles=0,
     [parameter(Position=9,Mandatory=$false)]
     [ValidateNotNullOrEmpty()]
     [long]$BytesTransfered=0,
     [parameter(Position=10,Mandatory=$false)]
     [ValidateNotNullOrEmpty()]
     [long]$TotalBytes=0                 
    )  
    $Job = [PSCustomObject]@{
                ID                = $Id
                Name              = $Name
                Url               = $Url
                Status            = $Status
                FilesTransfered     = $FilesTransfered
                TotalFiles          = $TotalFiles
                BytesTransfered     = $BytesTransfered
                TotalBytes          = $TotalBytes
                Priority             = $Priority
                Notifier          = $Notifier
                DestinationPath   = $DestinationPath
    }
 
    return $Job
}

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
        Write-ResultMessage "DefaultDownloadPath $DestinationPath"
        $null = New-ItemProperty -Path $RegPath -Name 'NotificationAppPath' -Value "$NotifierPath" -Force
        Write-ResultMessage "NotificationAppPath $NotificationAppPath"
        $null = New-ItemProperty -Path $RegPath -Name 'Initialized' -Value 1 -Force
        Write-ResultMessage "Initialized $Initialized"
       
        Write-Message "Setup Completed, exiting."
    }catch{
        write-error($_)
    }
}

