 
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  
#>



function New-SystemTrayNotifier{
    <#
    .Synopsis
        Display a balloon tip message in the system tray.

    .Description
        This function displays a user-defined message as a balloon popup in the system tray. This function
        requires Windows Vista or later.

    .Parameter Message
        The message text you want to display.  Recommended to keep it short and simple.

    .Parameter Title
        The title for the message balloon.

    .Parameter MessageType
        The type of message. This value determines what type of icon to display. Valid values are

    .Parameter SysTrayIcon
        The path to a file that you will use as the system tray icon. Default is the PowerShell ISE icon.

    .Parameter Duration
        The number of seconds to display the balloon popup. The default is 1000.

    .Inputs
        None

    .Outputs
        None

    .Notes
         NAME:      Invoke-BalloonTip
         VERSION:   1.0
         AUTHOR:    Boe Prox
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Text,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Title,
        [Parameter(Mandatory=$false)]
        [int]$Duration=5000,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Error', 'Info', 'None', 'Warning')]
        [Alias("t")]
        [string]$Tooltip='None',
        [Parameter(Mandatory=$false)]
        [ValidateSet('download', 'download1', 'error', 'house', 'info', 'lightning', 'mobile', 'phone', 'pin', 'setting', 'tools', 'upload-in-cloud', 'youtube', 'youtube_color')]
        [Alias("i")]
        [string]$ExtendedIcon,
        [Parameter(Mandatory=$false)]
        [string]$ProcessIcon
    )


    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.NotifyIcon]$MyNotifier = [System.Windows.Forms.NotifyIcon]::new()
    #Mouse double click on icon to dispose
    [void](Register-ObjectEvent -ErrorAction Ignore -InputObject $MyNotifier -EventName MouseDoubleClick -SourceIdentifier IconClicked -Action  {
        #Perform cleanup actions on balloon tip
        Write-Verbose 'Disposing of balloon'
        $MyNotifier.dispose()
        Unregister-Event -SourceIdentifier IconClicked
        Remove-Job -Name IconClicked
      
    })

 
    if($PSBoundParameters.ContainsKey('ProcessIcon') -eq $True){
        $apppath =  Get-Process | Where Name -match $ProcessIcon | Select -Unique | Select-Object -ExpandProperty Path
        $MyNotifier.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($apppath)
    }else{
        $ModPath = (Get-CoreModuleInformation).ModuleScriptPath
        $ExportsPath = Join-Path $ModPath 'exports\icons'

        $IconPath = Join-Path $ExportsPath $ExtendedIcon
        $IconPath += '.ico'
        $MyNotifier.Icon = [System.Drawing.Icon]::new($IconPath)
    }

    $MyNotifier.BalloonTipText  = $Text
    $MyNotifier.BalloonTipTitle = $Title
    $MyNotifier.Visible = $true

    #Display the tip and specify in milliseconds on how long balloon will stay visible
    $MyNotifier.ShowBalloonTip($Duration)
}



<#
    ## TEST
    $Tooltip='Warning'
    $Icon = 'Question'
    $Title = " "
    $Text = "file saved to .."
    $Duration = 5000
    New-SystemTrayNotifier -Text "$Text" -Title $Title -Duration $Duration -i 'youtube' -t 'Info' -ProcessIcon 'sub'
#>