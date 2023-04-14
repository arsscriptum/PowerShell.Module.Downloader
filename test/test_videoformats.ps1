   
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  Http
#>



[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$False, Position=0)]
    [string]$TestId
)


Clear-Host
Write-LogEntry "========================================================" -f DarkCyan
Write-LogEntry "           PowerShell.Module.Downloader TEST            " -f Gray
Write-LogEntry "========================================================" -f DarkCyan
$Module = Import-Module 'PowerShell.Module.Downloader' -Force -ErrorAction Ignore -PassThru



# 
$Url = 'https://www.youtube.com/watch?v=ghb6eDopW8I'

Write-LogEntry "-----------------------------------------------" -f Yellow
Write-LogEntry "VideoFormats for $Url" -f Blue
Request-VideoFormats $Url
