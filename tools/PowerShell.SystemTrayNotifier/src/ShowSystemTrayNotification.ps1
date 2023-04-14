<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍   
#̷𝓍   
#>


function Show-SystemTrayNotification{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Text,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Title,
        [Parameter(Mandatory=$true, Position=2)]
        [string]$Icon,
        [Parameter(Mandatory=$false)]
        [string]$Tooltip='None',
        [Parameter(Mandatory=$false)]
        [int]$Duration=3000
    )
    Add-Type -AssemblyName System.Windows.Forms
    Write-Verbose " Add-Type -AssemblyName System.Windows.Forms"

    Write-Verbose "Show-SystemTrayNotification : Text     `"$Text`""
    Write-Verbose "Show-SystemTrayNotification : Title    `"$Title`""
    Write-Verbose "Show-SystemTrayNotification : Icon     `"$Icon`""
    Write-Verbose "Show-SystemTrayNotification : Tooltip  `"$Tooltip`""
    Write-Verbose "Show-SystemTrayNotification : Duration `"$Duration`""
    
    try{
        [System.Windows.Forms.NotifyIcon]$MyNotifier = [System.Windows.Forms.NotifyIcon]::new()
        #Mouse double click on icon to dispose
        [void](Register-ObjectEvent -ErrorAction Ignore -InputObject $MyNotifier -EventName MouseDoubleClick -SourceIdentifier IconClicked -Action  {
            #Perform cleanup actions on balloon tip
            Write-Verbose 'Disposing of balloon'
            $MyNotifier.dispose()
            Unregister-Event -SourceIdentifier IconClicked
            Remove-Job -Name IconClicked
        })

        $MyNotifier.Icon = [System.Drawing.Icon]::new($Icon)

        if([string]::IsNullOrEmpty($Tooltip) -eq $False){
            $MyNotifier.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::$Tooltip
        }
        
        $MyNotifier.BalloonTipText  = $Text
        $MyNotifier.BalloonTipTitle = $Title
        $MyNotifier.Visible = $true

        #Display the tip and specify in milliseconds on how long balloon will stay visible
        $MyNotifier.ShowBalloonTip($Duration)
    }catch{
        Write-Output $_
    }

}
