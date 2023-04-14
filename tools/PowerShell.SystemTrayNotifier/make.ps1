
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)] 
    [Alias('r')]
    [String]$Run,
    [Parameter(Mandatory = $false)] 
    [Alias('c')]
    [switch]$Clean
)


    function Get-Script([string]$prop){
        $ThisFile = $script:MyInvocation.MyCommand.Path
        return ((Get-Item $ThisFile)|select $prop).$prop
    }

    $MakeScriptPath = split-path $script:MyInvocation.MyCommand.Path
    $ScriptFullName =(Get-Item -Path $script:MyInvocation.MyCommand.Path).FullName
    $ScriptsPath = Join-Path $MakeScriptPath 'scripts'

    #===============================================================================
    # Root Path
    #===============================================================================
    $Global:ConsoleOutEnabled              = $true
    $Global:CurrentRunningScript           = Get-Script basename
    $Script:CurrPath                       = $MakeScriptPath
    $Script:RootPath                       = (Get-Location).Path
    If( $PSBoundParameters.ContainsKey('Path') -eq $True ){
        $Script:RootPath = $Path
    }
    If( $PSBoundParameters.ContainsKey('ModuleIdentifier') -eq $True ){
        $Global:ModuleIdentifier = $ModuleIdentifier
    }else{
        $Global:ModuleIdentifier = (Get-Item $Script:RootPath).Name
    }
    #===============================================================================
    # Script Variables
    #===============================================================================
    $Global:CurrentRunningScript           = Get-Script basename
    $Script:Time                           = Get-Date
    $Script:Date                           = $Time.GetDateTimeFormats()[13]

    $Script:SrcPath                       = Join-Path $MakeScriptPath "src"
    $Script:ImgPath                       = Join-Path $MakeScriptPath "img"
    $Script:OutPath                       = Join-Path $MakeScriptPath "out"
    $Script:TemplatePath                  = Join-Path $MakeScriptPath "template"
    $Script:HeadRev                        = git log --format=%h -1 | select -Last 1
    $Script:LastRev                        = git log --format=%h -2 | select -Last 1


    Write-Host "===============================================================================" -f DarkRed
    Write-Host "MAKE - SYSTRAYNOTIFIER" -f DarkYellow
    Write-Host "===============================================================================" -f DarkRed
   
    if($Clean){
        Write-Host "Cleaning `"$Script:OutPath`""
        $Null = Remove-Item -Path "$Script:OutPath" -Force -Recurse -ErrorAction Ignore
    }
    if(-not(Test-Path "$Script:OutPath" -PathType Container)){
        $Null = New-Item -Path "$Script:OutPath" -Force -ItemType Directory -ErrorAction Ignore
    }
    

    [string]$ScriptContent = Get-Content "$Script:SrcPath\ShowSystemTrayNotification.ps1" -Raw
    $ScriptContent =  Remove-CommentsFromScriptBlock $ScriptContent
    $ScriptBlock =  Convert-ToBase64CompressedScriptBlock $ScriptContent
    $ScriptString = "`$ScriptStr = `"$ScriptBlock`""
    $DecodeString = "ConvertFrom-Base64CompressedScriptBlock `$ScriptStr | iex"
    $IcoString = "`$IconBaseDirectory = `"$Script:ImgPath`""
    [string]$ScriptContent = Get-Content "$Script:TemplatePath\Run.tpl" -Raw
    $ScriptContent = $ScriptContent.Replace('# __INCLUDE_SYSTRAY_NOTIFIER_SCRIPT__', "$ScriptString`n$DecodeString")
    $ScriptContent = $ScriptContent.Replace('# __INCLUDE_SYSTRAY_ICON_PATH__', "$IcoString")


    Write-Host "Generating `"$Script:OutPath\Run.ps1`"" -f Red
    Set-Content "$Script:OutPath\Run.ps1" -Value $ScriptContent

    if( [string]::IsNullOrEmpty($Run) -eq $False ){
        . "$Script:OutPath\Run.ps1" "$Run"
    }