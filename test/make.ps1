   
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  Http
#>



[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$False)]
    [string]$TmpPath = "$PSScriptRoot\Downloads",
    [Parameter(Mandatory=$False)]
    [switch]$Reset
)


function mlog{
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true,position=0)]
    [string]$message
)
    Write-Host "[make] " -n -f Blue
    Write-Host "$message" -f Gray
}

$RootPath = (Resolve-Path "..").Path
$ModPath        = "C:\DOCUMENTS\PowerShell\Modules"
$ModPathModDl   = "C:\DOCUMENTS\PowerShell\Modules\PowerShell.Module.Downloader"

mlog "Unloading PowerShell.Module.Downloader"
Remove-Module PowerShell.Module.Downloader -Force -ErrorAction Ignore

mlog "Deleting $ModPathModDl"
$Null = Remove-Item -Path $ModPathModDl -Recurse -Force -ErrorAction Ignore

$nupkgs = gci -Path $ModPath -File -Filter "*.nupkg"
$nupkgs | % {
    $fullname = $_.fullname
    mlog "Deleting $fullname"
    $Null = Remove-Item -Path $fullname -Force -ErrorAction Ignore
}

pushd $RootPath

make -i -d

popd

Import-Module PowerShell.Module.Downloader -Verbose -Force

