# PowerShell Downloader Module

A PowerShell Module Wrapping the BITS transfer protocol.
The goal is the ability to download multiple files on low bandwith, and resume downloads on errors. 
It also enables me to download files on multiple session (between reboots)


## Example
```
    $PowerBiURL = 'https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe'

    New-BITSJob -Url $Url -Name 'PBIDesktopSetup' -DestinationPath 'C:\Tmp' -Priority 'High'
```



## Links
- [DOCUMENTATION](https://github.com/arsscriptum/PowerShell.Module.Downloader/blob/main/doc/New-BITSJob.md)
- [GITHUB REPOSITORY](https://github.com/arsscriptum/PowerShell.Module.Downloader)
- [DOWNLOAD MODULE](https://arsscriptum.github.io/PowerShell.Module.Downloader.zip)
- [DEMO](https://github.com/arsscriptum/PowerShell.Module.Downloader/blob/main/img/Animation.gif)




