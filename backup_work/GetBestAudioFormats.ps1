
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>




function Convert-ArrayToVideoData {        # NOEXPORT
<#  
    .Synopsis
       Repair-WinGetOutput : Gets a string and repair it.
#>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, position=0)]
        [system.collections.arraylist]$data 
    )
    $videos_details_list = [system.collections.arraylist]::new()
    $format_start=0
    $ptrn_title = "^(?<format>format)(\s*)(?<code>code)(\s*)(?<extension>extension)(\s*)(?<resolution>resolution)(\s*)(?<note>note)"
    $ptrn_title = "^(?<format>format code)(\s*)(?<extension>extension)(\s*)(?<resolution>resolution)(\s*)(?<note>note)"
    $numlines = $data.Count
    while($data[$format_start] -notmatch $ptrn_title) { $format_start++ }
    Write-Verbose "format_start at $format_start"

    $title_line = $data[$format_start]

    # Indexes...
    $id_start = $title_line.IndexOf('format code')
    $id_extension = $title_line.IndexOf('extension')
    $id_resolution = $title_line.IndexOf('resolution')
    $id_note = $title_line.IndexOf('note')
            
    for($i = $format_start + 1 ; $i -lt $numlines ; $i++){
        [string]$fmt_code = $data[$i].Substring($id_start, $id_extension - $id_start).Trim()
        [string]$extension_data = $data[$i].Substring($id_extension, $id_resolution - $id_extension).Trim()
        [string]$res_data = $data[$i].Substring($id_resolution, $id_note - $id_resolution).Trim()

         $id_note_next = $data[$i].IndexOf(' ', $id_note)
         [string]$note_data = $data[$i].Substring($id_note, $id_note_next - $id_note).Trim()
        [string]$ext_data = $data[$i].Substring($id_note_next, (($data[$i].Length) - $id_note_next)).Trim()

        $video_obj = [PSCustomObject]@{
            Code = $fmt_code
            Resolution = $res_data
            Note = $note_data
        }
               
        [string[]]$ext_data_array = $ext_data.split(',')
        $ext_id = 0
        $ext_data_array | % {
            $ext_data_value = $_.Trim()
            $prop_name = "Quality_{0}" -f $ext_id++
            $video_obj | Add-Member -MemberType NoteProperty -Name $prop_name -Value $ext_data_value
        }
                
        [void]$videos_details_list.Add($video_obj)
    }
    $videos_details_list
}

function Get-BestAudioFormat{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Url,
        [Parameter(Mandatory=$false)]
        [switch]$ShowAll
    )
   
    $YoutubeDlPath = Get-YoutubeDlPath

    [string[]]$vurls = Get-Content -Path $UrlList
    $alist = @('--ignore-errors', '--flat-playlist',  '--write-info-json', '--skip-download', '--list-formats')

    $video_data_list = [system.collections.arraylist]::new()
    [string[]]$cmd_result = @()
    $audio_vid_data += [Ordered]@{}
   
    Write-Host "Getting Formats for $Url"

    $as = $alist
    $as += $Url

    $psargs = @{
        ExePath = $YoutubeDlPath
        ArgumentList = $as
    }
        
    $res = Invoke-Process @psargs
    [string[]]$cmd_result = $res.Output -split "`n"
        
    $video_data = Convert-ArrayToVideoData $cmd_result
    if($ShowAll){
        $video_data | where Resolution -imatch 'audio only' | sort -Property Quality_4| select  -Property 
    }else{
        $video_data | where Resolution -imatch 'audio only' | sort -Property Quality_4 | select -Last 1 -Property Code, Quality_0, Quality_3
    }
}


function Get-BestAudioFormatForUrls{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$UrlList,
        [Parameter(Mandatory=$false)]
        [switch]$ShowAll
    )
   
    if(-not (test-path $UrlList)){
        throw "cannot find URL LIST File"
    }
    $result_list = [system.collections.arraylist]::new()
    ForEach($u in (Get-Content $UrlList)){
        $video_data = Get-BestAudioFormat $u -ShowAll:$ShowAll
        [void]$audio_vid_data.Add($video_data)
    }
    $audio_vid_data
}
