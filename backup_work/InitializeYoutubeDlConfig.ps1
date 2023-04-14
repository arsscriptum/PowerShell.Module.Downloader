
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


function Initialize-YoutubeDlConfig{   
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [String]$Path
    )
    $cfg_small = @"
--no-color
--extract-audio
--external-downloader httpie
# --external-downloader-args ARGS
"@

    $cfg = @"

################################
# GENERAL OPTIONS
################################

# Save all videos under Movies directory in your home directory
-o E:\Music\%(title)s.%(ext)Save

# Do not copy the mtime
--no-mtime

--continue
--write-info-json
--yes-playlist


################################
# Verbosity / Simulation Options
################################
# --quiet
# --no-progress
--no-color
--console-title
# --skip-download
--print-traffic
  

################################
# VIDEO FORMAT
################################
# Download all available video formats
# --all-formats              
# Video format code, see the "FORMAT SELECTION" for all the info          
# --format FORMAT                  

################################
# AUDIO FORMAT
################################
--extract-audio
#  Specify audio format: "best", "aac", "flac", "mp3", "m4a", "opus", "vorbis", or "wav"; "best" by default; No effect without -x
--audio-format FORMAT

################################
# MISCELLANEOUS
################################
# --exec CMD
# --external-downloader
# --external-downloader-args ARGS
"@

    New-Item -Path $path -ItemType file -Force -ErrorAction Ignore | Out-Null
    Set-Content $path -Value $cfg_small

    Write-Host "Wrote file $path" -f Cyan
}

