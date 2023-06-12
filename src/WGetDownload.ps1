
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>



$Script:ShowNotification = $True

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
        [switch]$Asynchronous,    
        [Parameter(Mandatory=$false)]
        [bool]$ShowNotification=$True             
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

        $ArgumentList = @("-q", "--progress=bar:force:noscroll", "$Url", "-O", "$DestinationPath", $ShowNotification)

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
      param([string]$Url,[string]$DestinationFile,[string]$WgetExe,[bool]$ShowNotification)   
  
    try{
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        &"$WgetExe" "$Url" "-O" "$DestinationFile"

        if($ShowNotification -eq $True){
            $ENV:NotifyTitle = "DOWNLOAD COMPLETE"
            $ENV:NotifyText = "$DestinationFile"
            $PwshExe = (Get-Command 'pwsh.exe').Source
            $ArgList = @("-nop","-noni","-encodedcommand", "ZgB1AG4AYwB0AGkAbwBuACAATgBlAHcALQBUAHIAYQB5AE4AbwB0AGkAZgBpAGUAcgB7AA0ACgAgACAAIAAgAFsAQwBtAGQAbABlAHQAQgBpAG4AZABpAG4AZwAoAFMAdQBwAHAAbwByAHQAcwBTAGgAbwB1AGwAZABQAHIAbwBjAGUAcwBzACkAXQANAAoAIAAgACAAIABwAGEAcgBhAG0AKAApAA0ACgAgACAAIAAgACQASQBjAG8AbgAgAD0AIAAiAHkAbwB1AHQAdQBiAGUAXwBjAG8AbABvAHIAIgANAAoAIAAgACAAIAAkAFQAaQB0AGwAZQAgAD0AIAAiACQARQBOAFYAOgBOAG8AdABpAGYAeQBUAGkAdABsAGUAIgANAAoAIAAgACAAIAAkAFQAZQB4AHQAIAA9ACAAIgAkAEUATgBWADoATgBvAHQAaQBmAHkAVABlAHgAdAAiAA0ACgAgACAAIAAgACQARAB1AHIAYQB0AGkAbwBuACAAPQAgADUAMAAwADAADQAKACAAIAAgACAAQQBkAGQALQBUAHkAcABlACAALQBBAHMAcwBlAG0AYgBsAHkATgBhAG0AZQAgAFMAeQBzAHQAZQBtAC4AVwBpAG4AZABvAHcAcwAuAEYAbwByAG0AcwANAAoAIAAgACAAIABbAFMAeQBzAHQAZQBtAC4AVwBpAG4AZABvAHcAcwAuAEYAbwByAG0AcwAuAE4AbwB0AGkAZgB5AEkAYwBvAG4AXQAkAE0AeQBOAG8AdABpAGYAaQBlAHIAIAA9ACAAWwBTAHkAcwB0AGUAbQAuAFcAaQBuAGQAbwB3AHMALgBGAG8AcgBtAHMALgBOAG8AdABpAGYAeQBJAGMAbwBuAF0AOgA6AG4AZQB3ACgAKQANAAoADQAKAA0ACgAgACAAIAAgACQASQBjAG8AbgBQAGEAdABoACAAPQAgACIAQwA6AFwARABPAEMAVQBNAEUATgBUAFMAXABQAG8AdwBlAHIAUwBoAGUAbABsAFwATQBvAGQAdQBsAGUAcwBcAFAAbwB3AGUAcgBTAGgAZQBsAGwALgBNAG8AZAB1AGwAZQAuAEQAbwB3AG4AbABvAGEAZABlAHIAXABlAHgAcABvAHIAdABzAFwAaQBjAG8AXAB5AG8AdQB0AHUAYgBlAF8AYwBvAGwAbwByAC4AaQBjAG8AIgANAAoAIAAgACAAIAAgACAAIAANAAoAIAAgACAAIAAkAE0AeQBOAG8AdABpAGYAaQBlAHIALgBJAGMAbwBuACAAPQAgAFsAUwB5AHMAdABlAG0ALgBEAHIAYQB3AGkAbgBnAC4ASQBjAG8AbgBdADoAOgBuAGUAdwAoACQASQBjAG8AbgBQAGEAdABoACkADQAKACAAIAAgACAADQAKAA0ACgAgACAAIAAgACQATQB5AE4AbwB0AGkAZgBpAGUAcgAuAEIAYQBsAGwAbwBvAG4AVABpAHAAVABlAHgAdAAgACAAPQAgACQAVABlAHgAdAANAAoAIAAgACAAIAAkAE0AeQBOAG8AdABpAGYAaQBlAHIALgBCAGEAbABsAG8AbwBuAFQAaQBwAFQAaQB0AGwAZQAgAD0AIAAkAFQAaQB0AGwAZQANAAoAIAAgACAAIAAkAE0AeQBOAG8AdABpAGYAaQBlAHIALgBWAGkAcwBpAGIAbABlACAAPQAgACQAdAByAHUAZQANAAoADQAKACAAIAAgACAAJABOAGUAdwBHAHUAaQBkACAAPQAgACgATgBlAHcALQBHAHUAaQBkACkALgBHAHUAaQBkAA0ACgAgACAAIAAgACQAVABpAG0AZQByAFMAaABvAHcAIAA9ACAATgBlAHcALQBPAGIAagBlAGMAdAAgAFQAaQBtAGUAcgBzAC4AVABpAG0AZQByAA0ACgAgACAAIAAgACQAVABpAG0AZQByAFMAaABvAHcALgBJAG4AdABlAHIAdgBhAGwAIAA9ACAAJABEAHUAcgBhAHQAaQBvAG4AIAArACAAMQAwADAAMAANAAoAIAAgACAAIAAkAFQAaQBtAGUAcgBTAGgAbwB3AC4AQQB1AHQAbwByAGUAcwBlAHQAIAA9ACAAJABUAHIAdQBlAA0ACgAgACAAIAAgACQAbwBiAGoAZQBjAHQARQB2AGUAbgB0AEEAcgBnAHMAIAA9ACAAQAB7AA0ACgAgACAAIAAgACAAIAAgACAASQBuAHAAdQB0AE8AYgBqAGUAYwB0ACAAPQAgACQAVABpAG0AZQByAFMAaABvAHcADQAKACAAIAAgACAAIAAgACAAIABFAHYAZQBuAHQATgBhAG0AZQAgAD0AIAAiAEUAbABhAHAAcwBlAGQAIgANAAoAIAAgACAAIAAgACAAIAAgAFMAbwB1AHIAYwBlAEkAZABlAG4AdABpAGYAaQBlAHIAIAA9ACAAIgAkAE4AZQB3AEcAdQBpAGQAIgANAAoAIAAgACAAIAB9AA0ACgAgACAAIAAgAFIAZQBnAGkAcwB0AGUAcgAtAE8AYgBqAGUAYwB0AEUAdgBlAG4AdAAgAEAAbwBiAGoAZQBjAHQARQB2AGUAbgB0AEEAcgBnAHMADQAKACAAIAAgACAAJABUAGkAbQBlAHIAUwBoAG8AdwAuAFMAdABhAHIAdAAoACkADQAKACAAIAAgACAAJABUAGkAbQBlAHIAUwBoAG8AdwAuAEUAbgBhAGIAbABlAGQAIAA9ACAAJABUAHIAdQBlAA0ACgAgACAAIAAgACQATQB5AE4AbwB0AGkAZgBpAGUAcgAuAFMAaABvAHcAQgBhAGwAbABvAG8AbgBUAGkAcAAoACQARAB1AHIAYQB0AGkAbwBuACkADQAKACAAIAAgACAAJABOAHUAbABsACAAPQAgAFcAYQBpAHQALQBFAHYAZQBuAHQAIAAiACQATgBlAHcARwB1AGkAZAAiAA0ACgAgACAAIAAgACQAVABpAG0AZQByAFMAaABvAHcALgBTAHQAbwBwACgAKQANAAoAIAAgACAAIABVAG4AcgBlAGcAaQBzAHQAZQByAC0ARQB2AGUAbgB0ACAALQBTAG8AdQByAGMAZQBJAGQAZQBuAHQAaQBmAGkAZQByACAAIgAkAE4AZQB3AEcAdQBpAGQAIgAgAC0ARQByAHIAbwByAEEAYwB0AGkAbwBuACAASQBnAG4AbwByAGUADQAKACAAIAAgACAAUgBlAG0AbwB2AGUALQBKAG8AYgAgAC0ATgBhAG0AZQAgAFQAaQBtAGUAcgAuAEUAbABhAHAAcwBlAGQAIAAtAEUAcgByAG8AcgBBAGMAdABpAG8AbgAgAEkAZwBuAG8AcgBlAA0ACgAgACAAIAAgACQAVABpAG0AZQByAFMAaABvAHcALgBEAGkAcwBwAG8AcwBlACgAKQANAAoAIAAgACAAIAAkAE0AeQBOAG8AdABpAGYAaQBlAHIALgBEAGkAcwBwAG8AcwBlACgAKQANAAoAfQANAAoATgBlAHcALQBUAHIAYQB5AE4AbwB0AGkAZgBpAGUAcgA=")
            Start-Process -FilePath $PwshExe -ArgumentList $ArgList -NoNewWindow
        }
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
        [bool]$ShowNotification=$True     
    )
    try{
        [string]$JobName = (New-Guid).Guid
        $JobName = $JobName.Replace('-','')
        $WgetExe          = Get-WGetExecutable
        Write-Debug "==============================================================================="
        Write-Debug "                         *** DEBUG Save-UsingWGetJob ***                       "
        Write-Debug "==============================================================================="

        Write-Debug "Asynchronous     : $Asynchronous"
        Write-Debug "DestinationPath  : $DestinationPath"
        Write-Debug "Url              : $Url"
        Write-Debug "DownloadMode     : $DownloadMode"
        Write-Debug "JobName          : $JobName"
        Write-Debug "=========================================================="
        

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
        $jobby = Start-Job -Name $JobName -ScriptBlock $WGetDownloadJobScriptBlock -ArgumentList ($Url,$DestinationPath,$WgetExe,$ShowNotification)
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

        $Res
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}

