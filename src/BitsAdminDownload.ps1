<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  Http
#>


function Get-BitsAdminExecutable{
    [CmdletBinding(SupportsShouldProcess)]
    param()

   try{
        $Cmd = Get-Command -Name 'bitsadmin.exe' -ErrorAction Ignore
        if($Cmd -eq $Null) { throw "Cannot find bitsadmin.exe" }
        $BitsAdminExe = $Cmd.Source
        if(-not(Test-Path $BitsAdminExe)){ throw "cannot fin bitsadmin executable. is it installed ?" }
        return $BitsAdminExe
    }catch{
        Show-ExceptionDetails $_
    }
    return $Null
}


function Invoke-BitsAdmin{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Command,
        [Parameter(Mandatory=$false, Position=1)]
        [string]$JobName,  
        [Parameter(Mandatory=$false, Position=2)]
        [string]$Option1,
        [Parameter(Mandatory=$false, Position=3)]
        [string]$Option2,
        [Parameter(Mandatory=$false, Position=4)]
        [string]$Option3
    )


   try{
        $BitsAdminExe = Get-BitsAdminExecutable
        [string]$ResultString = &"$BitsAdminExe" "/RAWRETURN" "/$Command" "$JobName" "$Option1" "$Option2" "$Option3" 
        $SuccessFlag = $?
        
        if($SuccessFlag -eq $False){
            Show-InternalMiniErrorPopup "$ResultString" "BITSADMIN ERROR $Command"
        }
        $ResultString
    }catch{
        Show-ExceptionDetails $_
    }
}


New-Alias -Name 'CallBitsAdm' -Value Invoke-BitsAdmin -Force -ErrorAction Ignore


