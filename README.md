# PowerShell.Module.Downloader

This module provides multiple functions to transfer/download files from a network resource to a local drive.

It also provides ways to download Youtube medias like videos or audio tracks.

## External downloader replacement in Youtube-Dl.

Youtube-dl supports using external downloaders. This can help mitigate artificial throttling that Google appears to be implementing. I found that using aria2 made a massive difference in download speed. To use external downloaders, add the --external-downloader [downloader] option. The list of supported external downloaders is listed in the download options on the github page, but I found it did not work with axel, even though it's listed.

Here is an example usage:
```
    youtube-dl --external-downloader foobar --external-downloader-args '-a -b- c'
```

Unfortunately, the implementation is very restrictive in that it supports only a specific set of appliclication, and you cannot use your own. Currently supports aria2c,avconv,axel,c url,ffmpeg,httpie,wget

## The rationale of changing the download subsysstem in Youtube-Dl

As mentionned above, using your download subsystem can help mitigate artificial throttling that Google appears to be implementing. You can also really benefit from extended functionalities, especially when downloading big playlists. 

### BITS

For example, Windows provides a service called the Background Inelligent Transfer Service, this is used to download the Windows Update huge package files and gives the ability to really custommize the way the files are transfered. My main reason for using my own 
downloader was to use BITS and also use other downloader that provides speed advantages.


## Available Download methods

The module currently provides the following download subsystems:

1. ***http*** : this is using a .NET functionality in PowerShell: ```[System.Net.HttpWebRequest]``` . It creates a custom https GET request with custom header and writes the returned data on disk. You can use this functioality in both blocking and asynchronous mode. Note that if you
   start a download in asynchronous mode you can "re-hook" on your download job at anytime to switch to blocking mode and get transfer data information and a progress bar. See example ...
