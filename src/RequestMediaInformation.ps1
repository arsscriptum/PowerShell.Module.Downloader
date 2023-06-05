
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>




<#
.SYNOPSIS

Function to save a youtube video using external downloaders

.DESCRIPTION

The script will gather the available formats for the video and 
will select the format based of user-provided arguments.

.PARAMETER Url

Url of the Youtube video

.PARAMETER DestinationPath

The location of the downloaded file

.PARAMETER FormatId

This integer Format Identifier is used to select a video format to download. If it is not specified, a
video with the MEDIUM quality is selected.

.PARAMETER AudioOnly

FLAG: Download the AUDIO track only

.PARAMETER DownloadMode

Download mode selection:
- wget: uses WGET.EXE to download the file. It is called in a PowerShell job so that you can get a progress bar if you want.
- http: uses .NET System.Net.HttpWebRequest to download the file.
- bits: uses the BITS protocol (via the BitTransfer module)
- bitsadmin: uses the BITS protocol (via the bitsadmin.exe command line tool)

.PARAMETER Asynchronous

FLAG: If set, the command will return right away and download is done in the background

.INPUTS

None. You cannot pipe objects to Add-Extension.

.OUTPUTS

System.String. DestinationPath the path of locally saved file

.EXAMPLE.DESCRIPTION Download the AUDIO track only, using .NET WebRequest

Url = 'https://www.youtube.com/watch?v=ghb6eDopW8I'

# Download the AUDIO track only, using .NET WebRequest
>> Save-YoutubeVideo $Url -AudioOnly -DownloadMode 'http'
-
# Download the video via BITS
>> Save-YoutubeVideo $Url -DownloadMode 'bits'
.EXAMPLE Download the video format 251 using bitsadmin, async
.DESCRIPTION Download the video format 251 using bitsadmin, async
# Download the video format 251 using bitsadmin, async
>> Save-YoutubeVideo $Url -FormatId 251 -DownloadMode 'bitsadmin' -Asynchronous

.LINK

https://arsscriptum.github.io/files/gifs/SaveYoutubeVideo_1.gif

.EXTERNALHELP

https://arsscriptum.github.io/files/help/ModDl-help.xml

