
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>




function Test-LogVariableScopes{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $Initialized = Get-Variable -Name 'PowerShellYoutubeDlLogsInitialized' -Scope Script -ValueOnly -ErrorAction Ignore
    $FileLogsEnabled = Get-Variable -Name 'PowerShellYoutubeFileLogsEnabled' -Scope Script -ValueOnly -ErrorAction Ignore
    $ConsoleLogsEnabled = Get-Variable -Name 'PowerShellYoutubeConsoleLogsEnabled' -Scope Script -ValueOnly -ErrorAction Ignore
    $filepath = Get-Variable -Name 'YoutubeDlLogFilePath' -Scope Global -ErrorAction Ignore -ValueOnly
    Write-Host "========================================"
    Write-Host "Initialized        $Initialized"
    Write-Host "FileLogsEnabled    $FileLogsEnabled"
    Write-Host "ConsoleLogsEnabled $ConsoleLogsEnabled"
    Write-Host "LogFilePath        $filepath"
    Write-Host "========================================"
}


function Test-CustomLogSys{
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $DateStr = (Get-Date).GetDateTimeFormats()[124]
    Write-LogEntry "==============================="
    Write-LogEntry "Test-CustomLogSys $DateStr"
    1..10 | % {
        $sec = Get-Date -uFormat %s
        $guid = (New-Guid).Guid
        Write-LogEntry "$guid == $sec"
    }
}