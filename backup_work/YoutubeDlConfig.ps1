
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>




function Disable-YoutubeDlConfig{   
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [String]$Path
    )
    [string[]]$cfg_data = Get-Content $Path
    $new_cfg = [system.collections.arraylist]::new()
    ForEach($line in $cfg_data){
        $id_option = $line.IndexOf('-')
        $id_comment= $line.IndexOf('#')

        if($id_option -ge 0){
            if($id_comment -eq -1){
                Write-Host "$line" -f DarkRed
                [string]$newline = $line.Substring($id_option)
                $newline = "### [disabled] $newline"
                [void]$new_cfg.Add($newline)
            }elseif($id_option -lt $id_comment){
                Write-Host "$line" -f DarkYellow
                [string]$newline = $line.Substring($id_option)
                $newline = "### [disabled] $newline"
                [void]$new_cfg.Add($newline)
            }else{
                [void]$new_cfg.Add($line)
            }
        }else{
            [void]$new_cfg.Add($line)
        }
    }

    New-Item -Path $Path -ItemType file -Force -ErrorAction Ignore | Out-Null
    Set-Content $Path -Value $new_cfg
    Write-Verbose "$cfg"
    Write-Host "Wrote file $Path" -f Cyan
}


function Enable-YoutubeDlConfig{   
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [String]$Path,
        [Parameter(Mandatory=$false)]
        [switch]$All
    )
    [string[]]$cfg_data = Get-Content $Path
    $new_cfg = [system.collections.arraylist]::new()
    ForEach($line in $cfg_data){
        $id_option = $line.IndexOf('-')
        $id_comment= $line.IndexOf('#')
        $id_disabled= $line.IndexOf('[disabled]')
        if($All){
            if($id_option -ge 0){
                [string]$newline = $line.Substring($id_option)
                Write-Host "$newline" -f DarkGreen
                [void]$new_cfg.Add($newline)
            }else{
                [void]$new_cfg.Add($line)
            }
        }else{
            if(($id_disabled -ge 0) -And ($id_option -ge 0)){
                [string]$newline = $line.Substring($id_option)
                Write-Host "$newline" -f DarkGreen
                [void]$new_cfg.Add($newline)
            }else{
                [void]$new_cfg.Add($line)
            }
        }
    }

    New-Item -Path $Path -ItemType file -Force -ErrorAction Ignore | Out-Null
    Set-Content $Path -Value $new_cfg
    Write-Verbose "$cfg"
    Write-Host "Wrote file $Path" -f Cyan
}


function Reset-ConfigFiles{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $config_files = @("$ENV:APPDATA\youtube-dl\config.txt","C:\Users\gp\youtube-dl.conf")
    $config_files | % {
        $path = $_
        Remove-Item -Path $path -Force -ErrorAction Ignore | Out-Null
    }
}
