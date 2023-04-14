       
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  Http
#>



[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$False)]
    [int]$NumLinks = 3
)

if($Reset){
    $Null = Remove-Item -Path $TmpPath -Recurse -Force -ErrorAction Ignore
}
$Null = New-Item -Path $TmpPath -ItemType directory -Force -ErrorAction Ignore


$dep = "$PSScriptRoot\test_dependencies.ps1"
. "$dep"

Clear-Host
test_log "====================" -f Yellow
test_log "     BITS MODULE    " -f Gray
test_log "====================" -f Yellow


function Test-Run{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="url", Position=0)]
        [string]$Url,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Destination Directory where the files are saved", Position=1)]
        [string]$DestinationPath,  
        [Parameter(Mandatory=$false)]
        [switch]$Asynchronous,
        [Parameter(Mandatory=$false)]
        [switch]$EnableNotification,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Foreground','High','Normal','Low')]
        [string]$Priority="Foreground"  
    )

    test_log "Test-Run Save-UsingBitsModule" -f Yellow
    Add-DlModLogIndentValue
    test_log "Url = $Url"
    test_log "DestinationPath = $DestinationPath "
    test_log "Asynchronous = $Asynchronous "
    test_log "EnableNotification = $EnableNotification "
    test_log "Priority = $Priority"

    $OutFilePath
    $Parameters = @{
        Url = $Url 
        DestinationPath = $DestinationPath 
        Asynchronous = $Asynchronous 
        EnableNotification = $EnableNotification 
        Priority = $Priority
    }
    $timer =  [system.diagnostics.stopwatch]::StartNew()
    $ret = Save-UsingBitsModule @Parameters 
    $OutFilePath =  $ret.OutFilePath
    $JobName =  $ret.JobName
    test_log "JobName     = $JobName"
    test_log "OutFilePath = $OutFilePath"
    $ms =  $timer.Elapsed.TotalMilliseconds
    test_log "Save-UsingBitsModule completed in $ms`n"
    Set-DlModLogIndentValue 0
}


$links = Get-RandomTestLinks $NumLinks
$links.GetEnumerator() | % {
    $Url = $_.Key
    $DestinationPath = $_.Value
    Test-Run $Url $DestinationPath
}
