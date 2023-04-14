<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/  Http
#>





[CmdletBinding(SupportsShouldProcess)]
    param( 
        [Parameter(Mandatory=$false)]
        [ValidateSet('all','module','build-tools','export-tools')]
        [Alias('m')]
        [switch]$CompileMode,
        [Parameter(Mandatory=$false)]
        [switch]$Full
    )
try{

        $PushdCount = 0
        $ModuleIdentifier = 'PowerShell.Module.Downloader'

        $RootPath = (Resolve-Path "$PSScriptRoot").Path
        $NotifierRootPath = Join-Path $RootPath 'tools\PowerShell.SystemTrayNotifier'
        $NotifierCompiler = Join-Path $NotifierRootPath 'Compile-Runner.ps1'

        $Segments = $RootPath.split('\')
        $DirName = $Segments[$Segments.Count-1]
        if($DirName -ne $ModuleIdentifier){
            throw "This script must be run in the ROOT folder."
        }

        # Module Paths
        $ExportsPath = Join-Path $RootPath 'exports'


        # Tool Notifier Paths
        $BinPath = Join-Path $NotifierRootPath 'bin'
        $ImgPath = Join-Path $NotifierRootPath 'img'
        $IcoPath = Join-Path $ImgPath 'ico'
        $SrcPath = Join-Path $RootPath 'src'


        # ===================================
        # Compile the Notifier Tool
        # ===================================
        Push-Location $NotifierRootPath
        $PushdCount++
        . "$NotifierCompiler"
        Pop-Location
        $PushdCount--


        # ===================================
        # Export the Notifier Tool
        # ===================================
        Write-Host "Exporting Tool SystemTrayNotifier to Module Export path..."
        $CopiedBinFiles = Copy-Item -Path "$BinPath\*.exe" -Destination $ExportsPath  -Passthru -ErrorAction Ignore
        $CopiedBinFilesCount = $CopiedBinFiles.Count

        $BinFiles = gci $ExportsPath -File
        Write-Host "Exported $CopiedBinFilesCount files to `"$ExportsPath`"" 
        $BinFiles.Name

        Write-Host "Exporting Tool SystemTrayNotifier Required Data to Module Export path..."
        $CopiedBinFiles = Copy-Item -Path "$BinPath\ico" -Destination "$ExportsPath\ico"  -Recurse -Passthru -ErrorAction Ignore
        $CopiedBinFilesCount = $CopiedBinFiles.Count
        $IcoFiles = gci "$ExportsPath\ico" -File
        Write-Host "Exported $CopiedBinFilesCount files to `"$ExportsPath\ico`"" 
        $IcoFiles.Name

        # ===================================
        # Build the Module
        # ===================================

        make -i -d


}catch {
    Write-Error $_    
}finally{

    Write-Host "Compleing Build task."
    Write-Host "PushdCount $PushdCount"
    $PushdCount | % { 
        $CurrPath = (Get-Location).Path
        Write-Host "  CurrPath $CurrPath"
        Write-Host "  PopLocation"
        popd 
    }
}

 