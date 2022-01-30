
<#
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
##
##  Quebec City, Canada, MMXXI
#>




function Set-BITSNotifyCmdLine{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0,
            HelpMessage="BITS Job name") ]
        [string]$JobName,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=1,
            HelpMessage="Command") ]
        [string]$Command,     
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,Position=2)]
        [string]$Argument=""  
    )
    $n = Get-BITSJobsCount ; if($n -eq 0){ write-ChannelMessage "No jobs" ; return; }
    
    $BITSADMIN=(get-command bitsadmin.exe).Source
    $NOTIFIER='C:\Programs\SystemTools\Notifier.exe'
    if($Argument -eq ''){
        &"$BITSADMIN" /SetNotifyCmdLine $JobName "$Command" NULL
    }else{
        &"$BITSADMIN" /SetNotifyCmdLine $JobName "$Command" $Argument
    }
}


function Reset-BITSService {
<#
    .SYNOPSIS
            Create a download job
    .DESCRIPTION
            Create a download job
#>

    [CmdletBinding(SupportsShouldProcess)]
    param ()  

    $n = Get-BITSJobsCount
    if($n -gt 0){
        write-host "WARNING" -f Red -b DarkGray -NoNewLine ; $a=Read-Host -Prompt "This will cancel all transferring jobs ($n jobs). Are you sure (y/N)?" ; if($a -notmatch "y") {return;}
    }    
    
    $BITSADMIN=(get-command bitsadmin.exe).Source
    $ScriptDelete = '$Results = ""
    $Childs = (gci -Path  "C:\Users" -Directory).FullName
    ForEach( $dir in $Childs){
        $SubPath = Join-Path $dir "\AppData\Roaming\Microsoft\Network\Downloader"
        Write-Host "[BitsAdminReset] " -f DarkRed -NoNewLine
        Write-Host "CHECKING $SubPath" -f DarkYellow -NoNewLine
        if(Test-Path $SubPath -PathType Container){
            Write-Host "EXISTS...." -f DarkRed    
            Write-Host "[BitsAdminReset] " -f DarkRed -NoNewLine
            Write-Host "$SubPath Exits" -f DarkYellow
            $ToDelete = (gci -Path $SubPath -File -Filter "qmgr*.*").Fullname
            $TmpFile = (New-TemporaryFile).FullName
            ForEach( $del in $ToDelete){
                Write-Host "[BitsAdminReset] " -f DarkRed -NoNewLine
                write-ChannelMessage "Deleting $del" -f DarkYellow
                Remove-Item $del -Verbose  -Force -Recurse -ErrorAction Continue 4>> $TmpFile
            }
            $Results += Get-Content $TmpFile -Raw
        }else{
            Write-Host " DOESNT EXISTS" -f DarkGreen
        }
    }'
    $TmpFile = (New-TemporaryFile).FullName
    $ScriptStop = [ScriptBlock]::Create('net stop BITS /y')
    $ScriptStart = [ScriptBlock]::Create('net start BITS')
    $ScriptBlockDelete = [ScriptBlock]::Create($ScriptDelete)
    $Credz = Get-AppCredentials Admin

    Write-Host "RESETTING THE BITSADMIN" -f DarkRed 
    Write-Host "-----------------------" -f DarkYellow
    &"$BITSADMIN" /reset
    Sleep 1
    write-ChannelMessage "Stopping BITS service...."
    Invoke-Command -ScriptBlock $ScriptStop -ComputerName . -Credential $Credz ; Sleep 3 ; Write-ChannelResult "BITS service stopped" ;
    write-ChannelMessage "Deleting buffer files...."
    Invoke-Command -ScriptBlock $ScriptBlockDelete -ComputerName . -Credential $Credz ; Sleep 3 ; Write-ChannelResult "Done" ;
    write-ChannelMessage "Starting BITS service...."
    Invoke-Command -ScriptBlock $ScriptStart -ComputerName . -Credential $Credz ; Sleep 3
    Write-ChannelResult "BITS service started" ;
}    


