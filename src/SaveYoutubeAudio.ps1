
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


function Invoke-YoutubeDlAudio{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Url,
        [Parameter(Mandatory=$false)]
        [ValidateSet("best", "aac", "flac", "mp3", "m4a", "opus", "vorbis","wav")]
        [string]$AudioFormat="best",
        [Parameter(Mandatory=$false)]
        [int]$AudioQuality=5,
        [Parameter(Mandatory=$false)]
        [int]$VideoFormat,
        [Parameter(Mandatory=$false)]
        [String]$OutputDir = "E:\Download\YoutubeDownloader",
        [Parameter(Mandatory=$false)]
        [switch]$Asynchronous,
        [Parameter(Mandatory=$false)]
        [switch]$Quiet,
        [Parameter(Mandatory=$false)]
        [switch]$CompletedNotification,
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Download Mode", Position=2)]
        [ValidateSet('job','process')]
        [string]$DownloadMode="process"
    )
   
    $YoutubeDlPath = Get-YoutubeDlPath
    try{
        Push-Location $OutputDir

        if(-not (test-path $OutputDir)){
            throw "cannot find Output Dir"
        }
       
        $alist = @('--extract-audio')
        if($WhatIf){
            $alist +=  '--skip-download'
        }
        if($PSBoundParameters.ContainsKey('AudioQuality')){
            $alist +=  '--audio-quality'
            $alist +=  "$AudioQuality"
        }
        if($PSBoundParameters.ContainsKey('AudioFormat')){
            $alist +=  '--audio-format'
            $alist +=  "$AudioFormat"
        }
        if($PSBoundParameters.ContainsKey('VideoFormat')){
            $alist +=  '--format'
            $alist +=  "$VideoFormat"
        }
        $alist += $Url
        Write-Host "SaveYoutubeAudio    $Url"
        Write-Host "ExePath             $YoutubeDlPath"
        Write-Host "ArgumentList        $alist"
        Write-Host "WorkingDirectory    $OutputDir"

        # Generate a UNIQUE JOB NAME, but easy to use, not a GUID with 64 chars...
        [string]$JobName = (Get-Date).GetDateTimeFormats()[113]
        $JobName = $JobName.Replace(':',"").Replace('0',"")
        $v1 = Get-Random -Maximum 25 -Minimum 1
        $v2 = Get-Random -Maximum 25 -Minimum 1
        $arrrnd = @($v1,$v2)
        $arrrnd | % { $JobName += [char]($_ + 65) }

        # This JOB will output logs to a file so we can get the progress data.
        # Since we may run multiple jobs in parallel, the files ust be unique
        $TmpProgressFile = "$ENV:Temp\progress_$JobName.txt"
        $ProgressPattern = '^(\s*)(?<state>\[download\])(\s*)(?<Percent>[0-9\.\%]*)(\s*)(of)(\s*)(?<BytesTotal>[0-9\.\%]*)(?<Multiplier>[a-zA-Z]*)(\s*)(at)(\s*)(?<Speed>[0-9\.\%]*)(?<Multiplier2>[a-zA-Z\/]*)(\s*)(ETA)(\s*)(?<TimeRemaining>[0-9\:]*)'
                        
        switch( $DownloadMode ){

            'process'   {
                            $psargs = @{
                                ExePath = $YoutubeDlPath
                                ArgumentList = $alist
                                WorkingDirectory = $OutputDir
                            }
                            Invoke-Process @psargs 
                            $completed_msg = "Download complete" 
                            if($CompletedNotification){
                                $ok = Show-InternalMiniPopup -Title "TRANSFER COMPLETED" -Message $completed_msg -Icon 'Exclamation'
                            }
                        }

            'job'   {
                        $downloadVideoJob = {
                                param([string]$ExePath,[string]$url,[string]$WorkingDirectory)   
                                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                                pushd $WorkingDirectory
                                &"$ExePath" '--extract-audio' "$url"
                                $Null = Remove-Item -Path tmpfile -Force -ErrorAction Ignore
                                $totalMs = $stopwatch.Elapsed.TotalMilliseconds
                                popd 
                                Write-Output "$totalMs"
                        }
                        $ProgressTitle = "POWERSHELL JOB - YOUTUBE-DL"
                        Write-LogEntry "Start job `"$JobName`" Asynchronous $Asynchronous"
                        $jobby = Start-Job -Name $JobName -ScriptBlock $downloadVideoJob -ArgumentList ($YoutubeDlPath,$Url,$OutputDir)
                        $Transferring  = $True
                        if($Asynchronous){ 
                            Write-LogEntry "Asynchronous Mode..."
                            $Res = $jobby | Receive-Job
                            return
                        }else{
                            while($Transferring){
                                $JobState = (Get-Job -Name $JobName).State
                                if($JobState -eq 'Completed'){
                                    $Transferring = $False
                                }
                                Start-Sleep -Milliseconds 200
                                Receive-Job -Name $JobName *>> $TmpProgressFile
                               
                                $str = Get-Content $TmpProgressFile -Tail 1
                                if($str -match $ProgressPattern){
                                    $BytesTotal = $Matches.BytesTotal
                                    $Speed = $Matches.Speed
                                    $Mult2 = $Matches.Multiplier2
                                    $Time = $Matches.TimeRemaining
                                    $Percent = $Matches.Percent
                                    [int]$PercentNum = $Percent.Replace('%','')
                                    $PercentNum =[math]::Round($PercentNum)
                                    $ProgressStatusMesage = "Downloaded {0} of {1} at {2}{3}. Time remaining {4}" -f $Percent,$BytesTotal,$Speed,$Mult2,$Time
                                    Write-verbose "$ProgressStatusMesage"
                                    Write-Progress -Activity $ProgressTitle -Status "$ProgressStatusMesage" -PercentComplete $PercentNum 
                                }
                            }
                            $Res = $jobby | Receive-Job -Wait
                            $completed_msg = "Downloaded in {0:f2} seconds" -f ($Res / 1000)
                            if($CompletedNotification){
                                $ok = Show-InternalMiniPopup -Title "TRANSFER COMPLETED" -Message $completed_msg -Icon 'Exclamation'
                            }
                            
                            Write-LogEntry -n -f DarkRed "[DOWNLOAD] " ; Write-LogEntry -f DarkGreen "$completed_msg"
                        }
                    }
                }
                    
    }
    catch{
        Write-LogEntry $_
        Show-InternalMiniErrorPopup $_
        #Show-ExceptionDetails $_ -ShowStack
    }finally{
        Pop-Location
    }
    
}