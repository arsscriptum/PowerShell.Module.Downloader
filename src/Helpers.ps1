<#
  ╓──────────────────────────────────────────────────────────────────────────────────────
  ║   PowerShell Downloader Module
  ╙──────────────────────────────────────────────────────────────────────────────────────
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
$Script:ChannelProps = [ChannelProperties]::new()


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

function Get-DefaultDownloadPath{     
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $ModuleName = $ExecutionContext.SessionState.Module
    $RegPath = "$ENV:OrganizationHKCU\$ModuleName"
    $RegKeyName = 'DefaultDownloadPath'
    $Result =(Get-ItemProperty -Path $RegPath -Name $RegKeyName).DefaultDownloadPath
    return $Result
}
function Set-DefaultDownloadPath{        
    [CmdletBinding(SupportsShouldProcess)]
    param (
     [parameter(Position=0,Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [string]$Path
    )
    $ModuleName = $ExecutionContext.SessionState.Module
    $RegPath = "$ENV:OrganizationHKCU\$ModuleName"
    $RegKeyName = 'DefaultDownloadPath'
    $Result = New-RegistryValue -Path $RegPath -Name $RegKeyName -Value $Path -Type 'String'
    return $Result
}


function Set-NotifierAppPath{   
    [CmdletBinding(SupportsShouldProcess)]
    param (
     [parameter(Position=0,Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [string]$Path
    )

    $ModuleName = $ExecutionContext.SessionState.Module
    $RegPath = "$ENV:OrganizationHKCU\$ModuleName"
    $RegKeyName = 'NotificationAppPath'
    $Result='C:\Programs\SystemTools\Notifier.exe'
    $Result = New-RegistryValue -Path $RegPath -Name $RegKeyName -Value $Path -Type 'String'
    
    return $Result
}

function Get-NotifierAppPath{                         # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $ModuleName = $ExecutionContext.SessionState.Module
    $RegPath = "$ENV:OrganizationHKCU\$ModuleName"
    $RegKeyName = 'NotificationAppPath'
    $Result='C:\Programs\SystemTools\Notifier.exe'
    if(Test-RegistryValue -Path $RegPath -Entry $RegKeyName){
        $Result = Get-RegistryValue -Path $RegPath -Entry $RegKeyName   
    }
    
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


# SIG # Begin signature block
# MIIFxAYJKoZIhvcNAQcCoIIFtTCCBbECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmjITd4Bt/mw6QrjgGpjZ7D+K
# UNmgggNNMIIDSTCCAjWgAwIBAgIQmkSKRKW8Cb1IhBWj4NDm0TAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0yMjAyMDkyMzI4NDRaFw0zOTEyMzEyMzU5NTlaMCUxIzAhBgNVBAMTGkFyc1Nj
# cmlwdHVtIFBvd2VyU2hlbGwgQ1NDMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEA60ec8x1ehhllMQ4t+AX05JLoCa90P7LIqhn6Zcqr+kvLSYYp3sOJ3oVy
# hv0wUFZUIAJIahv5lS1aSY39CCNN+w47aKGI9uLTDmw22JmsanE9w4vrqKLwqp2K
# +jPn2tj5OFVilNbikqpbH5bbUINnKCDRPnBld1D+xoQs/iGKod3xhYuIdYze2Edr
# 5WWTKvTIEqcEobsuT/VlfglPxJW4MbHXRn16jS+KN3EFNHgKp4e1Px0bhVQvIb9V
# 3ODwC2drbaJ+f5PXkD1lX28VCQDhoAOjr02HUuipVedhjubfCmM33+LRoD7u6aEl
# KUUnbOnC3gVVIGcCXWsrgyvyjqM2WQIDAQABo3YwdDATBgNVHSUEDDAKBggrBgEF
# BQcDAzBdBgNVHQEEVjBUgBD8gBzCH4SdVIksYQ0DovzKoS4wLDEqMCgGA1UEAxMh
# UG93ZXJTaGVsbCBMb2NhbCBDZXJ0aWZpY2F0ZSBSb290ghABvvi0sAAYvk29NHWg
# Q1DUMAkGBSsOAwIdBQADggEBAI8+KceC8Pk+lL3s/ZY1v1ZO6jj9cKMYlMJqT0yT
# 3WEXZdb7MJ5gkDrWw1FoTg0pqz7m8l6RSWL74sFDeAUaOQEi/axV13vJ12sQm6Me
# 3QZHiiPzr/pSQ98qcDp9jR8iZorHZ5163TZue1cW8ZawZRhhtHJfD0Sy64kcmNN/
# 56TCroA75XdrSGjjg+gGevg0LoZg2jpYYhLipOFpWzAJqk/zt0K9xHRuoBUpvCze
# yrR9MljczZV0NWl3oVDu+pNQx1ALBt9h8YpikYHYrl8R5xt3rh9BuonabUZsTaw+
# xzzT9U9JMxNv05QeJHCgdCN3lobObv0IA6e/xTHkdlXTsdgxggHhMIIB3QIBATBA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdAIQ
# mkSKRKW8Cb1IhBWj4NDm0TAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAig
# AoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUPylrYkmt4QxqNotSMs1G
# e/itMo0wDQYJKoZIhvcNAQEBBQAEggEAwKnYu2P0YNJEfwLXmncchvlpZKQy5Jj0
# a5NCHesnaCiy9Z9VCGjZUBUXnzxkOe/E0LK+Dbe7gN4zq2443CnHSSTQgLVk7FoZ
# JkK2wPeuUxf34YRZtDNR2gs5VZgpJyHG5oqiG14ignCkXjaaghYhgwNaxRWajDgA
# ilYBSkTOrYRsLjRaCnZWLsEuuqTArqVFsB7pR/Zt82kLscWTOyMim43kfjXjO4/P
# HDntMwbWywZvL04YJ4afFQxwqq+D1a8XX/GKKeSzkw999R2JYwWOzMfWTwVNwpWo
# D94bSvI2Kyf/mXa0snxCm8khh+ItrhkSYJQWJJSuGKk8eG98xnSo5A==
# SIG # End signature block