function New-BITSJob {
<#
    .SYNOPSIS
            Create a download job
    .DESCRIPTION
            Create a download job
#>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [Parameter(Mandatory=$false)]
        [string]$Name="",
        [Parameter(Mandatory=$false)]
        [Alias('p','path')]
        [string]$DestinationPath="",
        [Parameter(Mandatory=$false)]
        [ValidateSet('Foreground','High','Normal','Low')]
        [string]$Priority="Normal"
    )
    try{
        $BITSADMIN=(get-command bitsadmin.exe).Source
        $I=$Url.LastIndexOf('/') + 1
        $UrlFile = $Url.SubString($I)
        if($Name -eq ""){
            $Name = 'JOB_' + $UrlFile 
        }

        if($DestinationPath -eq ""){
            $DestinationPath = Get-DefaultDownloadPath
            $DestinationPath = Join-Path $DestinationPath $Name
            New-Item -Path $DestinationPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null 
            $DestinationPath = Join-Path $DestinationPath $UrlFile
        }else{
            if(-Not ($DestinationPath | Test-Path) ){
                throw "Folder does not exist"
            }
            if(-Not ($DestinationPath | Test-Path -PathType Container) ){
                throw "The Path argument must be a Directory. Files paths are not allowed."
            }
            $DestinationPath = Join-Path $DestinationPath $UrlFile
        }

        $Notifier=Get-NotifierAppPath
        
        Write-Host "NEW DOWNLOAD TASK"
        Write-Host "-----------------"

        write-ChannelMessage "Creating Download Job $Name"
        [string]$Id = &"$BITSADMIN"  /RAWRETURN /nowrap /create "$Name"

        Sleep -Millisecond 500
        
        if($?){ Write-ChannelResult "Job created. Id $Id"} else { throw "ERROR CREATING JOB $Name"}

        $Data = &"$BITSADMIN"  /RAWRETURN /nowrap /addfile "$Name" "$Url" "$DestinationPath" ; Sleep -Millisecond 500
        Write-Verbose "Result: $Data"
        if($?){ Write-ChannelResult "File Added"} else { throw "ERROR ADDING FILE"}
        $JobName = $Name.Replace("'",'')
        $Data = &"$BITSADMIN"  /RAWRETURN /nowrap /SetNotifyCmdLine "$Name" "$Notifier" $JobName ; Sleep -Millisecond 500
        Write-Verbose "Result: $Data"
        if($?){ Write-ChannelResult "Set Notify CmdLine"} else { throw "ERROR NOTIFICATION"}
        $Data = &"$BITSADMIN"  /RAWRETURN /nowrap /Resume "$Name" ; Sleep -Millisecond 500
        Write-Verbose "Result: $Data"
        if($?){ Write-ChannelResult "Job Started"} else { throw "ERROR STARTING JOB $Name"}
        $Data = &"$BITSADMIN"  /RAWRETURN /nowrap /SetPRIORITY "$Name" $Priority
        Write-Verbose "Result: $Data"

        $NewJob = New-DownloadJobEntry $Id $Name $Url 'STARTING' $Notifier $DestinationPath $Priority 0 1 0 0
             

        return $NewJob
  }
  catch{
        &$BITSADMIN /cancel $Name  | Out-Null
        Show-ExceptionDetails $_ -ShowStack
        return $null
    }
}


function Complete-BITSJobs{
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try{
        $n = Get-BITSJobsCount ; if($n -eq 0){ write-ChannelMessage "No jobs" ; return; }

        $Jobs = Get-BITSJobs
        if($Jobs){
            $Jobs = $Jobs | where Status -eq 'TRANSFERRED'    
        }
        
        $NumJobs = 0
        if($Jobs){$NumJobs = $Jobs.Count}
        if($NumJobs -eq 0){
            throw "No Jobs with status TRANSFERED"
        }
        $BITSADMIN=(get-command bitsadmin.exe).Source
        
        foreach($job in $Jobs){
            $id = $job.ID
            $name = $job.Name
            $status = $job.Status
            $File = $job.DestinationPath
            if($status -eq 'TRANSFERRED'){
                $formatstring = "Completing Job Id {0} : {1}"
                $fields = $id,$name
                $Msg=($formatstring -f $fields)
                write-ChannelMessage $Msg
                Write-Verbose "$BITSADMIN /COMPLETE $id"
                $Data = &"$BITSADMIN" /rawreturn /COMPLETE "$id"

                Write-ChannelResult "$Data"
                Write-ChannelResult "Downloaded file ==> $File"
                $Dir=(Get-Item $File).DirectoryName
                $Exp = (get-command explorer.exe).Source
                &"$Exp" $Dir
                
            }
        }

    }catch{
        Write-Error $_
    }
}

function Get-BITSJobsCount{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $BITSADMIN=(get-command bitsadmin.exe).Source
    [string[]]$Data = &"$BITSADMIN" /RAWRETURN /nowrap /list

    if(($Data -eq $Null) -Or ($Data -eq '')){
        $NumJobs = 0
    }else{
         # Get the number of jobs
        $NumJobs = $Data.Count
    }

    return $NumJobs
}

function Get-BITSJobsFiles{
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory=$false)]
        [string]$JobName
    )
    $BITSADMIN=(get-command bitsadmin.exe).Source
    [string[]]$Data = &"$BITSADMIN" /RAWRETURN /nowrap /listfiles $JobName

    if(($Data -eq $Null) -Or ($Data -eq '')){
        return $null
    }

    return $Data
}

