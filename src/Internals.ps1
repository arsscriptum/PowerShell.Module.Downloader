
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


function Get-DlModuleInformation{  # NOEXPORT

        $ModuleName = $ExecutionContext.SessionState.Module
        $ModuleScriptPath = $ScriptMyInvocation = $Script:MyInvocation.MyCommand.Path
        $ModuleScriptPath = (Get-Item "$ModuleScriptPath").DirectoryName
        $CurrentScriptName = $Script:MyInvocation.MyCommand.Name
        $ModuleInformation = @{
            Module        = $ModuleName
            ModuleScriptPath  = $ModuleScriptPath
            CurrentScriptName = $CurrentScriptName
        }
        return $ModuleInformation
}

function Get-DownloaderModuleExportsPath{   v
    $ModPath = (Get-DlModuleInformation).ModuleScriptPath
    $ExportsPath = Join-Path $ModPath 'exports'
    return $ExportsPath
}


function Get-CleanFilename{   
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,Mandatory = $true)]
        [string]$Filename
    )
    $NewFilename = $Filename.Clone()
    $arrInvalidChars = '[]/|\+={}-$%^&*() '.ToCharArray()  + [IO.Path]::GetInvalidFileNameChars()
    $arrInvalidChars | % { $NewFilename = $NewFilename.replace("$_",'')} 
  
    return $NewFilename
}



function Show-YoutubeDlHelp{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,Mandatory = $false)]
        [string]$Search
    )
    $ExportsPath = Get-DownloaderModuleExportsPath
    $HelpFile = (Join-Path $ExportsPath "youtubedl_help.txt")  
    if (-not(Test-Path $HelpFile)){
        Write-Verbose "Running youtube-dl --help and saving output to $HelpFile"
        $YoutubeDlPath = Get-YoutubeDlPath
        &"$YoutubeDlPath" "--help" > $HelpFile 
    }
    $help_data = Get-Content $HelpFile
    if($PSBoundParameters.ContainsKey('Search')){
        $help_data | Select-String "$Search" -Context 3
    }else{
        $help_data
    }
}

function Convert-DestinationPath{   # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,Mandatory = $true)]
        [string]$Url,
        [Parameter(Position=1,Mandatory = $true)]
        [string]$DestinationPath
    )

    try{
        $Url = Out-DecodedUrl $Url
        Write-Verbose "======================="
        Write-Verbose "Convert-DestinationPath"
        Write-Verbose "Url                $Url"
        Write-Verbose "DestinationPath    $DestinationPath"
        $ReqArguments = @{}
        $req_array = $Url.split('&')
        ForEach($a in $req_array){
            if($a.IndexOf('=') -gt 0){
                $set = $a.split('=')
                $set_name = $set[0]
                $set_value = $set[1]
                $ReqArguments.Add($set_name,$set_value)
                Write-Verbose "$set_name`t<==>`t$set_value"
            }
        }

        $IsContainer = $False
        $ItemInfo = Get-Item -Path $DestinationPath -ErrorAction Ignore
        if($Null -eq $ItemInfo){
            Write-Verbose "DestinationPath DOES NOT EXISTS"

            $Parent = Get-ParentDirectoryName $DestinationPath
            $ParentItemInfo = Get-Item -Path $Parent -ErrorAction Ignore
            if($Null -eq $ParentItemInfo){
                throw "INVALID PATH $Parent DOES NOT EXISTS"
            }
            Write-Verbose "RETURNING $DestinationPath"
            return $DestinationPath
        }

        $IsContainer = $ItemInfo.PSIsContainer
        if($IsContainer -eq $True){
            Write-Verbose "DestinationPath Is a Container"
            [Uri]$Val = $Url;

            $Ext = 'mp4'
            try{
                $Name = $Val.Segments[$Val.Segments.read_count-1]
                [string]$source = $ReqArguments['source']
                Write-Verbose "Source is $source"
                if($source -match "youtube"){  
                    Write-Verbose "Source is youtube"
                    [string]$mimes = $ReqArguments['mime']
                    $mimetypes = $mimes.split('/')
                    $Ext = $mimetypes[1]
                    $Name = "{0}video.{1}" -f "$source", "$Ext"
                    Write-Verbose "*** $Name" 
                }

            }catch{}

            $DestinationPath = Join-Path $DestinationPath $Name
        }

     
        if(Test-Path $DestinationPath){
            $dn = (Get-Item $DestinationPath).DirectoryName
            $bn = (Get-Item $DestinationPath).BaseName
            $ex = (Get-Item $DestinationPath).Extension

            $i = 0
            do{
                $new_path = "{0}_{1}{2}" -f "$bn", "$i", "$ex"
                $new_path = Join-Path $dn $new_path
                Write-Verbose "Trying $new_path"
                $name_available = -not (Test-Path "$new_path")
                $i++

            }until($name_available -eq $True)
            $DestinationPath = $new_path
            Write-Verbose "RETURNINNG $DestinationPath"
            return $DestinationPath
        }
        Write-Verbose "RETURNINNG $DestinationPath"
        return $DestinationPath
    }catch{
        $DestinationPath = $Null
        Write-Error $_
    }
    
    $DestinationPath
}