$BitsAdminCompleteJobListener = {
      param($BitsAdminExe, $JobName,$DestinationPath,$ShowNotification)
  
    try{
        $TmpFile = "$ENV:Temp\$JobName.log"
        $ProcessingDownload = $True
        $TotalTransientErrors = 0
        while($ProcessingDownload){
            $CurrentJobState  = &"$BitsAdminExe" "/RAWRETURN" "/GETSTATE" "$JobName"
            Start-Sleep 1
            switch($CurrentJobState){
                'TRANSFERRING'      { 
                                    }
                'TRANSIENT_ERROR'   {
                                        if($TotalTransientErrors -gt 5){
                                            Write-Output "TRANSIENT_ERROR Occured! " -f DarkRed -n
                                            Write-Output "MAXIMUM REACHED. CANCELLING" -f DarkYellow
                                            Write-Output "Canceling in 3 seconds..." -f Gray
                                            3..1 | % { Write-Output "$_ " -n; Start-Sleep 1 }
                                            Write-Output "cancel bits job `"$JobName`""
                                            $CurrentJobState  = &"$BitsAdminExe" "/RAWRETURN" "/cancel" "$JobName" 
                                            $ProcessingDownload = $False
                                        }
                                        Write-Output "TRANSIENT_ERROR Occured! ($TotalTransientErrors so far)" -f DarkRed -n
                                        Write-Output "Restarting in 10 seconds..." -f Gray
                                        10..1 | % { Write-Output "$_ " -n; Start-Sleep 1 }
                                       
                                        &"$BitsAdminExe" "/RAWRETURN" "/resume" "$JobName" >> $TmpFile 
    
                                        $TotalTransientErrors++
                                    }
                'ERROR'             {
                                        $ErrorState = &"$BitsAdminExe" "/RAWRETURN" "/GETERROR" "$JobName"
                                        $ErrorFile = $ErrorState[0]
                                        $ErrorCode = $ErrorState[1]
                                        $ErrorContext = $ErrorState[3]
                                        $ErrorFiles = $ErrorFile.Split('->')
                                        $ErrorSourceFile = $ErrorFiles[0].Trim()
                                        $ErrorDestinationFile = 'DESTINATION: ' + $ErrorFiles[1].Trim()
                                        if($ErrorSourceFile.Length -gt 100){
                                            $ErrorSourceFile = $ErrorSourceFile.Substring(0,100).Replace('ERROR FILE:    ', 'SOURCE URL : ')
                                            $ErrorSourceFile += '....'
                                        }
                                        $ErrorMessage = @"


$ErrorCode

$ErrorContext

$ErrorSourceFile

$ErrorDestinationFile                                   
"@
                                        Show-InternalMiniErrorPopup $ErrorMessage -Title "Job $JobName ERROR"
                                        Write-Output "Job $JobName ERROR"
                                        $ProcessingDownload = $False
                                    }


                'SUSPENDED'         {
                                        Write-Output "Job $JobName SUSPENDED"
                                    }
                
                'TRANSFERRED'       {
                                        &"$BitsAdminExe" "/complete" "$JobName" *> "$ENV:Temp\temp.txt"
                                        $ProcessingDownload = $False
                                        if($ShowNotification -eq $True){
                                            $ENV:NotifyTitle = "DOWNLOAD COMPLETE"
                                            $ENV:NotifyText = "$DestinationPath"
                                            $PwshExe = (Get-Command 'pwsh.exe').Source
                                            $ArgList = @("-nop","-noni","-encodedcommand", "ZgB1AG4AYwB0AGkAbwBuACAATgBlAHcALQBUAHIAYQB5AE4AbwB0AGkAZgBpAGUAcgB7AA0ACgAgACAAIAAgAFsAQwBtAGQAbABlAHQAQgBpAG4AZABpAG4AZwAoAFMAdQBwAHAAbwByAHQAcwBTAGgAbwB1AGwAZABQAHIAbwBjAGUAcwBzACkAXQANAAoAIAAgACAAIABwAGEAcgBhAG0AKAApAA0ACgAgACAAIAAgACQASQBjAG8AbgAgAD0AIAAiAHkAbwB1AHQAdQBiAGUAXwBjAG8AbABvAHIAIgANAAoAIAAgACAAIAAkAFQAaQB0AGwAZQAgAD0AIAAiACQARQBOAFYAOgBOAG8AdABpAGYAeQBUAGkAdABsAGUAIgANAAoAIAAgACAAIAAkAFQAZQB4AHQAIAA9ACAAIgAkAEUATgBWADoATgBvAHQAaQBmAHkAVABlAHgAdAAiAA0ACgAgACAAIAAgACQARAB1AHIAYQB0AGkAbwBuACAAPQAgADUAMAAwADAADQAKACAAIAAgACAAQQBkAGQALQBUAHkAcABlACAALQBBAHMAcwBlAG0AYgBsAHkATgBhAG0AZQAgAFMAeQBzAHQAZQBtAC4AVwBpAG4AZABvAHcAcwAuAEYAbwByAG0AcwANAAoAIAAgACAAIABbAFMAeQBzAHQAZQBtAC4AVwBpAG4AZABvAHcAcwAuAEYAbwByAG0AcwAuAE4AbwB0AGkAZgB5AEkAYwBvAG4AXQAkAE0AeQBOAG8AdABpAGYAaQBlAHIAIAA9ACAAWwBTAHkAcwB0AGUAbQAuAFcAaQBuAGQAbwB3AHMALgBGAG8AcgBtAHMALgBOAG8AdABpAGYAeQBJAGMAbwBuAF0AOgA6AG4AZQB3ACgAKQANAAoADQAKAA0ACgAgACAAIAAgACQASQBjAG8AbgBQAGEAdABoACAAPQAgACIAQwA6AFwARABPAEMAVQBNAEUATgBUAFMAXABQAG8AdwBlAHIAUwBoAGUAbABsAFwATQBvAGQAdQBsAGUAcwBcAFAAbwB3AGUAcgBTAGgAZQBsAGwALgBNAG8AZAB1AGwAZQAuAEQAbwB3AG4AbABvAGEAZABlAHIAXABlAHgAcABvAHIAdABzAFwAaQBjAG8AXAB5AG8AdQB0AHUAYgBlAF8AYwBvAGwAbwByAC4AaQBjAG8AIgANAAoAIAAgACAAIAAgACAAIAANAAoAIAAgACAAIAAkAE0AeQBOAG8AdABpAGYAaQBlAHIALgBJAGMAbwBuACAAPQAgAFsAUwB5AHMAdABlAG0ALgBEAHIAYQB3AGkAbgBnAC4ASQBjAG8AbgBdADoAOgBuAGUAdwAoACQASQBjAG8AbgBQAGEAdABoACkADQAKACAAIAAgACAADQAKAA0ACgAgACAAIAAgACQATQB5AE4AbwB0AGkAZgBpAGUAcgAuAEIAYQBsAGwAbwBvAG4AVABpAHAAVABlAHgAdAAgACAAPQAgACQAVABlAHgAdAANAAoAIAAgACAAIAAkAE0AeQBOAG8AdABpAGYAaQBlAHIALgBCAGEAbABsAG8AbwBuAFQAaQBwAFQAaQB0AGwAZQAgAD0AIAAkAFQAaQB0AGwAZQANAAoAIAAgACAAIAAkAE0AeQBOAG8AdABpAGYAaQBlAHIALgBWAGkAcwBpAGIAbABlACAAPQAgACQAdAByAHUAZQANAAoADQAKACAAIAAgACAAJABOAGUAdwBHAHUAaQBkACAAPQAgACgATgBlAHcALQBHAHUAaQBkACkALgBHAHUAaQBkAA0ACgAgACAAIAAgACQAVABpAG0AZQByAFMAaABvAHcAIAA9ACAATgBlAHcALQBPAGIAagBlAGMAdAAgAFQAaQBtAGUAcgBzAC4AVABpAG0AZQByAA0ACgAgACAAIAAgACQAVABpAG0AZQByAFMAaABvAHcALgBJAG4AdABlAHIAdgBhAGwAIAA9ACAAJABEAHUAcgBhAHQAaQBvAG4AIAArACAAMQAwADAAMAANAAoAIAAgACAAIAAkAFQAaQBtAGUAcgBTAGgAbwB3AC4AQQB1AHQAbwByAGUAcwBlAHQAIAA9ACAAJABUAHIAdQBlAA0ACgAgACAAIAAgACQAbwBiAGoAZQBjAHQARQB2AGUAbgB0AEEAcgBnAHMAIAA9ACAAQAB7AA0ACgAgACAAIAAgACAAIAAgACAASQBuAHAAdQB0AE8AYgBqAGUAYwB0ACAAPQAgACQAVABpAG0AZQByAFMAaABvAHcADQAKACAAIAAgACAAIAAgACAAIABFAHYAZQBuAHQATgBhAG0AZQAgAD0AIAAiAEUAbABhAHAAcwBlAGQAIgANAAoAIAAgACAAIAAgACAAIAAgAFMAbwB1AHIAYwBlAEkAZABlAG4AdABpAGYAaQBlAHIAIAA9ACAAIgAkAE4AZQB3AEcAdQBpAGQAIgANAAoAIAAgACAAIAB9AA0ACgAgACAAIAAgAFIAZQBnAGkAcwB0AGUAcgAtAE8AYgBqAGUAYwB0AEUAdgBlAG4AdAAgAEAAbwBiAGoAZQBjAHQARQB2AGUAbgB0AEEAcgBnAHMADQAKACAAIAAgACAAJABUAGkAbQBlAHIAUwBoAG8AdwAuAFMAdABhAHIAdAAoACkADQAKACAAIAAgACAAJABUAGkAbQBlAHIAUwBoAG8AdwAuAEUAbgBhAGIAbABlAGQAIAA9ACAAJABUAHIAdQBlAA0ACgAgACAAIAAgACQATQB5AE4AbwB0AGkAZgBpAGUAcgAuAFMAaABvAHcAQgBhAGwAbABvAG8AbgBUAGkAcAAoACQARAB1AHIAYQB0AGkAbwBuACkADQAKACAAIAAgACAAJABOAHUAbABsACAAPQAgAFcAYQBpAHQALQBFAHYAZQBuAHQAIAAiACQATgBlAHcARwB1AGkAZAAiAA0ACgAgACAAIAAgACQAVABpAG0AZQByAFMAaABvAHcALgBTAHQAbwBwACgAKQANAAoAIAAgACAAIABVAG4AcgBlAGcAaQBzAHQAZQByAC0ARQB2AGUAbgB0ACAALQBTAG8AdQByAGMAZQBJAGQAZQBuAHQAaQBmAGkAZQByACAAIgAkAE4AZQB3AEcAdQBpAGQAIgAgAC0ARQByAHIAbwByAEEAYwB0AGkAbwBuACAASQBnAG4AbwByAGUADQAKACAAIAAgACAAUgBlAG0AbwB2AGUALQBKAG8AYgAgAC0ATgBhAG0AZQAgAFQAaQBtAGUAcgAuAEUAbABhAHAAcwBlAGQAIAAtAEUAcgByAG8AcgBBAGMAdABpAG8AbgAgAEkAZwBuAG8AcgBlAA0ACgAgACAAIAAgACQAVABpAG0AZQByAFMAaABvAHcALgBEAGkAcwBwAG8AcwBlACgAKQANAAoAIAAgACAAIAAkAE0AeQBOAG8AdABpAGYAaQBlAHIALgBEAGkAcwBwAG8AcwBlACgAKQANAAoAfQANAAoATgBlAHcALQBUAHIAYQB5AE4AbwB0AGkAZgBpAGUAcgA=")
                                            Start-Process -FilePath $PwshExe -ArgumentList $ArgList -NoNewWindow
                                        }
                                    }
                
                default             {}
            } # SWITCH
        } # WHILE

    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }finally{
        if(Test-Path "$DestinationPath"){
            Write-Output "$DestinationPath"
        }
        
}}.GetNewClosure()

[scriptblock]$BitsAdminCompleteJobScriptBlock = [scriptblock]::create($BitsAdminCompleteJobListener) 


function Save-UsingBitsAdmin{
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
        [string]$Priority="Foreground",    
        [Parameter(Mandatory=$false)]
        [bool]$ShowNotification=$True   
    )
    try{

        $JobName = New-JobName
        Write-LogEntry "Save-UsingBitsAdmin `"$JobName`" Asynchronous $Asynchronous"
        $TmpFile = New-TmpFileName
        Remove-Item $TmpFile -Force -ErrorAction Ignore | Out-Null
        New-Item $TmpFile -Force -ItemType file -ErrorAction Ignore | Out-Null
        $BitsAdminExe = Get-BitsAdminExecutable

        Write-LogEntry "Create bits job `"$JobName`""
        [string]$Log = CallBitsAdm "create" "/download" "$JobName" 

        Start-Sleep -Milliseconds 100
        Write-LogEntry "addfile to bitsjob `"$JobName`" `"$DestinationPath`""
        CallBitsAdm "addfile" "$JobName" "$Url" "$DestinationPath" 

        Start-Sleep -Milliseconds 100



        <#
            NotifyFlags
            
            BG_NOTIFY_JOB_TRANSFERRED   0x0001      All of the files in the job have been transferred.
            BG_NOTIFY_JOB_ERROR         0x0002      An error has occurred.
            BG_NOTIFY_DISABLE           0x0004      Event notification is disabled. BITS ignores the other flags.
            BG_NOTIFY_JOB_MODIFICATION  0x0008      The job has been modified. For example, a property value changed.
            BG_NOTIFY_FILE_TRANSFERRED  0x0010      A file in the job has been transferred. This flag is ignored in command-line callbacks if command line notification is specified. \
            BG_NOTIFY_FILE_RANGES_TRANSFERRED   0x0020 A range of bytes in the file has been transferred. 
        #>

        if($EnableNotification){
            $ExportsPath = Get-DownloaderModuleExportsPath
            $DownloadCompletedPath = (Join-Path $ExportsPath "DownloadCompleted.exe")  

            if(Test-Path "$DownloadCompletedPath"){
                Write-LogEntry "SetNotifyCmdLine `"$DownloadCompletedPath`""
                CallBitsAdm "SETNOTIFYCMDLINE" "$JobName" "$DownloadCompletedPath" "$JobName" >> $TmpFile 
                Write-LogEntry "SetNotifyflags `"1`""
                CallBitsAdm "SetNotifyflags" "$JobName" "16" "$JobName" >> $TmpFile 
            } 
        }

        Start-Sleep -Milliseconds 100
        Write-LogEntry "Set Job `"$JobName`" priority to $Priority " -n
        $Ret = CallBitsAdm "SetPRIORITY" "$JobName" "$Priority"
        Write-LogEntry "$Ret"

        Start-Sleep -Milliseconds 100
        Write-LogEntry "Start bits job `"$JobName`""
        &"$BitsAdminExe" "/resume" "$JobName" >> $TmpFile 
        # Create a timer
        $timer_main =  [system.diagnostics.stopwatch]::StartNew()

        $BitsAdminExe = Get-BitsAdminExecutable
        $CompletedListenerJob = "{0}_COMPLETE" -f $JobName
        Write-LogEntry "Start job CompletedListenerJob `"$CompletedListenerJob`""
        $newcompletionjob = Start-Job -Name $CompletedListenerJob -ScriptBlock $BitsAdminCompleteJobScriptBlock -ArgumentList ($BitsAdminExe,$JobName,$DestinationPath,$ShowNotification)

        if($Asynchronous -eq $False){
            Receive-BitsAdminJob $JobName
        }else{
            Write-LogEntry "Asynchronous mode. To get progress, call `"Receive-BitsAdminJob $JobName`""
        }


    }catch{
        Write-Error $_
    }finally{

        $CurrentJobState   = CallBitsAdm "GETSTATE" "$JobName"

        $RetObj = [pscustomobject]@{
            OutFilePath = $DestinationPath
            JobName = $JobName
        }
        
        if($Asynchronous -eq $False){
            if($CurrentJobState -eq 'TRANSFERRING'){
                Write-LogEntry "[TRANSFER TERMINATED] " -f DarkRed
                $Ret = CallBitsAdm "CANCEL" "$JobName"
                Write-LogEntry "[CANCELLING $JobName] " -f DarkRed -n
                Write-LogEntry "$Ret" -f Yellow
                
            }
        }else{
            Write-LogEntry "[ASYNC TRANSFER] " -f Gray -n
            Write-LogEntry "CurrentState is $CurrentJobState" -f DarkGray
            
        }
        $RetObj
    }
}




function Receive-BitsAdminJob{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="JobName", Position=0)]
        [string]$JobName
    )

    try{
        $TmpFile = New-TmpFileName
        Remove-Item $TmpFile -Force -ErrorAction Ignore | Out-Null
        New-Item $TmpFile -Force -ItemType file -ErrorAction Ignore | Out-Null
        $BitsAdminExe = Get-BitsAdminExecutable
        [string]$CurrentJobState  = CallBitsAdm "GETSTATE" "$JobName"  

        [int]$TotalTransientErrors = 0
        [string]$StrBytesTotal     = CallBitsAdm "GETBYTESTOTAL" "$JobName" 
        if($StrBytesTotal.Length -gt 10){
            Write-LogEntry "GETBYTESTOTAL returns INVALID $StrBytesTotal"
            Start-Sleep 1
            [string]$StrBytesTotal     = CallBitsAdm "GETBYTESTOTAL" "$JobName" 
            if($StrBytesTotal.Length -gt 10){ throw  "GETBYTESTOTAL returns INVALID $StrBytesTotal" } 
        }
        [int]$BytesTotal  = $StrBytesTotal
        [datetime]$JobCreationTime     = CallBitsAdm "GETCREATIONTIME" "$JobName" 
        [int]$raw_elapsed_milliseconds = ([datetime]::Now - $JobCreationTime).TotalMilliseconds
        [int]$elapsed_milliseconds = [math]::Round($raw_elapsed_milliseconds,0)

        [int]$ProgressPercent = 0

        Start-Sleep -Milliseconds 200
        [int]$BytesReceived  = CallBitsAdm "GETBYTESTRANSFERRED" "$JobName"  
        Start-Sleep -Milliseconds 200

        [string]$BytesReceivedStr = Get-FormattedBytes($BytesReceived)
        [string]$BytesTotalStr = Get-FormattedBytes($BytesTotal)
        [string]$ProgressStatusMessage = "Downloaded {0} of {1} . " -f "$BytesReceivedStr","$BytesTotalStr"
        [string]$ProgressTitle = "MODE: BITS [$JobName]"
    
        Write-LogEntry "bits job `"$JobName`"`t$ProgressStatusMesage"
        $ProcessingDownload = $True
        while($ProcessingDownload){
            [string]$CurrentJobState   = CallBitsAdm "GETSTATE" "$JobName"
            Start-Sleep 1
            switch($CurrentJobState){
                'TRANSFERRING'      {
                                        [string]$StrBytesReceived  = CallBitsAdm "GETBYTESTRANSFERRED" "$JobName"
                                        [int]$BytesReceived = $StrBytesReceived
                                        
                                        [int]$raw_percentage = ($BytesReceived / $BytesTotal)*100
                                        [int]$ProgressPercent =  [math]::Round($raw_percentage,0)
                                        if($ProgressPercent  -lt 1){  $ProgressPercent = 1 ; }
                                        if($ProgressPercent  -gt 100){  $ProgressPercent = 100 ; }

                                        [datetime]$JobCreationTime     = CallBitsAdm "GETCREATIONTIME" "$JobName" 
                                        [int]$raw_elapsed_milliseconds = ([datetime]::Now - $JobCreationTime).TotalMilliseconds
                                        [int]$elapsed_milliseconds = [math]::Round($raw_elapsed_milliseconds,0)
                                        [int]$raw_estimated_total_ms = (100 / $ProgressPercent) * $raw_elapsed_milliseconds
                                        [int]$estimated_total_ms = [math]::Round($raw_estimated_total_ms,0)
                                        [int]$remaining_ms = $raw_estimated_total_ms - $raw_elapsed_milliseconds
                
                                        [string]$str_total_time = Get-TimeString($remaining_ms)

                                        [string]$BytesReceivedStr = Get-FormattedBytes($BytesReceived)
                                        [string]$BytesTotalStr = Get-FormattedBytes($BytesTotal)
                                        [string]$ProgressStatusMesage = "Downloaded {0} of {1} . Estimated time remaining {2}" -f "$BytesReceivedStr","$BytesTotalStr","$str_total_time" 
                                        Write-Progress -Activity $ProgressTitle -Status "$ProgressStatusMesage" -PercentComplete $ProgressPercent 
                                    }
                'TRANSIENT_ERROR'   {
                                        if($TotalTransientErrors -gt 5){
                                            Write-LogEntry "TRANSIENT_ERROR Occured! " -f DarkRed -n
                                            Write-LogEntry "MAXIMUM REACHED. CANCELLING" -f DarkYellow
                                            Write-LogEntry "Canceling in 3 seconds..." -f Gray
                                            3..1 | % { Write-LogEntry "$_ " -n; Start-Sleep 1 }
                                            Write-LogEntry "cancel bits job `"$JobName`""
                                            &"$BitsAdminExe" "/cancel" "$JobName" >> $TmpFile 
                                            $ProcessingDownload = $False
                                        }
                                        Write-LogEntry "TRANSIENT_ERROR Occured! ($TotalTransientErrors so far)" -f DarkRed -n
                                        Write-LogEntry "Restarting in 10 seconds..." -f Gray
                                        10..1 | % { Write-LogEntry "$_ " -n; Start-Sleep 1 }
                                        Write-LogEntry "Start bits job `"$JobName`""
                                        &"$BitsAdminExe" "/resume" "$JobName" >> $TmpFile 
                                        $ProcessingDownload = $True
                                        $TotalTransientErrors++
                                    }
                'ERROR'             {
                                        $ErrorDetails   = CallBitsAdm "GETERROR" "$JobName"
                                        Write-LogEntry "Critical Error Occured! " -f DarkRed -n
                                        Write-LogEntry "$ErrorDetails" -f DarkYellow
                                        Write-LogEntry "Canceling in 3 seconds..." -f Gray
                                        3..1 | % { Write-LogEntry "$_ " -n; Start-Sleep 1 }
                                        Write-LogEntry "cancel bits job `"$JobName`""
                                        &"$BitsAdminExe" "/cancel" "$JobName" >> $TmpFile 
                                        $ProcessingDownload = $False
                                    }


                'SUSPENDED'         {
                                        Write-LogEntry "TRANSFER SUSPENDED! " -f DarkYellow -n
                                        Write-LogEntry "Restarting job in 3 seconds..." -f Gray
                                        3..1 | % { Write-LogEntry "$_ " -n; Start-Sleep 1 }
                                        Write-LogEntry "Resuming bits job `"$JobName`""
                                        &"$BitsAdminExe" "/resume" "$JobName" >> $TmpFile 
                                        $ProcessingDownload = $True
                                    }
                
                'TRANSFERRED'       {
                                        Write-LogEntry "TRANSFER COMPLETED! " -f DarkGreen
                                        $CompletedListenerJob = "{0}_COMPLETE" -f $JobName
                                        $Logs = Receive-Job -Name $CompletedListenerJob -Wait -ErrorAction Ignore
                                        &"$BitsAdminExe" "/complete" "$JobName" >> $TmpFile 
                                        $ProcessingDownload = $False
                                    }
                
                default             {}
            } # SWITCH
        } # WHILE

    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}