function Get-Svc($ServiceName){
    
    $Status=(get-service | where Name -match "$ServiceName").Status
    $formatstring = "Service {0} : {1}"
    $fields = $ServiceName, $Status
    $Msg=($formatstring -f $fields)
    write-ChannelMessage $Msg
}

function Stop-BITSServices{
    $cs = Get-AppCredentials Admin
    $script = 'stop-service dosvc
    stop-service bits
    stop-service wuauserv'
    $sblock = [scriptblock]::Create($script)
    Invoke-Command -ScriptBlock $sblock -Credential $cs -ComputerName .
    Get-Svc 'dosvc'
    Get-Svc 'bits'
    Get-Svc 'wuauserv'
}

function Start-BITSServices{
    $cs = Get-AppCredentials Admin
    $script = 'stop-service dosvc
    Start-service bits
    Start-service wuauserv'

    $sblock = [scriptblock]::Create($script)
    Invoke-Command -ScriptBlock $sblock -Credential $cs -ComputerName .
    Get-Svc 'dosvc'
    Get-Svc 'bits'
    Get-Svc 'wuauserv'
}

function Test-BITSServices{
    Write-ChannelMessage "Test-BITSServices : Getting the Services Status for BITS transfer"
    $n=Get-BITSJobsCount
    $DoSvcStatus=(Get-Service 'dosvc').Status
    $BitsSvcStatus=(Get-Service 'bits').Status

    Write-ChannelMessage "Currently active jobs : $n "
    if(($DoSvcStatus -eq 'Stopped') -Or ($BitsSvcStatus -eq 'Stopped')){
        Write-ChannelResult "Service 'dosvc' $DoSvcStatus" -Warning
        Write-ChannelResult "Service 'bits'  $BitsSvcStatus" -Warning
        $a=Read-Host -Prompt "Do you want to start the services (y/N)?" ; if($a -notmatch "y") {return;}
        Start-BITSServices
    }else{
        Write-ChannelMessage "Service 'dosvc' " "$DoSvcStatus"
        Write-ChannelMessage "Service 'bits' " "$BitsSvcStatus"
        
    }
}


function Get-BITSJobs{
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory=$false)]
        [string]$JobName
    )

    $n = Get-BITSJobsCount ; if($n -eq 0){ write-ChannelMessage "No jobs" ; return; }

    $BITSADMIN=(get-command bitsadmin.exe).Source

    $NumJobs = Get-BITSJobsCount

    $formatstring = "Get-BITSJobs : {0} Download Jobs"
    $fields = $NumJobs
    $Msg=($formatstring -f $fields)
    
    write-ChannelMessage $Msg

    if($NumJobs -eq 0){
        return $null
    }

    [string[]]$Data = &"$BITSADMIN" /RAWRETURN /nowrap /list

    $JobList = [System.Collections.ArrayList]::new()
    $i = 0
    foreach($Buffer in $Data){
         [string[]]$JobInfo = $Buffer.Split(' ')
         $JobInfoCount = $JobInfo.Count
        Write-Verbose "PARSING ==> $Buffer"
        
        Write-Verbose "JobInfoCount $JobInfoCount"
       try{
            [string]$JobID = $JobInfo[0]
            [string]$Name = $JobInfo[1]
            [string]$JobStatus = $JobInfo[2]
            [long]$JobFilesTransfered   = 0
            [long]$JobTotalFiles        = 0
            [long]$JobBytesTransfered   = 0
            [long]$JobTotalBytes        = 0        
            if($JobInfoCount -ge 7){
                [long]$JobFilesTransfered   = $JobInfo[3]
                [long]$JobTotalFiles        = $JobInfo[5]
                [long]$JobBytesTransfered   = $JobInfo[6]
                if($JobInfo[8] -ne 'UNKNOWN'){
                    [long]$JobTotalBytes        = $JobInfo[8]
                }
            }
            [string]$Name = $Name.Replace("'",'')
            [string]$Priority = &"$BITSADMIN"  /RAWRETURN /nowrap /getpriority "$Name"
            [string]$Data = Get-BITSJobsFiles "$Name"
            $Url = '-'
            $DestinationPath = '-'
            if($Data){
                [string[]]$Buffer = $Data.Split(' ')
                [string]$Url = $Buffer[4]
                [string]$DestinationPath = $Buffer[6]
             }

             $Notifier = Get-NotifierAppPath
             $Job = New-DownloadJobEntry $JobID $Name $Url $JobStatus $Notifier $DestinationPath $Priority $JobFilesTransfered $JobTotalFiles $JobBytesTransfered $JobTotalBytes
             $JobList.Add($Job) | Out-Null
        }catch{
            Write-Warning "PARSER ERROR FOR $Name $_"
            &"$BITSADMIN" /RAWRETURN /nowrap /cancel $Name
            Show-ExceptionDetails $_ -ShowStack 
        }
        
        if($PSBoundParameters.ContainsKey('JobName')){
            Write-Verbose "Apply filter $Name match $JobName"
            return $JobList | where Name -match $JobName
        }
    }

    return $JobList
}