function New-JobName{    # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param()
    # Generate a UNIQUE JOB NAME, but easy to use, not a GUID with 64 chars...
    [string]$JobName = (Get-Date).GetDateTimeFormats()[113]
    $JobName = $JobName.Replace(':',"").Replace('0',"")
    $NumArray= $JobName.ToCharArray()
    $Sum = 0
    $NumArray | % {
        $Sum += $_
    }
    $JobName = ''
    
    $v1 = Get-Random -Maximum 25 -Minimum 1
    $v2 = Get-Random -Maximum 25 -Minimum 1
    $arrrnd = @($v1,$v2)
    $arrrnd | % { $JobName += [char]($_ + 65) }
    $JobName = "{0}{1}" -f $JobName, $Sum
    $JobName
}



function Out-DecodedUrl{     # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [string]$Url
    )
    if (!("System.Web.HttpUtility" -as [type])) {
        Write-Verbose "Registering System.Web... " 
        Add-Type -AssemblyName System.Web
    }else{
        Write-Verbose "System.Web already registered: ... " 
    }
    [string]$decodedURL = [System.Web.HttpUtility]::UrlDecode($Url)
    Write-Verbose "The decoded url is: $decodedURL"
    return $decodedURL
}


function Out-EncodedUrl{     # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [string]$Url
    )
    if (!("System.Web.HttpUtility" -as [type])) {
        Write-Verbose "Registering System.Web... " 
        Add-Type -AssemblyName System.Web
    }else{
        Write-Verbose "System.Web already registered: ... " 
    }
    $encodedURL = [System.Web.HttpUtility]::UrlEncode($Url) 
    Write-Verbose "The encoded url is: $encodedURL"
    return $decodedURL
}



Function Show-InternalMiniPopup{  # NOEXPORT
    # Define Parameters
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # The popup Content
        [Parameter(Position=0,Mandatory=$True)]
        [String]$Title,
        [Parameter(Position=1,Mandatory=$True)]
        [String]$Message,
        [Parameter(Position=2,Mandatory=$False)]
        [ValidateSet('None','Hand','Error','Stop','Question','Exclamation','Warning','Asterisk','Information')]
        [String]$Icon="None",
        [Parameter(Position=3,Mandatory=$False)]
        [ValidateSet('OK', 'OKCancel', 'AbortRetryIgnore', 'YesNoCancel', 'YesNo', 'RetryCancel')]
        [String]$Type="OK",
        [ValidateSet('Button1','Button2','Button3')]
        [String]$DefaultButton="Button1",
        [ValidateSet('DefaultDesktopOnly', 'RightAlign', 'RtlReading', 'ServiceNotification')]
        [String]$Option="DefaultDesktopOnly"     

        
    )
    $Null = [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    return [Windows.Forms.MessageBox]::show($Message, $Title,$Type,$Icon,$DefaultButton,$Option)
}

