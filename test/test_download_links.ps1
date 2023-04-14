
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  Http
#>



[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$False)]
    [string]$TmpPath = "$ENV:Temp\Downloads",
    [Parameter(Mandatory=$False)]
    [switch]$Reset
)

if($Reset){
    $Null = Remove-Item -Path $TmpPath -Force -Recurse  -ErrorAction Ignore
}
$Null = New-Item -Path $TmpPath -ItemType Directory -Force -ErrorAction Ignore

$test_download_links = @{
    "https://github.com/PowerShell/PowerShell/releases/download/v7.2.7/PowerShell-7.2.7-win-x64.zip"    =   "$TmpPath\PowerShell-7.2.7-win-x64.zip"
    "https://arsscriptum.github.io/assets/img/art.png"                                                  =   "$TmpPath\art.png"
    "https://arsscriptum.github.io/files/TeamViewerQS.exe"                                              =   "$TmpPath\TeamViewerQS.exe"
    "https://arsscriptum.github.io/assets/files/ookla-speedtest-1.2.0-win64.zip"                        =   "$TmpPath\ookla-speedtest-1.2.0-win64.zip"
    "https://github.com/PowerShell/PowerShell/releases/download/v7.3.0-rc.1/powershell-7.3.0-rc.1-linux-arm32.tar.gz"       =   "$TmpPath\powershell-7.3.0-rc.1-linux-arm32.tar.gz"
    "https://github.com/PowerShell/PowerShell/releases/download/v7.3.0-rc.1/powershell-preview-7.3.0_rc.1-1.rh.x86_64.rpm"  =   "$TmpPath\powershell-preview-7.3.0_rc.1-1.rh.x86_64.rpm"
}


function Get-RandomTestLink{
    $num_links = $test_download_links.Count
    $index = Get-Random -Minimum 0 -Maximum ($num_links - 1)

    $i = 0
    $test_download_links.GetEnumerator() | % {
        if($index -eq $i){
            @{ $_.Key = $_.Value }
        }
        $i++

    } 
}


function Get-RandomTestLinks{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Num
    )
    $num_links = $test_download_links.Count
    if($Num -gt $num_links) { throw "Not enough links" }
    $ret = @{}

    $i = 0
    $test_download_links.GetEnumerator() | % {
        $k = $_.Key
        $v = $_.Value
        $ret.Add($k,$v)
        Write-Verbose "Add $k,$v"
        if($Num -eq $($ret.Count)){
            return $ret
        }
    } 
}
