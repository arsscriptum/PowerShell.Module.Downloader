<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

#===============================================================================
# Commandlet Binding
#===============================================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Force") ]
    [Alias('f')]
    [switch]$Force,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Clean") ]
    [Alias('c')]
    [switch]$Clean,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Import") ]
    [Alias('i')]
    [switch]$Import,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Explorer") ]
    [Alias('e')]
    [switch]$Explorer
)

function Get-Script([string]$prop){
    $ThisFile = $script:MyInvocation.MyCommand.Path
    return ((Get-Item $ThisFile)|select $prop).$prop
}

$Script:ScriptPath                      = split-path $script:MyInvocation.MyCommand.Path
$Script:ScriptFullName                  = (Get-Item -Path $script:MyInvocation.MyCommand.Path).DirectoryName
$Script:ModuleRootPath                  = (Resolve-Path "$Script:ScriptPath\..").Path
$Script:ModuleName                      = (Get-Item -Path $Script:ModuleRootPath).Name
$Script:CurrPath                        = $ScriptPath
$Global:CurrentRunningScript            = Get-Script basename
$Script:Time                            = Get-Date
$Script:InternsPath                     = Join-Path $ScriptPath "internals"
$Script:InternsScript                   = Join-Path $Script:InternsPath "internals.ps1"
$Script:OutPath                         = Join-Path $Script:ModuleRootPath "out"
$Script:ModuleExportsPath               = Join-Path $Script:ModuleRootPath "exports"

$ExplorerExe = (Get-Command 'explorer.exe').Source
Write-Verbose "including `"$Script:InternsScript`""
. "$Script:InternsScript"

Write-Verbose "ModuleRootPath `"$Script:ModuleRootPath`""
Write-Verbose "ScriptPath `"$Script:ScriptPath`""
Write-Verbose "ModuleName `"$Script:ModuleName`""

try{

    [string[]]$ModPaths = Get-ModulePath | where Writeable -eq $True | where Childrens -gt 0 | Select -ExpandProperty Path
    if($ModPaths.Count -eq 0){
        throw "Could not find a suitable module path"
    }
    $ModulesRootPath = $ModPaths[0]

    $InstallPath = Join-Path $ModulesRootPath $Script:ModuleName
    Write-Verbose "InstallPath `"$InstallPath`""

    if($Clean){
        Write-Verbose "[Clean] Remove-Item -Path $InstallPath"
        $Null = Remove-Item -Path $InstallPath -Force -Recurse -ErrorAction Ignore
    }
    Write-Verbose "[Install] New-Item -Path $InstallPath"
    $Null = New-Item -Path $InstallPath -ItemType Directory -Force -ErrorAction Ignore
    Copy-Item "$Script:OutPath\$Script:ModuleName.psm1" "$InstallPath\$Script:ModuleName.psm1"
    Copy-Item "$Script:OutPath\$Script:ModuleName.psd1" "$InstallPath\$Script:ModuleName.psd1"
    Copy-Item "$Script:ModuleExportsPath" "$InstallPath" -Recurse

    if($Import){
        $Module = import-module "$Script:ModuleName" -Verbose -Force -PassThru
        $Ver = $Module.Version 
        Write-Host "[Import] $Script:ModuleName version $Ver Imported successfully" -f DarkGreen
        
        Add-IconUtilsType
    }

    if($Explorer){
        &"$ExplorerExe" "$InstallPath"
    }

    $ModuleScriptPath = (Get-ToolsModuleInformation).ModuleScriptPath
    Write-Verbose "[Install] ModuleScriptPath $ModuleScriptPath"
    Write-Verbose "[Install] InstallPath      $InstallPath"
    if( $ModuleScriptPath -ne $InstallPath ){
        throw "Installation Error"
    }


}catch{
    write-Error $_
}