#>
function Save-YoutubeVideo{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Url of the Youtube video", Position=0)]
        [Alias('u')]
        [string]$Url,
        [Parameter(Mandatory=$false, HelpMessage="The location of the downloaded file (directory or filename)")]
        [Alias('p')]
        [string]$DestinationPath,
        [Parameter(Mandatory=$false, HelpMessage="This integer Format Identifier is used to select a video format to download.")]
        [Alias('f')]
        [int]$FormatId,
        [Parameter(Mandatory=$false, HelpMessage="Download the AUDIO track only")]
        [Alias('a')]
        [switch]$AudioOnly,
        [Parameter(Mandatory=$false, HelpMessage="Download mode selection: wget, http, bits, bitsadmin")]
        [Alias('m')]
        [ValidateSet('wget',"http","bits","bitsadmin")]
        [string]$DownloadMode="bits",    
        [Parameter(Mandatory=$false, HelpMessage="If set, the command will return right away and download is done in the background")]
        [switch]$Asynchronous    
    )

    try{
        $TestMode = $False
        if( ($PSBoundParameters.ContainsKey("WhatIf")) -Or ($PSBoundParameters.ContainsKey("Debug"))){
            Write-LogEntry "======================================"
            Write-LogEntry "Save-YoutubeVideo ==> TEST MODE"
            Write-LogEntry "======================================"
            $TestMode = $True
        }
        [string]$DownloadUrl = ''
        [string]$Extension = ''
        
        if($PSBoundParameters.ContainsKey("FormatId") -eq $True){
            $data =Request-VideoFormats $Url -e
            $Found = $False
            $data | % { 
                if($_.format_id -eq $FormatId){
                 $DownloadUrl = $_.url
                 $Extension =  $_.ext
                 $Found = $True
             } 
            }
            if(!($Found)){ throw "Could not find url for format id $FormatId" }
   
        }else{
            if($AudioOnly){
                $selected = Select-BestAudioFormat $Url
                $DownloadUrl =  $selected.url
                $Extension =  $selected.ext
            }else{
                $selected = Select-VideoByQuality $Url
                $DownloadUrl =  $selected.url
                $Extension =  $selected.ext
            }
        }



        Write-LogEntry "[Request-MediaDownload] Url `"$Url`""
        Write-LogEntry "DownloadUrl      : $DownloadUrl"
        Write-LogEntry "DestinationFile  : $DestinationFile"
        Write-LogEntry "DownloadMode     : $DownloadMode"

        if($PSBoundParameters.ContainsKey("DestinationPath") -eq $False){
            $MyVideos = [environment]::getfolderpath("myvideos")
            $DownloadVideoPath = Join-Path $MyVideos 'DownloadModule'
            if(-not(Test-Path -Path $DownloadVideoPath -PathType Container)){
                $Null = New-Item -Path $DownloadVideoPath -ItemType "Directory" -Force -ErrorAction Ignore 
            }
            $DestinationPath = $DownloadVideoPath
        }
      
        $UrlInvalid = ([string]::IsNullOrEmpty($DownloadUrl))
        $PathInvalid = ([string]::IsNullOrEmpty($DestinationPath))
        $ExtInvalid = ([string]::IsNullOrEmpty($Extension))
        Write-LogEntry "UrlInvalid      : $UrlInvalid"
        Write-LogEntry "PathInvalid     : $PathInvalid"
        Write-LogEntry "ExtInvalid      : $ExtInvalid"
        if($UrlInvalid -Or $PathInvalid -Or $ExtInvalid){
            $Err=@"
Save-YoutubeVideo : Invalid argument
DownloadUrl      : `"$DownloadUrl`"
DestinationFile  : `"$DestinationFile`"
DownloadMode     : `"$DownloadMode`"
"@
            throw "$Err"
        }

        ########################################################################
        #                      Save-InternetFile
        ########################################################################
        
        if($TestMode){
            Write-LogEntry "DownloadUrl      : $DownloadUrl"
            Write-LogEntry "DestinationFile  : $DestinationFile"
            Write-LogEntry "DownloadMode     : $DownloadMode"
            return
        }
                
        switch( $DownloadMode ){

            'wget'      {
                            Save-UsingWGetJob -Url $DownloadUrl -DestinationPath $DestinationPath -Asynchronous:$Asynchronous
                        }

            "http"      {
                            Save-UsingHttpJob -Url $DownloadUrl -DestinationPath $DestinationPath -Asynchronous:$Asynchronous
                        }
            "bitsadmin" {
                            Save-UsingBitsAdmin -Url $DownloadUrl -DestinationPath $DestinationPath -Asynchronous:$Asynchronous
                        }
            "bits"      {
                            Save-UsingBitsModule -Url $DownloadUrl -DestinationPath $DestinationPath -Asynchronous:$Asynchronous -EnableNotification
                        }
        }
        
        "$DestinationPath"
    }
    catch{
        Write-LogEntry $_
        #Show-InternalMiniErrorPopup $_
        Show-ExceptionDetails $_ -ShowStack
    }
}


<#
.SYNOPSIS

Function to get all detailed video information

.DESCRIPTION

Function to get all detailed video information

.PARAMETER Url

Url of the Youtube video

#>
function Request-VideoInformation{
<#
    .SYNOPSIS
        Function to get all detailed video information
    .DESCRIPTION
        Function to get all detailed video information
    .PARAMETER Url
        Url of the Youtube video
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Url of the Youtube video", Position=0)]
        [string]$Url
    )
    
    try{
        $YoutubeDlPath = Get-YoutubeDlPath

        [string]$epoc_time = (Get-Date -uFormat %s)
        $Path = "{0}\{1}_{2}.json" -f $ENV:Temp, 'YoutubeMediaInformation', $epoc_time
        
        Write-LogEntry "Youtube Dl : $YoutubeDlPath"
        Write-LogEntry "Output file: $Path"

        &"$YoutubeDlPath" '-j' "$Url" > $Path
        $Success = $?
        $JsonSize = (gi $Path).Length

        Write-LogEntry "Operation Success : $Success"
        Write-LogEntry "Output file size  : $JsonSize"

        if( ($Success -eq $false) -Or  ($JsonSize -eq 0) ){
            throw "youtube-dl.exe failure. Output file size  : $JsonSize. Operation Success : $Success"
        }

        $MediaInformation = (Get-Content -Path $Path | ConvertFrom-Json)
        $Null = Remove-Item -Path $Path -Force -ErrorAction Ignore
        $MediaInformation 
    }
    catch{
        Write-LogEntry $_
        #Show-InternalMiniErrorPopup "EXCEPTION OCCURED $_"
        Show-ExceptionDetails $_ -ShowStack
    }
}