Function Show-InternalMiniInfoPopup{   
    # Define Parameters
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # The popup Content
        [Parameter(Position=0,Mandatory=$True)]
        [String]$Message,
        [Parameter(Position=1,Mandatory=$False)]
        [String]$Title = "Important Information"
    )
    return Show-InternalMiniPopup -Title $Title -Message $Message -Icon 'Information'
}

Function Show-InternalMiniErrorPopup{    
    # Define Parameters
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # The popup Content
        [Parameter(Position=0,Mandatory=$True)]
        [System.Management.Automation.ErrorRecord]$Record,
        [Parameter(Position=1,Mandatory=$False)]
        [String]$Title = "ERROR"
    )
    $formatstring = "{0}`n{1}"
    $fields = $Record.FullyQualifiedErrorId,$Record.Exception.ToString()
    $ExceptMsg=($formatstring -f $fields)
    $Stack=$Record.ScriptStackTrace

    $ErrMsg = @"
$ExceptMsg
---------------------
$Stack
"@
    return Show-InternalMiniPopup -Title $Title -Message $ErrMsg -Icon 'Error'
}


function Get-ParentDirectoryName([string]$Path) {      # NOEXPORT
    if([string]::IsNullOrEmpty($Path)){
        return ""
    }
        if(Test-Path -Path $Path -PathType Container){
            $directory = $Path.Replace('/','\').Trim('\').Trim()
            return $directory
        }
        $resolvedPath = Resolve-Path -Path $Path -ErrorVariable resolvePathError -ErrorAction SilentlyContinue

        if ($null -eq $resolvedPath)
        {
            $fullpath = $resolvePathError[0].TargetObject
            [uri]$u = $fullpath
            $segcount = $u.Segments.Count
            $directory = ''
            for($x = 1 ; $x -lt $segcount-1 ; $x++){
                $directory += $u.Segments[$x].Replace('/','\')
                $directory = $directory.Trim()
            }
        
            return $directory
        }
        else
        {
            $fullpath = $resolvedPath.ProviderPath
            $directory = (Get-Item -Path $fullpath).DirectoryName
            $directory = $directory.Trim()
            return $directory
        }
    
}

function Out-Banner {  # NOEXPORT
    $ModName = (Get-YoutubeDlModuleInformation).Module
    Write-Host "`n$ModName - PowerShell Module to Download Youtube Media" -f Blue
    Write-Host "Copyright (C) 2000-2021 Guillaume Plante" -f Gray
}

function Out-UsageFunct1{  # NOEXPORT
    Write-Host "usage: $ProgramName  [url] <-p destination path> <-m download mode> <-a>`n" -f Gray
    Write-Host "The following cmdline options are available:" -f Gray
    Write-Host "`t-h | --help    show help" -f Gray
    Write-Host "`t-u | --url     source location of the files that you want to transfer" -f Gray
    Write-Host "`t-p | --path    destination location of the files that you want to transfer. If a directory, the app will detect the file based on url" -f Gray 
    Write-Host "`t-m | --mode    download mode. valid are 'wgetjob','wget','http','bits' and 'bitsadmin'" -f Gray
    Write-Host "`t-a | --async   async mode`n"  -f Gray
}



function Get-TimeString([int]$ms){   # NOEXPORT
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


function Get-FormattedBytes([int]$TotalBytes){   # NOEXPORT
    $TotalKb =  ($TotalBytes / 1KB)
    $TotalMb =  ($TotalBytes / 1MB)
    $TotalSizeInBytesStr = "{0:n2} Bytes" -f $TotalBytes
    $TotalFolderSizeInKB = "{0:n2} KB" -f $TotalKb 
    $TotalFolderSizeInMB = "{0:n2} MB" -f $TotalMb
    [string]$res_str = ""
    if($TotalBytes -gt 1MB){
        $res_str =  $TotalFolderSizeInMB
    }elseif($TotalBytes -gt 1KB){
        $res_str =  $TotalFolderSizeInKB
    }else{
        $res_str =  $TotalSizeInBytesStr
    }
    return $res_str
}


function New-TmpFileName{        # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Extension='log',
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Path="$ENV:Temp"       
    )
    # Generate a UNIQUE JOB NAME, but easy to use, not a GUID with 64 chars...
    [string]$FileName = (Get-Date).GetDateTimeFormats()[113]
    $FileName = $FileName.Replace(':',"").Replace('0',"")
    $NumArray= $FileName.ToCharArray()
    $Sum = 0
    $NumArray | % {
        $Sum += $_
    }
    $FileName = ''
    
    $v1 = Get-Random -Maximum 25 -Minimum 1
    $v2 = Get-Random -Maximum 25 -Minimum 1
    $arrrnd = @($v1,$v2)
    $arrrnd | % { $FileName += [char]($_ + 65) }
    $FileName = "{0}{1}.{2}" -f $FileName, $Sum, $Extension
    $FileName = Join-Path $Path $FileName
    $FileName
}



function Get-PwshCoreExePath{    # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $powershellCmd = Get-Command 'pwsh.exe' -ErrorAction Ignore
    if(($powershellCmd -ne $Null ) -And (test-path -Path "$($powershellCmd.Source)" -PathType Leaf)){
        $pwshApp = $powershellCmd.Source
        Write-Verbose "✅ Found pwshApp.exe CMD [$pwshApp]"
        Return $pwshApp 
    }

    $expectedLocations="${ENV:ProgramFiles}\PowerShell\7", "${ENV:ProgramFiles(x86)}\PowerShell\7", "c:\Programs\PowerShell\7"
    $pwshFiles=$expectedLocations|%{Join-Path $_ 'pwsh.exe'}
    [String[]]$validPwshExeFiles=@($pwshFiles|?{test-path $_})
    $validPwshExeFilesCount = $validPwshExeFiles.Count
    if($validPwshExeFilesCount){
        Write-Verbose "✅ Found pwshApp.exe in expectedLocations [$validPwshExeFiles[0]]"
        return $validPwshExeFiles[0]
    }
}



function Get-YoutubeDlPath{      # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $powershellCmd = Get-Command 'yt-dlp' -ErrorAction Ignore
    if(($powershellCmd -ne $Null ) -And (test-path -Path "$($powershellCmd.Source)" -PathType Leaf)){
        $youtubeExePath = $powershellCmd.Source
        Write-Verbose "✅ Found yt-dlp.exe CMD [$youtubeExePath]"
        Return $youtubeExePath 
    }

    $ExportsPath = Get-DownloaderModuleExportsPath
    $expectedLocations= @("$ExportsPath","${ENV:ProgramFiles}\Youtube-Dl", "${ENV:ProgramFiles(x86)}\Youtube-Dl", "C:\ProgramData\chocolatey\bin")
    $pwshFiles=$expectedLocations|%{Join-Path $_ 'youtube-dl.exe'}
    [String[]]$validPwshExeFiles=@($pwshFiles|?{test-path $_})
    $validPwshExeFilesCount = $validPwshExeFiles.Count
    if($validPwshExeFilesCount){
        Write-Verbose "✅ Found yt-dlp.exe in expectedLocations [$validPwshExeFiles[0]]"
        return $validPwshExeFiles[0]
    }
}

function Reset-UrlListFile{      # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [String]$Path
    )
    $urlbase = "https://www.youtube.com/watch?v=rUVEFkjqiEE&list=PLWOW19VPvvh2NFXgThAAE_NgCiskUi0rW&index={0}"
    $url = $urlbase -f 1
    Set-Content -Path $Path -Value $url
    for($i = 2 ; $i -lt 9 ; $i++){
        $url = $urlbase -f $i
        Add-Content -Path $Path -Value $url
    }    
}


function Reset-DlModJobs{
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $JobCount = (Get-Job).Count
    Write-Host "Removing $JobCount thread jobs"
    Get-Job | % { Write-Host ". " -n;Remove-Job $_ -Force ; }
    $Cmd = Get-Command -Name 'bitsadmin.exe' -ErrorAction Ignore
    if($Cmd -eq $Null) { throw "Cannot find bitsadmin.exe" }
    $BitsAdminExe = $Cmd.Source
    Write-Host ""
    $Pattern = "^(?<Guid>[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}])(\s+)(?<Name>[\w\(\)a-zA-Z0-9\']*)(\s+)(?<State>[\w\(\)a-zA-Z0-9\']*)(\s+)(?<BytesReceived>(\d))[\/ ]*(\s+)(?<BytesTotal>(\d))(\s+)(?<FilesReceived>(\d))[\/ ]*(\s+)(?<FilesTotal>(\d))?"
    [string[]]$JobList = &"$BitsAdminExe" "/RAWRETURN" "/LIST"
    $JobListCount = $JobList.Count
    Write-Host "$JobListCount Jobs"
    ForEach($job in $JobList){
        if($job -match $Pattern){
            $jname = $Matches.Name
            $jname = $jname.Replace('"','').Replace("'",'')
            $jstate = $Matches.State
            Write-Host "Job $jname in state $jstate ==> " -n
            $Res = &"$BitsAdminExe" "/RAWRETURN" "/CANCEL" "$jname"
            Write-Host "$Res"
        }
    }
}




function Get-BitsJobsPSObjects{  # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [String]$JobName
    )

    $Cmd = Get-Command -Name 'bitsadmin.exe' -ErrorAction Ignore
    if($Cmd -eq $Null) { throw "Cannot find bitsadmin.exe" }
    $BitsAdminExe = $Cmd.Source

    $Pattern = "^(?<Guid>[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}])(\s+)(?<Name>[\w\(\)a-zA-Z0-9\']*)(\s+)(?<State>[\w\(\)a-zA-Z0-9\']*)(\s+)(?<BytesReceived>(\d))[\/ ]*(\s+)(?<BytesTotal>(\d))(\s+)(?<FilesReceived>(\d))[\/ ]*(\s+)(?<FilesTotal>(\d))?"
    [string[]]$JobList = &"$BitsAdminExe" "/RAWRETURN" "/LIST"
    [system.collections.arraylist]$JobsPsObjects = [system.collections.arraylist]::new()
    ForEach($job in $JobList){
        if($job -match $Pattern){

            $Name = $Matches.Name
            $Name = $Name.Replace('"','').Replace("'",'')
            $State = $Matches.State
            $BytesReceived = $Matches.BytesReceived
            $BytesTotal = $Matches.BytesTotal
            $FilesReceived = $Matches.FilesReceived
            $FilesTotal = $Matches.FilesTotal

            if($PSBoundParameters.ContainsKey('Name')){
                if($Name -match $JobName){
                    $obj = [pscustomobject]@{
                        Name           = $Name
                        State          = $State
                        BytesReceived  = $BytesReceived
                        BytesTotal     = $BytesTotal
                        FilesReceived  = $FilesReceived
                        FilesTotal     = $FilesTotal
                    }
                    [void]$JobsPsObjects.Add($obj)
                }
            }else{
                $obj = [pscustomobject]@{
                    Name           = $Name
                    State          = $State
                    BytesReceived  = $BytesReceived
                    BytesTotal     = $BytesTotal
                    FilesReceived  = $FilesReceived
                    FilesTotal     = $FilesTotal
                }
                [void]$JobsPsObjects.Add($obj)
            }
        }
    }
    $JobsPsObjects
}


