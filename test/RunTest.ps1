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
        HelpMessage="Reset") ]
    [Alias('r')]
    [switch]$Reset
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
$Script:ExtractedIconsPath              = Join-Path $Script:CurrPath "_test_data\extracted_icons"

if($Reset){
    Write-Verbose "[Clean] Remove-Item -Path $Script:ExtractedIconsPath"
    $Null = Remove-Item -Path $Script:ExtractedIconsPath -Force -Recurse -ErrorAction Ignore
}
$ExecutableList = (gci -Path "$ENV:ProgramFiles" -Recurse -File -Filter "*.exe" -ErrorAction Ignore).FullName
$ExecutableListCount = $ExecutableList.Count

$RandomNums = Get-Random -Minimum 1 -Maximum $ExecutableListCount -Count 30


 Write-Verbose "[ExtractedIconsPath] New-Item -Path $Script:ExtractedIconsPath"
$Null = New-Item -Path $Script:ExtractedIconsPath -ItemType Directory -Force -ErrorAction Ignore
$TotalExtracted = 0
$Sizes = @(8, 16, 24, 32, 48, 64, 96, 128)
#$Types = @('ico', 'bmp', 'png', 'jpg', 'gif', 'jpeg', 'emf', 'exif', 'icon', 'tiff', 'wmf')
$Types = @('jpg')
ForEach($num in $RandomNums){
    $exe = $ExecutableList[$num]
    $bname = (gi $exe).Basename
    $export_path = Join-Path $Script:ExtractedIconsPath $bname
    $Null = New-Item -Path $export_path -ItemType Directory -Force -ErrorAction Ignore
    Write-Host "[Export-Icon] $exe to $export_path"
    ForEach($type in $Types){
        try{
            $NumExtracted = Export-Icon -Path $exe -Directory $export_path -Type $type -Size 32
            if($NumExtracted -eq 0){
                $Null = remove-Item -Path $export_path -Force -recurse -ErrorAction Ignore
                continue;
            }
            $TotalExtracted += $NumExtracted
        }catch{}
    }
    
    
}

Write-Host "[Test] Extracted $NumExtracted icons" -Red
