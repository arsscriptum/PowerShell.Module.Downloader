

   
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  Http
#>

#Requires -Version 5


function Get-Script([string]$prop){
    $ThisFile = $script:MyInvocation.MyCommand.Path
    return ((Get-Item $ThisFile)|select $prop).$prop
}



#===============================================================================
# Root Path
#===============================================================================

$ScriptPath                     = split-path $script:MyInvocation.MyCommand.Path
$ScriptFullName                 = (Get-Item -Path $script:MyInvocation.MyCommand.Path).DirectoryName

$Script:CurrPath                       = $ScriptPath
$Script:RootPath                       = (Resolve-Path "$ScriptPath").Path

Write-Host "========================================================" -f Yellow
Write-Host "                     DEPENDENCIES                       " -f Gray
Write-Host "========================================================" -f Yellow

$Script:DlLinks                  = Join-Path $Script:RootPath "test_download_links.ps1"


. "$Script:DlLinks"


Set-DlModConsoleLogsEnabled -Enabled $True

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



$TestJobsListenerScript = {
      param($BitsAdminExe,[string[]]$Jobs)
  
    try{
        
        $AllTransfered = $False
        $Completed = 0
        $e = "$([char]27)"
        #hide the cursor
        Write-Host "$e[?25l"  -NoNewline  
        
        write-host "$($e)[s" -NoNewline
        do {
            Start-Sleep -Milliseconds 200

            ForEach($job in $Jobs){
                [string]$CurrentState  = &"$BitsAdminExe" "/RAWRETURN" "/GETSTATE" "$job" 
                
                if($CurrentState -match "Unable") {  continue; }

                $CurrentState = $CurrentState.ToUpper()
                if($CurrentState -match "TRANSFERRED"){
                    
                    $Completed = $Completed + 1
                    if($Completed -eq 0){
                        Write-Host "$e[u$e[u$e[u$e[u$e[u$e[u$e[u$e[u$e[u▱▱▱▱▱▱▱▱▱" -n
                    }elseif($Completed -eq 1){
                        Write-Host "$e[u$e[u$e[u$e[u$e[u$e[u$e[u$e[u$e[u▰▰▰▱▱▱▱▱▱" -n
                    }elseif($Completed -eq 2){
                        Write-Host "$e[u$e[u$e[u$e[u$e[u$e[u$e[u$e[u$e[u▰▰▰▰▰▰▱▱▱" -n
                    }else{
                        Write-Host "$e[u$e[u$e[u$e[u$e[u$e[u$e[u$e[u$e[u▰▰▰▰▰▰▰▰▰" -n
                    }
                }
            }
            if($Completed -eq 3){
                Write-Host "$e[u$e[u$e[u$e[u$e[u$e[u$e[u$e[u$e[u▰▰▰▰▰▰▰▰▰     <-- Completed" -n
                $AllTransfered = $True
            }
        }while($AllTransfered -eq $False)
    }catch{
        Write-Error $_
    }finally{
        #restore scrolling region
        Write-Host "$e[s$($e)[r$($e)[u" -NoNewline
        #show the cursor
        Write-Host "$e[?25h" 
        Write-Host "`n"
}}.GetNewClosure()

[scriptblock]$TestJobsListenerSb = [scriptblock]::create($TestJobsListenerScript) 



Function Write-TestLog {     
    PARAM(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="LogEntry", Position=0)]
        [string] $LogEntry,
        [Parameter(Mandatory=$false)]
        [Alias('s')]
        [int]    $Severity=1,
        [Parameter(Mandatory=$false)] 
        [Alias('f')]
        [string] $FontColor="Gray",
        [Parameter(Mandatory=$false)] 
        [Alias('i')]
        [int]    $Indent = 0,
        [Parameter(Mandatory=$false)] 
        [Alias('n')]
        [switch] $NoNewLine,
        [Parameter(Mandatory=$false)] 
        [Alias('c')]
        [string] $Category
    )


    $Param = @{
        LogEntry    = $LogEntry
        Severity    = $Severity
        FontColor   = $FontColor
        Indent      = $Indent
        NoNewLine   = $NoNewLine
        Category    = "test"   
    }
    Write-LogEntry @Param
}

New-Alias -Name 'test_log' -Value Write-TestLog -Force -ErrorAction Ignore