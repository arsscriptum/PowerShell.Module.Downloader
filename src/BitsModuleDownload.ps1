<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  Http
#>



$BitsModuleCompleteJobListener = {
      param($JobName,$DestinationPath)
  
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
            Start-Sleep 1
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
                                        Write-Output "Job $JobName TRANSFERRED`n"
                                        Get-BitsTransfer -Name $JobName |  Complete-BitsTransfer
                                        Write-Output "COMPLETING Job $JobName"
                                        #Write-Output "$Ret"
                                        $CompletedListenerJob = "{0}_COMPLETE" -f $JobName
                                        $Logs = Receive-Job -Name $CompletedListenerJob -Wait -ErrorAction Ignore
                                        Write-LogEntry "$Logs" -f Gray
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
        [string]$Priority="Foreground"
    )
    try{

        $DestinationPath = Convert-DestinationPath $Url $DestinationPath

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
        $newcompletionjob = Start-Job -Name $CompletedListenerJob -ScriptBlock $BitsModuleCompleteScriptBlock -ArgumentList ($JobName,$DestinationPath)
        

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


