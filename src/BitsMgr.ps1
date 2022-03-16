

function Invoke-GetNotifierAppPath{                         # NOEXPORT
    [CmdletBinding(SupportsShouldProcess)]
    param()


    $Result='C:\Programs\SystemTools\Notifier.exe'

    
    return $Result
}

function New-RandomFilename{
<#
    .SYNOPSIS
            Create a RandomFilename 
    .DESCRIPTION
            Create a RandomFilename 
#>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = "$ENV:Temp",
        [Parameter(Mandatory=$false)]
        [string]$Extension = 'tmp',
        [Parameter(Mandatory=$false)]
        [int]$MaxLen = 6,
        [Parameter(Mandatory=$false)]
        [switch]$CreateFile,
        [Parameter(Mandatory=$false)]
        [switch]$CreateDirectory
    )    
    try{
        if($MaxLen -lt 4){throw "MaxLen must be between 4 and 36"}
        if($MaxLen -gt 36){throw "MaxLen must be between 4 and 36"}
        [string]$filepath = $Null
        [string]$rname = (New-Guid).Guid
        Write-Verbose "Generated Guid $rname"
        [int]$rval = Get-Random -Minimum 0 -Maximum 9
        Write-Verbose "Generated rval $rval"
        [string]$rname = $rname.replace('-',"$rval")
        Write-Verbose "replace rval $rname"
        [string]$rname = $rname.SubString(0,$MaxLen) + '.' + $Extension
        Write-Verbose "Generated file name $rname"
        if($CreateDirectory -eq $true){
            [string]$rdirname = (New-Guid).Guid
            $newdir = Join-Path "$Path" $rdirname
            Write-Verbose "CreateDirectory option: creating dir: $newdir"
            $Null = New-Item -Path $newdir -ItemType "Directory" -Force -ErrorAction Ignore
            $filepath = Join-Path "$newdir" "$rname"
        }
        $filepath = Join-Path "$Path" $rname
        Write-Verbose "Generated filename: $filepath"

        if($CreateFile -eq $true){
            Write-Verbose "CreateFile option: creating file: $filepath"
            $Null = New-Item -Path $filepath -ItemType "File" -Force -ErrorAction Ignore 
        }
        return $filepath
        
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}

function New-DownloadJob {
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

        Write-Host "NEW DOWNLOAD TASK"
        Write-Host "-----------------"

        write-ChannelMessage "Creating Download Job $Name"
        <#
            NotifyFlags
            1: Generates an event when all files in the job have been transferred.
            2: Generates an event when an error occurs.
            4: Disables notifications.
            The default value is 1|2.
        #>
        $Notifier = Invoke-GetNotifierAppPath
        $Params = @{
            Source = "$Url"
            Destination = "$DestinationPath"
            DisplayName = "$Name"
            Priority = "$Priority"
            TransferPolicy = 'Unrestricted'
            RetryInterval = 120
            RetryTimeout = 60
            TransferType = 'Download'
            NotifyCmdLine = "$Notifier"
        }

        Start-BitsTransfer @Params -Asynchronous

  }
  catch{
        Reset-AllBitsJobs
        Show-ExceptionDetails $_ -ShowStack
        return $null
    }
}


function Reset-AllBitsJobs{
    Param(
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )
    $BITSADMIN=(get-command bitsadmin.exe).Source
    $Data = &"$BITSADMIN" /raw /reset     
}