<#
.SYNOPSIS
    Function to get all the available formats for the video

.DESCRIPTION
    Function to get all the available formats for the video
.PARAMETER Url
    Url of the Youtube video
.PARAMETER Extended
    Flag: Get Extended information
.ExternalHelp  https://arsscriptum.github.io/files/help/ModDl-help.xml
#>

function Request-VideoFormats{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Url of the Youtube video", Position=0)]
        [string]$Url,
        [Parameter(Mandatory=$false, HelpMessage="Flag: Get Extended information")]
        [Alias('e','x','all')]
        [switch]$Extended
    )
    $data = Request-VideoInformation $Url
    if($Extended){
        $format_list = $data.formats | select * | sort -Property quality
        $format_list 
    }else{
        $avail_formats = [system.collections.arraylist]::new()
        $format_list = $data.formats | select format_note,ext,format_id, format, quality | sort -Property quality
        $format_list | % {
            $obj = [pscustomobject]@{
                Id = $_.format_id
                Format = $_.format
                Quality = $_.quality
                #Note = $_.format_note
                Extension = $_.ext
            }
            [void]$avail_formats.Add($obj)
        }
        $avail_formats
        #$format_list
    }
}   

function Select-BestVideoFormat{ 

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Url,
        [Parameter(Mandatory=$false)]
        [String]$Extension
    )
    
    try{
        $Data = Request-VideoFormats $Url -e
        if($PSBoundParameters.ContainsKey("Extension") -eq $True){
            [psobject[]]$Out = $Data | Where ext -imatch $Extension
            if($Out.Count -gt 0){
                $Out[$Out.Count-1]
            }
        }else{
            $Data[$Data.Count-1]
        }
    }
    catch{
        Write-LogEntry $_
        #Show-InternalMiniErrorPopup "EXCEPTION OCCURED $_"
        Show-ExceptionDetails $_ -ShowStack
    }
}
<#
.SYNOPSIS

Function to get all detailed video information

.DESCRIPTION

Function to get all detailed video information

.PARAMETER Url

Url of the Youtube video

#>
function Select-VideoByQuality{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Url,
        [Parameter(Mandatory=$false)]
        [int]$Quality=3
    )
    
    try{
        $Data = Request-VideoFormats $Url -e
        if($PSBoundParameters.ContainsKey("Extension") -eq $True){
            [psobject[]]$Out = $Data | Where quality -eq $Quality | Where ext -imatch $Extension
            if($Out.Count -gt 0){
                $Out[0]
            }
        }else{
            [psobject[]]$Out = $Data |  Where quality -eq $Quality 
            if($Out.Count -gt 0){
                $Out[0]
            }
        }
    }
    catch{
        Write-LogEntry $_
        #Show-InternalMiniErrorPopup "EXCEPTION OCCURED $_"
        Show-ExceptionDetails $_ -ShowStack
    }
}

function Select-BestAudioFormat{


    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Url,
        [Parameter(Mandatory=$false)]
        [String]$Extension
    )
    
    try{
        $Data = Request-VideoFormats $Url -e
        if($PSBoundParameters.ContainsKey("Extension") -eq $True){
            [psobject[]]$Out = $Data | Where format -imatch 'audio' | Where ext -imatch $Extension | sort -Property filesize -Descending
            if($Out.Count -gt 0){
                $Out[0]
            }
        }else{
            [psobject[]]$Out = $Data | Where format -imatch 'audio' | sort -Property filesize -Descending
            if($Out.Count -gt 0){
                $Out[0]
            }
        }
    }
    catch{
        Write-LogEntry $_
        #Show-InternalMiniErrorPopup "EXCEPTION OCCURED $_"
        Show-ExceptionDetails $_ -ShowStack
    }
}