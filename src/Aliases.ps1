<#
  ╓──────────────────────────────────────────────────────────────────────────────────────
  ║   PowerShell Downloader Module
  ╙──────────────────────────────────────────────────────────────────────────────────────
 #>



#===============================================================================
# BitsAdmin.ps1
#===============================================================================

# Download a file
New-Alias -Name dl -Value New-BITSJob -Description 'Create a new download task' -Force
New-Alias -Name bj -Value Get-BITSJobs -Description 'Get the list of BITS Jobs (or BJs)' -Force
New-Alias -Name dldn -Value Complete-BITSJobs -Description 'COMPLETE all the BITS Jobs that have been 100% transfered' -Force

