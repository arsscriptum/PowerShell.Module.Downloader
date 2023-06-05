
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>





function Get-WGetExecutable{     # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param()

   try{
        $Cmd = Get-Command -Name 'wget.exe' -ErrorAction Ignore
        if($Cmd -eq $Null) { throw "Cannot find wget.exe" }
        $WgetExe = $Cmd.Source
        if(-not(Test-Path $WgetExe)){ throw "cannot fin wget executable. is it installed ?" }
        return $WgetExe
    }catch{
        Show-ExceptionDetails $_
    }
    return $Null
}



function Save-UsingStartProcessWGet{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="url", Position=0)]
        [string]$Url,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Destination Directory where the files are saved", Position=1)]
        [string]$DestinationPath,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="WgetExe", Position =2)]
        [string]$WgetExe,    
        [Parameter(Mandatory=$false)]
        [switch]$Asynchronous          
    )
    try{
        [string]$epoc_time = (Get-Date -uFormat %s)
        $FNameOut = "{0}\{1}_{2}.log" -f $ENV:Temp, 'STDOUT', $epoc_time
        $FNameErr = "{0}\{1}_{2}.log" -f $ENV:Temp, 'STDERR', $epoc_time

        $WaitArg = !$Asynchronous
        $startProcessParams = @{
            FilePath               = $WgetExe
            RedirectStandardError  = $FNameErr
            RedirectStandardOutput = $FNameOut
            Wait                   = $WaitArg
            PassThru               = $true
            NoNewWindow            = $true
        }

        $ArgumentList = @("-q", "--progress=bar:force:noscroll", "$Url", "-O", "$DestinationPath")

        $cmd = Start-Process @startProcessParams -ArgumentList $ArgumentList
        $cmdExitCode = $cmd.ExitCode
        $cmdId = $cmd.Id 
        $cmdHasExited=$cmd.HasExited 
        $cmdTotalProcessorTime=$cmd.TotalProcessorTime 


        $stdOut = Get-Content -Path $FNameOut -Raw -ErrorAction Ignore
        $stdErr = Get-Content -Path $FNameErr -Raw -ErrorAction Ignore
        if ([string]::IsNullOrEmpty($stdOut) -eq $false) {
            $stdOut = $stdOut.Trim()
        }
        if ([string]::IsNullOrEmpty($stdErr) -eq $false) {
            $stdErr = $stdErr.Trim()
        }
        $res = [PSCustomObject]@{
            HasExited          = $cmdHasExited
            TotalProcessorTime = $cmdTotalProcessorTime
            Id                 = $cmdId
            ExitCode           = $cmdExitCode
            DestinationPath    = $DestinationPath
            Output             = $stdOut
            Error              = $stdErr
            ElapsedSeconds     = $stopwatch.Elapsed.Seconds
            ElapsedMs          = $stopwatch.Elapsed.Milliseconds
        }
            
        return $res
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}





$WGetDownloadJob = {
      param([string]$Url,[string]$DestinationFile,[string]$WgetExe)   
  
    try{
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        &"$WgetExe" "$Url" "-O" "$DestinationFile"
        $Null = Remove-Item -Path tmpfile -Force -ErrorAction Ignore
        $totalMs = $stopwatch.Elapsed.TotalMilliseconds
        Write-Output "$totalMs"


    }catch{
        Write-Error $_
    }finally{
        if(Test-Path "$DestinationFile"){
            Write-Output "$DestinationFile"
        }
        
}}.GetNewClosure()

[scriptblock]$WGetDownloadJobScriptBlock = [scriptblock]::create($WGetDownloadJob) 



