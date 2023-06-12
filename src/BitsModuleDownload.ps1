<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  Http
#>



$BitsModuleCompleteJobListener = {
      param($JobName,$DestinationPath,$ShowNotification)
  
    try{
        [string]$CurrentState  =  (Get-BitsTransfer -Name $JobName).JobState.ToString().ToUpper()
        [string]$CurrentState  =  $CurrentState.ToUpper()
        Write-LogEntry "bits job `"$JobName`"`t $CurrentState"
        $ProcessingDownload = $True
        $TotalTransientErrors = 0
        while($ProcessingDownload){
            [string]$CurrentState  =  (Get-BitsTransfer -Name $JobName).JobState.ToString().ToUpper()
            [string]$CurrentState  =  $CurrentState.ToUpper()
            Write-Output "Bits Job $JobName CurrentState $CurrentState"
            Start-Sleep -Milliseconds 200
            switch($CurrentState){
                'TRANSFERRING'      { 
                                        
                                    }
                'TRANSIENT_ERROR'   {
                                        if($TotalTransientErrors -gt 5){
                                            Write-Output "TRANSIENT_ERROR Occured! " -f DarkRed -n
                                            Write-Output "MAXIMUM REACHED. CANCELLING" -f DarkYellow
                                            Write-Output "Canceling in 3 seconds..." -f Gray
                                            3..1 | % { Write-Output "$_ " -n; Start-Sleep 1 }
                                            Write-Output "cancel bits job `"$JobName`""
                                            &"$BitsAdminExe" "/cancel" "$JobName" >> $TmpFile 
                                            $ProcessingDownload = $False
                                        }
                                        Write-Output "TRANSIENT_ERROR Occured! ($TotalTransientErrors so far)" -f DarkRed -n
                                        Write-Output "Restarting in 10 seconds..." -f Gray
                                        10..1 | % { Write-Output "$_ " -n; Start-Sleep 1 }
                                       
                                        $out = &"$BitsAdminExe" "/RAWRETURN" "/resume" "$JobName"
    
                                        $TotalTransientErrors++
                                    }
                'ERROR'             {
                                        $ErrorState   = &"$BitsAdminExe" "/RAWRETURN" "/GETERROR" "$JobName"
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
                                        if($ShowNotification){
                                            $ENV:NotifyTitle = "DOWNLOAD COMPLETE"
                                            $ENV:NotifyText = "$DestinationPath"
                                            $PwshExe = (Get-Command 'pwsh.exe').Source
                                            $ArgList = @("-nop","-noni","-encodedcommand", "ZgB1AG4AYwB0AGkAbwBuACAATgBlAHcALQBUAHIAYQB5AE4AbwB0AGkAZgBpAGUAcgB7AA0ACgAgACAAIAAgAFsAQwBtAGQAbABlAHQAQgBpAG4AZABpAG4AZwAoAFMAdQBwAHAAbwByAHQAcwBTAGgAbwB1AGwAZABQAHIAbwBjAGUAcwBzACkAXQANAAoAIAAgACAAIABwAGEAcgBhAG0AKAApAA0ACgAgACAAIAAgACQASQBjAG8AbgAgAD0AIAAiAHkAbwB1AHQAdQBiAGUAXwBjAG8AbABvAHIAIgANAAoAIAAgACAAIAAkAFQAaQB0AGwAZQAgAD0AIAAiACQARQBOAFYAOgBOAG8AdABpAGYAeQBUAGkAdABsAGUAIgANAAoAIAAgACAAIAAkAFQAZQB4AHQAIAA9ACAAIgAkAEUATgBWADoATgBvAHQAaQBmAHkAVABlAHgAdAAiAA0ACgAgACAAIAAgACQARAB1AHIAYQB0AGkAbwBuACAAPQAgADUAMAAwADAADQAKACAAIAAgACAAQQBkAGQALQBUAHkAcABlACAALQBBAHMAcwBlAG0AYgBsAHkATgBhAG0AZQAgAFMAeQBzAHQAZQBtAC4AVwBpAG4AZABvAHcAcwAuAEYAbwByAG0AcwANAAoAIAAgACAAIABbAFMAeQBzAHQAZQBtAC4AVwBpAG4AZABvAHcAcwAuAEYAbwByAG0AcwAuAE4AbwB0AGkAZgB5AEkAYwBvAG4AXQAkAE0AeQBOAG8AdABpAGYAaQBlAHIAIAA9ACAAWwBTAHkAcwB0AGUAbQAuAFcAaQBuAGQAbwB3AHMALgBGAG8AcgBtAHMALgBOAG8AdABpAGYAeQBJAGMAbwBuAF0AOgA6AG4AZQB3ACgAKQANAAoADQAKAA0ACgAgACAAIAAgACQASQBjAG8AbgBQAGEAdABoACAAPQAgACIAQwA6AFwARABPAEMAVQBNAEUATgBUAFMAXABQAG8AdwBlAHIAUwBoAGUAbABsAFwATQBvAGQAdQBsAGUAcwBcAFAAbwB3AGUAcgBTAGgAZQBsAGwALgBNAG8AZAB1AGwAZQAuAEQAbwB3AG4AbABvAGEAZABlAHIAXABlAHgAcABvAHIAdABzAFwAaQBjAG8AXAB5AG8AdQB0AHUAYgBlAF8AYwBvAGwAbwByAC4AaQBjAG8AIgANAAoAIAAgACAAIAAgACAAIAANAAoAIAAgACAAIAAkAE0AeQBOAG8AdABpAGYAaQBlAHIALgBJAGMAbwBuACAAPQAgAFsAUwB5AHMAdABlAG0ALgBEAHIAYQB3AGkAbgBnAC4ASQBjAG8AbgBdADoAOgBuAGUAdwAoACQASQBjAG8AbgBQAGEAdABoACkADQAKACAAIAAgACAADQAKAA0ACgAgACAAIAAgACQATQB5AE4AbwB0AGkAZgBpAGUAcgAuAEIAYQBsAGwAbwBvAG4AVABpAHAAVABlAHgAdAAgACAAPQAgACQAVABlAHgAdAANAAoAIAAgACAAIAAkAE0AeQBOAG8AdABpAGYAaQBlAHIALgBCAGEAbABsAG8AbwBuAFQAaQBwAFQAaQB0AGwAZQAgAD0AIAAkAFQAaQB0AGwAZQANAAoAIAAgACAAIAAkAE0AeQBOAG8AdABpAGYAaQBlAHIALgBWAGkAcwBpAGIAbABlACAAPQAgACQAdAByAHUAZQANAAoADQAKACAAIAAgACAAJABOAGUAdwBHAHUAaQBkACAAPQAgACgATgBlAHcALQBHAHUAaQBkACkALgBHAHUAaQBkAA0ACgAgACAAIAAgACQAVABpAG0AZQByAFMAaABvAHcAIAA9ACAATgBlAHcALQBPAGIAagBlAGMAdAAgAFQAaQBtAGUAcgBzAC4AVABpAG0AZQByAA0ACgAgACAAIAAgACQAVABpAG0AZQByAFMAaABvAHcALgBJAG4AdABlAHIAdgBhAGwAIAA9ACAAJABEAHUAcgBhAHQAaQBvAG4AIAArACAAMQAwADAAMAANAAoAIAAgACAAIAAkAFQAaQBtAGUAcgBTAGgAbwB3AC4AQQB1AHQAbwByAGUAcwBlAHQAIAA9ACAAJABUAHIAdQBlAA0ACgAgACAAIAAgACQAbwBiAGoAZQBjAHQARQB2AGUAbgB0AEEAcgBnAHMAIAA9ACAAQAB7AA0ACgAgACAAIAAgACAAIAAgACAASQBuAHAAdQB0AE8AYgBqAGUAYwB0ACAAPQAgACQAVABpAG0AZQByAFMAaABvAHcADQAKACAAIAAgACAAIAAgACAAIABFAHYAZQBuAHQATgBhAG0AZQAgAD0AIAAiAEUAbABhAHAAcwBlAGQAIgANAAoAIAAgACAAIAAgACAAIAAgAFMAbwB1AHIAYwBlAEkAZABlAG4AdABpAGYAaQBlAHIAIAA9ACAAIgAkAE4AZQB3AEcAdQBpAGQAIgANAAoAIAAgACAAIAB9AA0ACgAgACAAIAAgAFIAZQBnAGkAcwB0AGUAcgAtAE8AYgBqAGUAYwB0AEUAdgBlAG4AdAAgAEAAbwBiAGoAZQBjAHQARQB2AGUAbgB0AEEAcgBnAHMADQAKACAAIAAgACAAJABUAGkAbQBlAHIAUwBoAG8AdwAuAFMAdABhAHIAdAAoACkADQAKACAAIAAgACAAJABUAGkAbQBlAHIAUwBoAG8AdwAuAEUAbgBhAGIAbABlAGQAIAA9ACAAJABUAHIAdQBlAA0ACgAgACAAIAAgACQATQB5AE4AbwB0AGkAZgBpAGUAcgAuAFMAaABvAHcAQgBhAGwAbABvAG8AbgBUAGkAcAAoACQARAB1AHIAYQB0AGkAbwBuACkADQAKACAAIAAgACAAJABOAHUAbABsACAAPQAgAFcAYQBpAHQALQBFAHYAZQBuAHQAIAAiACQATgBlAHcARwB1AGkAZAAiAA0ACgAgACAAIAAgACQAVABpAG0AZQByAFMAaABvAHcALgBTAHQAbwBwACgAKQANAAoAIAAgACAAIABVAG4AcgBlAGcAaQBzAHQAZQByAC0ARQB2AGUAbgB0ACAALQBTAG8AdQByAGMAZQBJAGQAZQBuAHQAaQBmAGkAZQByACAAIgAkAE4AZQB3AEcAdQBpAGQAIgAgAC0ARQByAHIAbwByAEEAYwB0AGkAbwBuACAASQBnAG4AbwByAGUADQAKACAAIAAgACAAUgBlAG0AbwB2AGUALQBKAG8AYgAgAC0ATgBhAG0AZQAgAFQAaQBtAGUAcgAuAEUAbABhAHAAcwBlAGQAIAAtAEUAcgByAG8AcgBBAGMAdABpAG8AbgAgAEkAZwBuAG8AcgBlAA0ACgAgACAAIAAgACQAVABpAG0AZQByAFMAaABvAHcALgBEAGkAcwBwAG8AcwBlACgAKQANAAoAIAAgACAAIAAkAE0AeQBOAG8AdABpAGYAaQBlAHIALgBEAGkAcwBwAG8AcwBlACgAKQANAAoAfQANAAoATgBlAHcALQBUAHIAYQB5AE4AbwB0AGkAZgBpAGUAcgA=")
                                            Start-Process -FilePath $PwshExe -ArgumentList $ArgList -NoNewWindow
                                        }
                                        Write-Output "Job $JobName TRANSFERRED`n"
                                        Get-BitsTransfer -Name $JobName |  Complete-BitsTransfer
                                        Write-Output "COMPLETING Job $JobName"
                                        #Write-Output "$Ret"
                                        $CompletedListenerJob = "{0}_COMPLETE" -f $JobName
                                        $Logs = Receive-Job -Name $CompletedListenerJob -Wait -ErrorAction Ignore
                                        Write-LogEntry "$Logs" -f Gray
                                        $BitsAdminExe = Get-BitsAdminExecutable
                                        &"$BitsAdminExe" "/complete" "$JobName" *> "$ENV:Temp\temp.txt"
                                        $ProcessingDownload = $False
   
                                        
                                    }
                
                default             {}
            } # SWITCH
        } # WHILE

    }catch{
        Write-Error $_
    }finally{
        if(Test-Path "$DestinationPath"){
            Write-Output "$DestinationPath"
        }
        
}}.GetNewClosure()

[scriptblock]$BitsModuleCompleteScriptBlock = [scriptblock]::create($BitsModuleCompleteJobListener) 

function Save-UsingBitsModule{
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
        $Params = @{
            DisplayName    = $JobName
            Source         = "$Url"
            Destination    = "$DestinationPath"
            Priority       = $Priority
            RetryInterval  = 120
            RetryTimeout   = 180000
            Suspended      = $True
            NotifyFlags    = 'JobTransferred'
        }



        <#
            NotifyFlags

            BG_NOTIFY_JOB_TRANSFERRED   0x0001      All of the files in the job have been transferred.
            BG_NOTIFY_JOB_ERROR         0x0002      An error has occurred.
            BG_NOTIFY_DISABLE           0x0004      Event notification is disabled. BITS ignores the other flags.
            BG_NOTIFY_JOB_MODIFICATION  0x0008      The job has been modified. For example, a property value changed.
            BG_NOTIFY_FILE_TRANSFERRED  0x0010      A file in the job has been transferred. This flag is ignored in command-line callbacks if command line notification is specified. \
            BG_NOTIFY_FILE_RANGES_TRANSFERRED   0x0020 A range of bytes in the file has been transferred. 
        #>


        if($EnableNotification -eq $True){
            $ExportsPath = Get-DownloaderModuleExportsPath
            $DownloadCompletedPath = (Join-Path $ExportsPath "DownloadCompleted.exe")  
            if(Test-Path "$DownloadCompletedPath"){
                Write-LogEntry "SetNotifyCmdLine `"$DownloadCompletedPath`""
                $Params['NotifyCmdLine'] = "$DownloadCompletedPath"
            } 
        }

        $ProgressTitle = "MODE: BITSMODULE [$JobName]"
        $Mod = Import-module BitsTransfer -PassThru -Force
        if($Null -eq $Mod) { throw "CANNOT LOAD MODULE" }
        Write-LogEntry "Create bits job `"$JobName`""
        $BitsJob = Start-BitsTransfer @Params
        Start-Sleep -Milliseconds 500
        Write-LogEntry "Start bits job `"$JobName`""
        $BitsJob | Resume-BitsTransfer -Asynchronous:$Asynchronous

        $CompletedListenerJob = "{0}_COMPLETE" -f $JobName
        Write-LogEntry "Start job CompletedListenerJob `"$CompletedListenerJob`""
        $newcompletionjob = Start-Job -Name $CompletedListenerJob -ScriptBlock $BitsModuleCompleteScriptBlock -ArgumentList ($JobName,$DestinationPath,$ShowNotification)
        

        $RetObj = [pscustomobject]@{
            OutFilePath = $DestinationPath
            JobName = $JobName
        }
        $RetObj
    }catch{
        Write-Error $_
    }finally{


    }
}


