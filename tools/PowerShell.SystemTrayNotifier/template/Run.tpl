<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜  
#>


[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Text,
    [Parameter(Mandatory=$false)]
    [int]$Duration=3000,
    [Parameter(Mandatory=$false)]
    [int]$Pause=8
)   


if(($ProgramName -eq 'pwsh.exe') -Or ($ProgramName -eq 'powershell.exe')){
    $MODE_NATIVE = $False
    $MODE_SCRIPT = $True
}else{
    $MODE_NATIVE = $True
    $MODE_SCRIPT = $False

    $CurrentPath = (Get-Location).Path
    $CmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = '$pid'" | select CommandLine ).CommandLine   
    [string[]]$UserCommandArray = $CmdLine.Split(' ')
    $ProgramFullPath = $UserCommandArray[0].Replace('"','')
    $ProgramDirectory = (gi $ProgramFullPath).DirectoryName
    $ProgramName = (gi $ProgramFullPath).Name
    $ProgramBasename = (gi $ProgramFullPath).BaseName
}

# __INCLUDE_SYSTRAY_NOTIFIER_SCRIPT__
# __INCLUDE_SYSTRAY_ICON_PATH__

$Title = "Download Completed"
$IconPath = Join-Path $IconBaseDirectory "download.ico"

Show-SystemTrayNotification $Text $Title $IconPath -Duration $Duration

$Pause..1 | % {
    Start-Sleep 1
    Write-Host "$_ " -n
}

$Title = "Operation Completed"
$IconPath = Join-Path $IconBaseDirectory "close128.ico"

Show-SystemTrayNotification $Text $Title $IconPath -Duration $Duration