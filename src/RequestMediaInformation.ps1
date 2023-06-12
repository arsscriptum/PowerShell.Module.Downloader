
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
        [Parameter(Mandatory=$false)]
        [ValidateSet('m4a','webm')]
        [String]$AudioExtension='webm',
        [Parameter(Mandatory=$false, HelpMessage="Download the AUDIO track only")]
        [Alias('a')]
        [switch]$AudioOnly,
        [Parameter(Mandatory=$false, HelpMessage="Download mode selection: wget, http, bits, bitsadmin")]
        [Alias('m')]
        [ValidateSet('wget',"http","bits","bitsadmin")]
        [string]$DownloadMode="bits",    
        [Parameter(Mandatory=$false, HelpMessage="If set, the command will return right away and download is done in the background")]
        [switch]$Asynchronous,    
        [Parameter(Mandatory=$false, HelpMessage="If set, download from https protocol only")]
        [switch]$ForceHttps
    )

    try{
        $TestMode = $False
        if( ($PSBoundParameters.ContainsKey("WhatIf")) -Or ($PSBoundParameters.ContainsKey("Debug"))){
            $TestMode = $True
            Write-Debug "==============================================================================="
            Write-Debug "                         *** DEBUG Save-YoutubeVideo ***                       "
            Write-Debug "==============================================================================="
        }

        Write-Debug "---------------------------------------------------"
        Write-Debug "[Request-VideoInformation] Url `"$Url`""
        $VideoInformation = Request-VideoInformation $Url
        Write-Debug "---------------------------------------------------"

        [string]$DownloadUrl = ''
        [string]$Extension = $VideoInformation.ext
        
        if($Protocol -eq 'any'){
            $Protocol = 'http_dash_segments|https'
        }
        $VideoFormats = $VideoInformation.formats | select * 
        [int]$FileSize = 0
        if($PSBoundParameters.ContainsKey("FormatId") -eq $True){
            $Found = $False
            $VideoFormats | % { 
                if($_.format_id -eq $FormatId){
                 $DownloadUrl = $_.url
                 $Extension =  $_.ext
                 $FileSize = $_.filesize_approx
                 $Found = $True
             } 
            }
            if(!($Found)){ throw "Could not find url for format id $FormatId" }
   
        }else{
            if($AudioOnly){
                $selected =  $VideoFormats | Where acodec -ne 'none' | Where vcodec -eq 'none' | where ext -eq "$AudioExtension" |  Sort -Property quality -Descending | select -First 1
                $DownloadUrl =  $selected.url
                $Extension =  $selected.ext
                $FileSize = $selected.filesize_approx

            }else{
                if($ForceHttps){
                    $selected = $VideoFormats | Where vcodec -ne 'none' | Where acodec -ne 'none' | Where protocol -eq "https" | Sort -Property quality -Descending | select -First 1
                }else{
                    $selected = $VideoFormats | Where vcodec -ne 'none' | Where acodec -ne 'none' | Sort -Property quality -Descending | select -First 1
                }
                
                $DownloadUrl =  $selected.url
                $Extension =  $selected.ext
                $FileSize = $selected.filesize_approx
            }
        }


        [string]$Title = $VideoInformation.title

        $CleanFilename = Get-CleanFilename $Title

        $DownloadVideoPath = Join-Path $DestinationPath $CleanFilename
        if(-not(Test-Path -Path $DownloadVideoPath -PathType Container)){
            $Null = New-Item -Path $DownloadVideoPath -ItemType "Directory" -Force -ErrorAction Ignore 
        }
        $Num = 0
        [string]$DestinationFile = "{0}\{1}.{2}" -f $DownloadVideoPath, $CleanFilename, $Extension
        $Exists = Test-Path -Path $DestinationFile -PathType Leaf
        while($Exists){
            $Num = $Num + 1
            $DestinationFile = "{0}\{1}-{2:d4}.{3}" -f $DownloadVideoPath,  $CleanFilename,$Num, $Extension
            $Exists = Test-Path -Path $DestinationFile -PathType Leaf
        }
        [string]$VideoDesc = $VideoInformation.description

        $DescriptionPath = Join-Path $DownloadVideoPath "Description.txt"
        try{
            if(-not(Test-Path -Path $DescriptionPath -PathType Leaf)){
                Set-Content "$DescriptionPath" "$VideoDesc" -Force -Encoding 'ascii' -ErrorAction Stop 
            }
        }catch{
            Write-Host "[ERROR] " -n -f DarkRed
            Write-Host "Write Description file : $_" -f DarkYellow
        }
        [string]$ThumbnailUrl = $VideoInformation.thumbnail


        if($TestMode){
            Write-Debug "================================================================"
            Write-Debug "================================================================"
            Write-Debug "DownloadUrl      : $DownloadUrl"
            Write-Debug "DestinationFile  : $DestinationFile"
            Write-Debug "DownloadMode     : $DownloadMode"
            Write-Debug "Filename         : $CleanFilename"
            Write-Debug "Extension        : $Extension"
            Write-Debug "Title            : $Title"
            Write-Debug "DownloadVideoPath: $DownloadVideoPath"
            Write-Debug "VideoDesc.Length : $($VideoDesc.Length)"
            Write-Debug "ThumbnailUrl     : $ThumbnailUrl"
            Write-Debug "FileSize         : $FileSize bytes"
            [string]$FileSizeStr = Convert-Bytes $FileSize -Format MB
            Write-Debug "FileSize         : $FileSizeStr"
            $UrlInvalid = ([string]::IsNullOrEmpty($DownloadUrl))
            $PathInvalid = ([string]::IsNullOrEmpty($DestinationPath))
            $ExtInvalid = ([string]::IsNullOrEmpty($Extension))
            Write-Debug "UrlInvalid      : $UrlInvalid"
            Write-Debug "PathInvalid     : $PathInvalid"
            Write-Debug "ExtInvalid      : $ExtInvalid"
            Write-Debug "================================================================"
            Write-Debug "================================================================"

            if($UrlInvalid -Or $PathInvalid -Or $ExtInvalid){
                $Err=@"
Save-YoutubeVideo : Invalid argument
DownloadUrl      : `"$DownloadUrl`"
DestinationFile  : `"$DestinationFile`"
DownloadMode     : `"$DownloadMode`"
"@
            throw "$Err"
        }

            return "$DestinationFile"
        }
        ########################################################################
        #                      Save-InternetFile
        ########################################################################
   
        switch( $DownloadMode ){

            'wget'      {
                            $Job = Save-UsingWGetJob -Url "$DownloadUrl" -DestinationPath "$DestinationFile" -Asynchronous:$Asynchronous
                        }

            "http"      {
                            $Job = Save-UsingHttpJob -Url "$DownloadUrl" -DestinationPath "$DestinationFile" -Asynchronous:$Asynchronous
                        }
            "bitsadmin" {
                            $Job = Save-UsingBitsAdmin -Url "$DownloadUrl" -DestinationPath "$DestinationFile" -Asynchronous:$Asynchronous
                        }
            "bits"      {
                            $Job = Save-UsingBitsModule -Url "$DownloadUrl" -DestinationPath "$DestinationFile" -Asynchronous:$Asynchronous
                        }
        }
        <#if($Asynchronous -ne $True){
            $Icon = 'youtube_color'
            $Title = "DOWNLOAD COMPLETE"
            $Text = "$DestinationFile"
            $Duration = 5000
            New-SystemTrayNotifier -Text "$Text" -Title $Title -Duration $Duration -ExtendedIcon $Icon
        }#>
        "$DestinationFile"
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
        
        Write-Debug "Youtube Dl : $YoutubeDlPath"
        Write-Debug "Output file: $Path"

        &"$YoutubeDlPath" '-j' "$Url" > $Path
        $Success = $?
        $JsonSize = (gi $Path).Length

        Write-Debug "Operation Success : $Success"
        Write-Debug "Output file size  : $JsonSize"

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
.ExternalHelp  https://arsscriptum.github.io/files/help/ModDl-help.xml
#>