2. ***bits*** : this is using [PowerShell's BitTransfer module](https://learn.microsoft.com/en-us/powershell/module/bitstransfer/?view=windowsserver2022-ps). When you start a download job with this mode, you get a job managed by the bits service that you can extensively configure.
3. ***bitsadmin*** : this is also downloading using the Bits service, but the jobs are created and managed using Window's [bitsadmin.exe](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/bitsadmin). Bitsadmin is a command-line tool used to create, download or upload jobs, and to monitor their progress. The bitsadmin tool is useful when the Bits module cannot be installed or used.
"bitsadmin"
4. ***wget*** : this method uses the [wget.exe](https://gnuwin32.sourceforge.net/packages/wget.htm) command-line tool. GNU Wget is a free network utility to retrieve files from the World Wide Web using HTTP and FTP. Wget works exceedingly well on slow or unstable connections, keeping getting the document until it is fully retrieved. Re-getting files from where it left off works on servers (both HTTP and FTP) that support it. Wget supports proxy servers, which can lighten the network load, speed up retrieval and provide access behind firewalls.



## Example Usage

### Download using .NET System.Net.HttpWebRequest

PowerShell is based on .NET, and its nature makes it capable of leveraging the power of .NET itself. There’s two .NET class you can use in PowerShell to download files; [WebClient](https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient?view=net-5.0) and [HttpClient](https://docs.microsoft.com/en-us/dotnet/api/system.net.http.httpclient.getasync?view=net-5.0)

If you want to know more about these two .NET class in more development and technical way, you could start with → [When to use WebClient vs. HttpClient vs. HttpWebRequest](https://www.infoworld.com/article/3198673/when-to-use-webclient-vs-httpclient-vs-httpwebrequest.html) In the next section, you will learn how to use WebClient and HttpClient in PowerShell to download files from the web.

Like the WebClient class, you need to create first the System.Net.Http.HttpClient. Using the code below downloads the file from the $source to the $destination. Refer to the comments above each line to know what each line of code does.


#### Authentication

In situations where downloading a file requires authentication, you need to add the credential to the HttpClient object. To include a credential to the file download request, create a new System.Net.Http.HttpClientHandler object to store the credentials.

You can copy the code below and run it in PowerShell to test. Or you can also run it as a PowerShell script. In this example, the code is saved as download-file.ps1.

```
    # BLOCKING CALL (will display a progresss bar)
    $Parameters = @{
        Url = 'https://arsscriptum.github.io/files/heads.png'
        DestinationPath = "c:\Tmp"
        Asynchronous = $False 
    }
    Save-UsingHttpJob @Parameters    # will return after completion


    # ASYNCHRONOUS DOWNLOAD
    $Parameters = @{
        Url = 'https://arsscriptum.github.io/files/heads.png'
        DestinationPath = "c:\Tmp"
        Asynchronous = $True 
    }
    > $Ret = Save-UsingHttpJob @Parameters
    > ....
    # You can get the progress data and switch back to blocking mode by calling `Receive-HttpJob` with the job name
    > Receive-HttpJob $($Ret.JobName)
```


### Download using the BitsTransfer Module


![SaveUsingBitsModule](https://arsscriptum.github.io/files/gifs/SaveUsingBitsModule.gif)

```
    $Parameters = @{
        Url = 'https://arsscriptum.github.io/files/heads.png'
        DestinationPath = "c:\Tmp"
        Asynchronous = $False           # ASYNCHRONOUS
        EnableNotification = $True      # NOTIFICATION
        Priority = 'High'    # Foreground|High|Normal|Low
    }
    Save-UsingBitsModule @Parameters


```

#### NOTE: Notification Option

If you activate the ```EnableNotification``` option. You will get a custom notification after download. I made a custom PowerShell-based message box that will show up along with the Mission Impossible tune.

![Custom Notifier](https://arsscriptum.github.io/files/images/notification.png)

### Download using the bitsadmin.exe commandline tools

```
    $Parameters = @{
        Url = 'https://arsscriptum.github.io/files/heads.png'
        DestinationPath = "c:\Tmp"
        Asynchronous = $False 
        EnableNotification = $True 
        Priority = 'High'    # Foreground|High|Normal|Low
    }
    Save-UsingBitsAdmin @Parameters


    # ASYNCHRONOUS DOWNLOAD
    $Parameters = @{
        Url = 'https://arsscriptum.github.io/files/heads.png'
        DestinationPath = "c:\Tmp"
        Asynchronous = $True 
        EnableNotification = $True 
        Priority = 'High'    # Foreground|High|Normal|Low
    }
    > $CreatedJob = Save-UsingBitsAdmin @Parameters
    > ....
    # You can get the progress data and switch back to blocking mode by calling `Receive-BitsAdminJob` with the job name $JobName
    > Receive-BitsAdminJob $CreatedJob
```

### Download using the wget.exe commandline tools

```
    $Parameters = @{
        Url = 'https://arsscriptum.github.io/files/heads.png'
        DestinationPath = "c:\Tmp"
        Asynchronous = $False 
        EnableNotification = $True 
        Priority = 'High'    # Foreground|High|Normal|Low
    }
    Save-UsingWGetJob @Parameters


    # ASYNCHRONOUS DOWNLOAD
    $Parameters = @{
        Url = 'https://arsscriptum.github.io/files/heads.png'
        DestinationPath = "c:\Tmp"
        Asynchronous = $True 
        EnableNotification = $True 
        Priority = 'High'    # Foreground|High|Normal|Low
    }
    > Save-UsingWGetJob @Parameters

```

### CONCLUSION 

Windows PowerShell and PowerShell Core come with built-in capabilities to download files, acting as a PowerShell wget alternative! Whether downloading password-protected sources, single or multiple files – a PowerShell way is available to you.

The file download methods covered in this article works on both Windows PowerShell and PowerShell Core. This means that these methods apply to both Windows and Non-Windows systems, with the exclusion of Start-BitsTransfer.

And since PowerShell is more than a command prompt, you can translate what you learned into scripts. For you, that would mean an opportunity for automation. No more copying URLs, clicking links, and waiting for downloads manually.

# Youtube Media Download

## Functions to Use

1. [Save-YoutubeVideo](https://github.com/arsscriptum/PowerShell.Module.Downloader/blob/main/doc/Save-YoutubeVideo.md)
2. [Request-VideoFormats](https://github.com/arsscriptum/PowerShell.Module.Downloader/blob/main/doc/Request-VideoFormats.mdRequest-VideoFormats)

## [Save-YoutubeVideo](https://github.com/arsscriptum/PowerShell.Module.Downloader/blob/main/doc/Save-YoutubeVideo.md) - Save Youtube Media with selected Format, using the download tool of your choice.

You do not need to know the format of the video you wish to download. The [Save-YoutubeVideo](https://github.com/arsscriptum/PowerShell.Module.Downloader/blob/main/doc/Save-YoutubeVideo.md) function will automatically select a format based on if you want a video or just an audio track.

For example, if you wish to download a music video of your favourite band, and you don't care about the video, use the ```-AudioOnly``` switch. Else, if you omit this, it will download a 
video format of medium (average quality)

```
        
        $Url = 'https://www.youtube.com/watch?v=ghb6eDopW8I'
        .
        # Download the AUDIO track only, using .NET WebRequest
        >> Save-YoutubeVideo $Url -AudioOnly -DownloadMode 'http'
        -
        # Download the video via BITS
        >> Save-YoutubeVideo $Url -DownloadMode 'bits'

```


It helps if you know the format you wish to download. You can get the list of available formats for a video using ```Request-VideoFormats```
A typical Youtube video is available in these formats (I have trimmed down that list since its example):	

```
	> Request-VideoFormats 'https://www.youtube.com/watch?v=xQ_M3vqVzII'
	Id  Format                    Quality Extension
	--  ------                    ------- ---------
	249 249 - audio only (tiny)         0 webm
	250 250 - audio only (tiny)         0 webm
	251 251 - audio only (tiny)         0 webm
	278 278 - 256x144 (144p)            0 webm
	160 160 - 256x144 (144p)            0 mp4
	242 242 - 426x240 (240p)            1 webm
	18  18 - 640x360 (360p)             2 mp4
	302 302 - 1280x720 (720p60)         4 webm
	136 136 - 1280x720 (720p)           4 mp4
	315 315 - 3840x2160 (2160p60)       7 webm
```

### NOTE about AUDIO formats

In the example above, the formats id 251, 250 and 249 are AUDIO only, meaning that the file will only contain the soundtrack. This is usefull when you download music tracks and you don't need the video. I personally have
multiple music playlists that I download in this format. The files are smaller if you just want music :)


## Get Video availables Formats

```
	> Request-VideoFormats 'https://www.youtube.com/watch?v=xQ_M3vqVzII'


	Id  Format                    Quality Extension
	--  ------                    ------- ---------
	249 249 - audio only (tiny)         0 webm
	...
	278 278 - 256x144 (144p)            0 webm
	18  18 - 640x360 (360p)             2 mp4
	244 244 - 854x480 (480p)            3 webm

```


## EXAMPLES of Downloading Youtube Media

```
        
        $Url = 'https://www.youtube.com/watch?v=ghb6eDopW8I'
        
        -
        # Download the video format 251 using bitsadmin, async
        >> Save-YoutubeVideo $Url -FormatId 251 -DownloadMode 'bitsadmin' -Asynchronous

```


# ADVANCED CONCEPTS

## DEMONSTRATION using BITS

Here we start a download job for a Youtube video, we then use the BitsTransfer module to change the JOB priority. Then we use the bitsadmin.exe command line tool to monitor the transferring job.

![SaveYoutubeVideo](/assets/img/posts/ps-module-downloader/SaveYoutubeVideo_1.gif)



## GET THE VIDEO FORMATS for a specific Extension (file type)


![RequestVideoFormats](/assets/img/posts/ps-module-downloader/RequestVideoFormats_1.gif)


