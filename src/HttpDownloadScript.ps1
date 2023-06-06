<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  Http
#>


$HttpDownloadScript = {
      param($Url,$Path)
  

    function GetTimeString([int]$ms){
        $up=[timespan]::FromMilliseconds($ms)
        [string]$res_str = ""
        if($up.Days -gt 0){
            $res_str =  $up.ToString("dd' days 'hh' hours 'mm' minutes 'ss' seconds'")
        }elseif($up.Hours -gt 0){
            $res_str =  $up.ToString("hh' hours 'mm' minutes 'ss' seconds'")
        }elseif($up.Minutes -gt 0){
            $res_str =  $up.ToString("mm' minutes 'ss' seconds'")
        }else{
            $res_str =  $up.ToString("ss' seconds'")
        }
        return $res_str
    }

    try{

        $uri = New-Object "System.Uri" "$Url"
        [System.Net.HttpWebRequest]$request = [System.Net.HttpWebRequest]::Create($Url)
        $request.PreAuthenticate = $false
        $request.Method = 'GET'

        $request.Headers = New-Object System.Net.WebHeaderCollection
        $request.Headers.Add('referrer',$uri.Host)
         $request.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36'
        #$request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9'
        #$request.KeepAlive = $true
        $request.Timeout = ($TimeoutSec * 1000)
        $request.set_Timeout(15000) #15 second timeout


        ################################################################################
        # Request headers
        $request.Headers.Add('sec-ch-ua', '" Not A;Brand";v="99", "Chromium";v="99", "Google Chrome";v="99"')
        $request.Headers.Add('sec-ch-ua-mobile', '?0')
        $request.Headers.Add('sec-ch-ua-platform', "Windows")
        $request.Headers.Add('Sec-Fetch-Site', 'same-site')
        $request.Headers.Add('Sec-Fetch-Mode' ,'navigate')
        $request.Headers.Add('Sec-Fetch-Dest','document')
        $request.Headers.Add('Upgrade-Insecure-Requests', '1')
        $request.Headers.Add('User-Agent','Automated PowerShell Script')
        $request.Headers.Add('Referer' , $HttpReferrer)
        $request.Headers.Add('Accept-Encoding', 'gzip, deflate, br')

        # Create a timer
        $timer_main =  [system.diagnostics.stopwatch]::StartNew()
        $timer_update =  [system.diagnostics.stopwatch]::StartNew()
        $timespan_update = New-TimeSpan -Seconds 1
        ################################################################################
        # SEND THE REQUEST HERE
        $response = $request.GetResponse()    
        $responseStream = $response.GetResponseStream()

        $total_len_bytes = [System.Math]::Floor($response.get_ContentLength())
        $total_len_kilobytes = $total_len_bytes/1024

        $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, Create
        $buffer = new-object byte[] 10KB
        $read_count = $responseStream.Read($buffer,0,$buffer.length)
        $received_kilo_bytes = 0
        $received_bytes = $read_count

        while ($read_count -gt 0){
            $targetStream.Write($buffer, 0, $read_count)
            $read_count = $responseStream.Read($buffer,0,$buffer.length)

                $timer_update.Restart()

                $received_bytes += $read_count
                $received_kilo_bytes = $([System.Math]::Floor($received_bytes/1024))
                $raw_percentage = ($received_bytes / $total_len_bytes)*100
                $percentage = [math]::Round($raw_percentage)

                if($percentage -lt 0) {$percentage = 0}
                if($percentage -gt 100) {$percentage = 100}
                $raw_elapsed_milliseconds = $timer_main.Elapsed.TotalMilliseconds
                $elapsed_milliseconds = [math]::Round($raw_elapsed_milliseconds)
                $raw_estimated_total_ms = (100 / $raw_percentage) * $raw_elapsed_milliseconds
                $estimated_total_ms = [math]::Round($raw_estimated_total_ms)
                $remaining_ms = $raw_estimated_total_ms - $raw_elapsed_milliseconds
                
                [string]$str_total_time = GetTimeString($remaining_ms)
                
                $obj = [pscustomobject]@{
                    received_bytes          = $received_bytes
                    total_len_bytes         = $total_len_bytes
                    received_kilo_bytes     = $received_kilo_bytes
                    total_len_kilobytes     = $total_len_kilobytes
                    percentage              = $percentage
                    elapsed_milliseconds    = $elapsed_milliseconds
                    estimated_total_ms      = $estimated_total_ms
                    str_total_time          = $str_total_time
                }
                [string]$str_output = $obj | ConvertTo-Json -Compress
                Write-Output($str_output)
           # }       
        }

        $targetStream.Flush()
        $targetStream.Close()
        $targetStream.Dispose()
        $responseStream.Dispose()
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }finally{
        Write-verbose "Downloaded $Url"
}}.GetNewClosure()

[scriptblock]$HttpDownloadScriptBlock = [scriptblock]::create($HttpDownloadScript) 




function Save-UsingHttpJob{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="url", Position=0)]
        [string]$Url,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Destination Directory where the files are saved", Position=1)]
        [string]$DestinationPath, 
        [Parameter(Mandatory=$false)]
        [switch]$Asynchronous, 
        [Parameter(Mandatory=$false)]
        [switch]$Authenticate, 
        [Parameter(Mandatory=$false)]
        [string]$User, 
        [Parameter(Mandatory=$false)]
        [string]$Password    
    )

    try{
        $JobName = New-JobName
        Write-LogEntry "Start job `"$JobName`" Asynchronous $Asynchronous"
        $jobby = Start-Job -Name $JobName -ScriptBlock $HttpDownloadScriptBlock -ArgumentList ($Url,$DestinationPath)
        $Transferring  = $True

        if($Asynchronous -eq $False){
            Receive-HttpJob $JobName
        }else{
            Write-LogEntry "Asynchronous mode. To get progress, call `"Receive-HttpJob $JobName`""
        }
        $RetObj = [pscustomobject]@{
            OutFilePath = $DestinationPath
            JobName = $JobName
        }
        $RetObj

    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}



function Receive-HttpJob{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="JobName", Position=0)]
        [string]$JobName
    )

    try{
        $Transferring = $True
        $JobState = (Get-Job -Name $JobName).State
        Write-verbose "JobState: $JobState"

        $ProgressTitle = "MODE: HTTPJOB $JobName"
        while($Transferring){

            try{
                $JobState = (Get-Job -Name $JobName).State
                $Output = Receive-Job -Name $JobName

                Write-verbose "JobState: $JobState"
                if($JobState -eq 'Completed'){
                    $Transferring = $False
                    Get-Job $JobName | Remove-Job
                    return
                }

                $line_out = $Output | Select-Object -Last 1
                $progress = $line_out | ConvertFrom-Json

                $progress_percentage = $progress.percentage
                if($progress_percentage -eq $Null) {$progress_percentage = 0}
                if($progress_percentage -lt 0) {$progress_percentage = 0}
                if($progress_percentage -gt 100) {$progress_percentage = 100}
                
                if( ($Null -eq $progress.received_kilo_bytes) -Or ($Null -eq $progress.total_len_kilobytes) -Or ($Null -eq $progress.str_total_time) ) {
                    continue;
                }
                $msg = "Received {0} Kb of {1} Kb. {2}% completed. {3}" -f $progress.received_kilo_bytes, $progress.total_len_kilobytes, $progress.percentage, $progress.str_total_time
                Write-Progress -Activity $ProgressTitle -Status $msg -PercentComplete $progress_percentage
            }catch{
                Write-Error $_
            }
        }

    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}