function Reset-BITSJobs{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $BITSADMIN=(get-command bitsadmin.exe).Source
    $n = Get-BITSJobsCount
    Write-ChannelMessage "cancel all transferring jobs ($n jobs)"
    if($n -gt 0){
        $a=Read-Host -Prompt "Are you sure (y/N)?" ; if($a -notmatch "y") {return;}
        $Data = &"$BITSADMIN" /reset
    }       
}

function Set-BITSJobPriority{
     [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$JobName,
        [Parameter(Mandatory=$true)]
        [ValidateSet('Foreground','High','Normal','Low')]
        [string]$Priority
    )
    $BITSADMIN=(get-command bitsadmin.exe).Source
    &"$BITSADMIN" /SETPRIORITY $JobName $Priority
   
}
function Resume-BITSJob{
     [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$JobName
    )
    $BITSADMIN=(get-command bitsadmin.exe).Source
    &"$BITSADMIN" /RESUME $JobName
   
}


function Get-BITSJobStats{
     [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$JobName
    )
    $n = Get-BITSJobsCount ; if($n -eq 0){ write-ChannelMessage "No jobs" ; return; }
    $Job = (Get-BITSJobs -JobName $JobName)
    $Id = ''
    $Name = ''
    if($Job -ne $Null){
        [long]$b1 = $Job.BytesTransfered
        [long]$b2 = $Job.TotalBytes
        $Id = $Job.Id
        $Name = $Job.Name
    }

    $ret = 100 * ( $b1 / $b2 )

    Write-Host "`n=======================================================" -f DarkRed
   Write-Host "ＤＯＷＮＬＯＡＤ ＪＯＢ ＵＰＤＡＴＥ" -f DarkYellow
   Write-Host "=======================================================" -f DarkRed
    Write-Host "[$Name]" -f DarkGray
   Write-Host "𝑻𝒓𝒂𝒏𝒔𝒇𝒆𝒓𝒆𝒅`t" -f DarkRed -NoNewLine ; Write-Host "$b1" -f DarkYellow
   Write-Host "𝑩𝒚𝒕𝒆𝒔 𝑻𝒐𝒕𝒂𝒍`t" -f DarkRed -NoNewLine ; Write-Host "$b2" -f DarkYellow
   Write-Host "𝑪𝒐𝒎𝒑𝒍𝒆𝒕𝒆𝒅 %`t" -f DarkRed -NoNewLine ; Write-Host "$ret" -f DarkGreen
}

function List-AllBITSJobs{
    [CmdletBinding()]
    param()

    try{
        $n = Get-BITSJobsCount ; if($n -eq 0){ write-ChannelMessage "No jobs" ; return; }

        $Jobs = Get-BITSJobs
        if($Jobs){
            $Jobs = $Jobs | where Status -eq 'TRANSFERRED'    
        }
        
        $NumJobs = 0
        if($Jobs){$NumJobs = $Jobs.Count}
        if($NumJobs -eq 0){
            throw "No Jobs with status TRANSFERED"
        }
        $BITSADMIN=(get-command bitsadmin.exe).Source
        
        foreach($job in $Jobs){
            $id = $job.ID
            $name = $job.Name
            $status = $job.Status
            $File = $job.DestinationPath
            if($status -eq 'TRANSFERRED'){
                write-Host "Get-BITSJobStats -JobName $name"
                
            }
        }

    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}


function Resume-BITSJobs{
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try{
        $n = Get-BITSJobsCount ; if($n -eq 0){ write-ChannelMessage "No jobs" ; return; }

        $Jobs = Get-BITSJobs
        if($Jobs){
            $Jobs = $Jobs | where Status -eq 'TRANSIENT_ERROR'    
        }
        
        $NumJobs = 0
        if($Jobs){$NumJobs = $Jobs.Count}
        if($NumJobs -eq 0){
            throw "No Jobs with status TRANSIENT_ERROR"
        }
        $BITSADMIN=(get-command bitsadmin.exe).Source
        
        foreach($job in $Jobs){
            $id = $job.ID
            $name = $job.Name
            $status = $job.Status
            $File = $job.DestinationPath
            if($status -eq 'TRANSIENT_ERROR'){
                $formatstring = "RESUME Job Id {0} : {1}"
                $fields = $id,$name
                $Msg=($formatstring -f $fields)
                write-ChannelMessage $Msg
                Write-Verbose "$BITSADMIN /RESUME $id"
                $Data = &"$BITSADMIN" /rawreturn /RESUME "$id"
                $Data
            }
        }

    }catch{
        Write-Error $_
    }
}