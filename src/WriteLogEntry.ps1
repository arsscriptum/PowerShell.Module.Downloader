
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>




function Get-DlModLogsInitialized{   
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $Initialized = Get-Variable -Name 'PowerShellYoutubeDlLogsInitialized' -Scope Script -ValueOnly -ErrorAction Ignore
    if($Initialized -eq $False -or $Initialized -eq $null){
        Write-Verbose "Get-DlModLogsInitialized False"
        return $False
    }
    Write-Verbose "Get-DlModLogsInitialized True"
    return $True
}

function Initialize-DlModLogs{     
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $init = Get-DlModLogsInitialized
    if($init -eq $False){
        [string]$folder = (Get-Date).GetDateTimeFormats()[11].Replace(':','-').Replace(' ','-') 
        $logfilepath = Join-Path "$ENV:Temp\PowerShell.YoutubeDl\$folder" 'youtube-dl.log'
        Write-Verbose "Initialize-DlModLogs logfilepath $logfilepath"
        $Null = New-Item -Path $logfilepath -ItemType file -Force -ErrorAction Ignore
        Set-Variable -Name 'YoutubeDlLogFilePath' -Scope Global -ErrorAction Ignore -Value $logfilepath -Force -Visibility Public -Option AllScope
        Set-Variable -Name 'PowerShellYoutubeDlLogsInitialized' -Scope Script -ErrorAction Ignore -Value $True -Force -Visibility Public -Option AllScope

        
        Set-DlModFileLogsEnabled $True
        Set-DlModConsoleLogsEnabled $True
    }
}

function Add-DlModLogIndentValue{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, Position=0)]
        [int]$Indent=1
    )
    $NewValue=Get-DlModLogIndentValue
    $NewValue = $NewValue + $Indent
    Set-Variable -Name 'DlModLogIndentValue' -Scope Script -Value $NewValue -Visibility Public # -Option AllScope
}

function Set-DlModLogIndentValue{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [int]$Indent
    )
    Set-Variable -Name 'DlModLogIndentValue' -Scope Script -Value $Indent -Visibility Public # -Option AllScope
}

function Get-DlModLogIndentValue{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $Indent = Get-Variable -Name 'DlModLogIndentValue' -Scope Script -ValueOnly -ErrorAction Ignore
    if($Indent -eq 0 -or $Indent -eq $null){
        return 0
    }
    return $Indent
}


function Get-DlModFileLogsEnabled{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $Enabled = Get-Variable -Name 'DlModFileLogsEnabled' -Scope Script -ValueOnly -ErrorAction Ignore
    if($Enabled -eq $False -or $Enabled -eq $null){
        Write-Verbose "Get-DlModFileLogsEnabled False"
        return $False
    }
    Write-Verbose "Get-DlModFileLogsEnabled True"
    return $True
}

function Set-DlModFileLogsEnabled{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [bool]$Enabled
    )
    Set-Variable -Name 'DlModFileLogsEnabled' -Scope Script -Value $Enabled -Visibility Public # -Option AllScope
}
function Set-DlModConsoleLogsEnabled{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [bool]$Enabled
    )
    Set-Variable -Name 'DlModConsoleLogsEnabled' -Scope Script -Value $Enabled -Visibility Public # -Option AllScope
}
function Get-DlModConsoleLogsEnabled{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $Enabled = Get-Variable -Name 'DlModConsoleLogsEnabled' -Scope Script -ValueOnly -ErrorAction Ignore
    if($Enabled -eq $False -or $Enabled -eq $null){
        Write-Verbose "Get-DlModConsoleLogsEnabled False"
        return $False
    }
    Write-Verbose "Get-DlModConsoleLogsEnabled True"
    return $True
}

function Get-InternalLogFilePath{     # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $path = Get-Variable -Name 'YoutubeDlLogFilePath' -Scope Global -ValueOnly -ErrorAction Ignore
    if($path -eq $False -or $path -eq $null){
        Write-Verbose "Get-InternalLogFilePath ''"
        return ""
    }
    Write-Verbose "Get-InternalLogFilePath $path"
    return $path
}

function Get-DlModLogFilePath{   
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $path = Get-Variable -Name 'YoutubeDlLogFilePath' -Scope Global -ValueOnly -ErrorAction Ignore
    if($path -eq $False -or $path -eq $null){
        Write-Verbose "Get-InternalLogFilePath ''"
        return ""
    }
    Write-Verbose "Get-DownloaderModuleLogFilePath $path"
    return $path
}

function Invoke-DlModLogTailing{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, Position=0)]
        [string]$Command = 'baretail.exe'
    )
    try{
        $log =Get-InternalLogFilePath
        $CmdExe = (Get-Command $Command).Source
        &"$CmdExe" "$log"
    }catch{
        Write-Error $_
    }
}


Function Write-LogEntry {     
    PARAM(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="LogEntry", Position=0)]
        [string] $LogEntry,
        [Parameter(Mandatory=$false)]
        [Alias('s')]
        [int]    $Severity=1,
        [Parameter(Mandatory=$false)] 
        [Alias('f')]
        [string] $FontColor="Gray",
        [Parameter(Mandatory=$false)] 
        [Alias('i')]
        [int]    $Indent = 0,
        [Parameter(Mandatory=$false)] 
        [Alias('n')]
        [switch] $NoNewLine,
        [Parameter(Mandatory=$false)] 
        [Alias('c')]
        [string] $Category
    )
    BEGIN
    {
        
        $init = Get-DlModLogsInitialized
        if($init -eq $False){ Initialize-DlModLogs }

        $DlModConsoleLogsEnabled = Get-DlModConsoleLogsEnabled
        $DlModFileLogsEnabled    = Get-DlModFileLogsEnabled
        $LogFile            = Get-Variable -Name 'YoutubeDlLogFilePath' -Scope Global -ErrorAction Ignore -ValueOnly
        if($FontColor -eq "") {
            switch ($Severity) {
                "1" {
                    ## Informational Response
                    $FontColor     = "White"
                    $MessagePreFix = ""
                }
                "2" {
                    ## Warning Response
                    $FontColor = "Yellow"
                    $MessagePreFix = "WARNING:  "
                }
                "3" {
                    ## Error Response
                    $FontColor = "Red"
                    $MessagePreFix = "ERROR:    "
                }
            }
        }
        ## Combines the logging message and the message type as a prefix
        $LogEntry = $MessagePreFix + $LogEntry

        if($PSBoundParameters.ContainsKey('Indent') -eq $False){
            $Indent = Get-DlModLogIndentValue
        }
        ## Indents the message when viewed on the screen.
        $LogEntry = $LogEntry.PadLeft($LogEntry.Length + (2 * $Indent) )
    }
    PROCESS
    {
        if($DlModFileLogsEnabled)    { Add-Content -Path "$LogFile" -Value "$LogEntry" -NoNewline:$NoNewLine }
        if($DlModConsoleLogsEnabled) { 
            if($PSBoundParameters.ContainsKey('Category') -eq $True){
                Write-Host "[$Category] " -f Yellow -n
            }else{
                Write-Host "[ModDl] " -f DarkCyan -n
            }
            Write-Host -Object $LogEntry -ForegroundColor $FontColor -NoNewline:$NoNewLine 
        }
    }
    END
    {
        return
    }
}