function Save-UsingWGetJob{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="url", Position=0)]
        [string]$Url,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Destination Directory where the files are saved", Position=1)]
        [string]$DestinationPath, 
        [Parameter(Mandatory=$false)]
        [switch]$Asynchronous,
        [Parameter(Mandatory=$false)]
        [switch]$EnableNotification         
    )
    try{
        $DestinationPath = Convert-DestinationPath $Url $DestinationPath

        # Generate a UNIQUE JOB NAME, but easy to use, not a GUID with 64 chars...
        [string]$JobName = (Get-Date).GetDateTimeFormats()[113]
        $JobName = $JobName.Replace(':',"").Replace('0',"")
        $v1 = Get-Random -Maximum 25 -Minimum 1
        $v2 = Get-Random -Maximum 25 -Minimum 1
        $arrrnd = @($v1,$v2)
        $arrrnd | % { $JobName += [char]($_ + 65) }

        $DestinationPath = Convert-DestinationPath $Url $DestinationPath
        
        if(Test-Path $DestinationPath -PathType Leaf){
            $dn = (Get-Item $DestinationPath).DirectoryName
            $bn = (Get-Item $DestinationPath).BaseName
            $ex = (Get-Item $DestinationPath).Extension
            [string]$rndname = (Get-Date).GetDateTimeFormats()[113]
            $rndname = $rndname.Replace(':',"").Replace('0',"")
            $newname = "{0}_{1}{2}" -f "$bn", "$rndname", "$ex"
            $DestinationPath = Join-Path $dn $newname
        }
        $WgetExe          = Get-WGetExecutable
        Write-LogEntry "=========================================================="
        Write-LogEntry "Asynchronous     : $Asynchronous"
        Write-LogEntry "DestinationPath  : $DestinationPath"
        Write-LogEntry "Url              : $Url"
        Write-LogEntry "DownloadMode     : $DownloadMode"
        Write-LogEntry "=========================================================="
        

        $ProgressTitle = "MODE: WGET [$JobName]"

        # This JOB will output logs to a file so we can get the progress data.
        # Since we may run multiple jobs in parallel, the files ust be unique
        $TmpProgressFile = "$ENV:Temp\progress_$JobName.txt"
        $WgetPattern = '^(\s*)(?<BytesReceived>[0-9\*]*)(?<Multiplier>[a-zA-Z])(\s?)(?<Dots>.......... .......... .......... .......... ..........?)(\s*)(?<Percent>[\d\%]*)(\s*)(?<BytesReceived2>[0-9\*\.]*)(?<Multiplier2>[a-zA-Z])(\s?)(\s?)(?<Time>[a-zA-Z0-9\:]*)'
        $RetObj = [pscustomobject]@{
            OutFilePath = $DestinationPath
            JobName = $JobName
        }
        Write-LogEntry "Start job `"$JobName`" Asynchronous $Asynchronous"
        $jobby = Start-Job -Name $JobName -ScriptBlock $WGetDownloadJobScriptBlock -ArgumentList ($Url,$DestinationPath,$WgetExe)
        $Transferring  = $True
        if($Asynchronous){ 
            Write-LogEntry "Asynchronous Mode..."
        }else{
            Receive-WGetJob $JobName -EnableNotification:$EnableNotification
        }
        $RetObj
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}




function Receive-WGetJob{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="JobName", Position=0)]
        [string]$JobName,
        [Parameter(Mandatory=$false)]
        [switch]$EnableNotification  
    )

    try{
        $TmpProgressFile = "$ENV:Temp\progress_$JobName.txt"
        $Transferring = $True
        $JobState = (Get-Job -Name $JobName).State
        Write-verbose "JobState: $JobState"
        if($JobState -eq 'Completed'){
            $Transferring = $False
        }
        $ProgressTitle = "MODE: WGETJOB $JobName"
        while($Transferring){
            Start-Sleep -Milliseconds 100
            
            $JobState = (Get-Job -Name $JobName).State
            Write-verbose "JobState: $JobState"
            if($JobState -eq 'Completed'){
                $Transferring = $False
            }
            
            Receive-Job -Name $JobName *>> $TmpProgressFile
                               
            $str = Get-Content $TmpProgressFile -Tail 1
            if($str -match $WgetPattern){
                $BytesReceived = $Matches.BytesReceived
                $Time = $Matches.Time
                $Percent = $Matches.Percent
                [int]$PercentNum = $Percent.Replace('%','')
                $PercentNum =[math]::Round($PercentNum)
                $ProgressStatusMesage = "Downloaded {0}{1}. ({2}) Time remaining {3}" -f $BytesReceived,$Multiplier,$Percent,$Time
                Write-Progress -Activity $ProgressTitle -Status "$ProgressStatusMesage" -PercentComplete $PercentNum 
            }else{
                Write-verbose "WGet Progress: Parsing Error [$TmpProgressFile]"
            }
        }
        $ExportsPath = Get-DownloaderModuleExportsPath
        $DownloadCompletedPath = (Join-Path $ExportsPath "DownloadCompleted.exe")
        
        $Res = Get-Job -Name $JobName | Receive-Job -Wait
        if($EnableNotification){
            $message = @"

A wget.exe download job just completed.

$DestinationPath

"@          

            Show-InternalMiniInfoPopup $message "WGET JOB COMLPETED"
            #&"$DownloadCompletedPath" "$DestinationPath"
        }
        $Res
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}