function Request-VideoFormats{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, HelpMessage="Url of the Youtube video", Position=0)]
        [string]$Url,
        [Parameter(Mandatory=$false)]
        [switch]$SelectAllProperties
    )
    $Data = Request-VideoInformation $Url
    if($SelectAllProperties){
        $VideoFormats = $Data.formats | select * | sort -Property quality
    }else{
        $VideoFormats = $Data.formats | select format_id, protocol, vcodec, acodec, ext, height,  width, format, audio_ext, video_ext, http_headers | sort -Property quality
    }
    
    $VideoFormats
}   


function Select-BestVideoFormat{ 

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Url,
        [Parameter(Mandatory=$false)]
        [switch]$AudioIncluded
    )
    
    try{
        $Data = Request-VideoFormats $Url
        if($AudioIncluded){
            $Merged = $Data | Where vcodec -ne 'none' | Where acodec -ne 'none' | Sort -Property quality -Descending | select -First 1
            return $Merged
        }
        $ReturnFmt = $Data | Sort -Property quality -Descending | select -First 1
        return $ReturnFmt
    }
    catch{
        Write-LogEntry $_
        Show-ExceptionDetails $_ -ShowStack
    }
}

function Select-BestAudioFormat{


    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Url,
        [Parameter(Mandatory=$false)]
        [ValidateSet('m4a','webm','3gp')]
        [String]$Extension='m4a'
    )
    
    try{
        $Data = Request-VideoFormats $Url -e
        $ReturnFmt =  $Data | Where acodec -ne 'none' | Where vcodec -eq 'none' | where ext -eq "$Extension" |  Sort -Property quality -Descending | select -First 1
        return $ReturnFmt
    }
    catch{
        Write-LogEntry $_
        #Show-InternalMiniErrorPopup "EXCEPTION OCCURED $_"
        Show-ExceptionDetails $_ -ShowStack
    }
}