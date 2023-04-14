
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>





function Save-UsingWebClient{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="url", Position=0)]
        [string]$Url,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Destination Directory where the files are saved", Position=1)]
        [string]$DestinationPath, 
        [Parameter(Mandatory=$false)]
        [switch]$Asynchronous,
        [Parameter(Mandatory=$false)]
        [string]$ProxyAddress,
        [Parameter(Mandatory=$false)]
        [string]$ProxyUser,
        [Parameter(Mandatory=$false)]
        [string]$ProxyPassword,
        [Parameter(Mandatory=$false)]
        [string]$UserAgent=""
    )

    try{


       ################################################################################
        # Get Url values
        [Uri]$Val = $Url;
        $HttpHost = $Val.Host
        $HttpPathAndQuery = $Val.PathAndQuery
        $FullPathAndQuery = $HttpHost + $HttpPathAndQuery
        $Name = $Val.Segments[$Val.Segments.read_count-1]
        #$Name = "{0}_{1}" -f $TimeStr, $Name
        $HttpReferrer = $HttpHost

        $IsContainer = $False
        $ItemInfo = Get-Item -Path $DestinationPath -ErrorAction Ignore
        if($Null -ne $ItemInfo){
            $IsContainer = $ItemInfo.PSIsContainer
        }
        
        if($IsContainer -eq $True){
          $DestinationPath = Join-Path $DestinationPath $Name
        }

        if(Test-Path $DestinationPath -PathType Leaf){
            $dn = (Get-Item $DestinationPath).DirectoryName
            $bn = (Get-Item $DestinationPath).BaseName
            $ex = (Get-Item $DestinationPath).Extension
            [string]$rndname = (Get-Date).GetDateTimeFormats()[113]
            $rndname = $rndname.Replace(':',"").Replace('0',"")
            $newname = "{0}_{1}{2}" -f "$bn", "$rndname", "$ex"
            $DestinationPath = Join-Path $dn $newname
        }

        Write-LogEntry "[Save-UsingWebClient] Url `"$Url`""
        Write-LogEntry "[Save-UsingWebClient] DestinationPath `"$DestinationPath`""

        $ForceNoCache=$True

        $client = New-Object Net.WebClient
        if( $PSBoundParameters.ContainsKey('ProxyAddress') ){
            Write-Warning ("NetGetFileNoCache''s -ProxyAddress parameter is not tested.")
            $proxy = New-object System.Net.WebProxy "$ProxyAddress"
            $proxy.Credentials = New-Object System.Net.NetworkCredential ($ProxyUser, $ProxyPassword) 
            $client.proxy=$proxy
        }
        
        if($UserAgent -ne ""){
            $Client.Headers.Add("user-agent", "$UserAgent")     
        }else{
            $Client.Headers.Add("user-agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 13_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Mobile/15E148 Safari/604.1") 
        }

        $RequestUrl = "$Url"

        if ($ForceNoCache) {
            # doesn’t use the cache at all
            $client.CachePolicy = New-Object Net.Cache.RequestCachePolicy([Net.Cache.RequestCacheLevel]::NoCacheNoStore)

            $RandId=(new-guid).Guid
            $RandId=$RandId -replace "-"
            $RequestUrl = "$Url" + "?id=$RandId"
        }
        Write-LogEntry "NetGetFileNoCache: Requesting $RequestUrl"
        $client.DownloadFile($RequestUrl,$DestinationPath)
        Write-LogEntry "[Save-UsingWebClient] COMPLETE `"$DestinationPath`""

    }catch{
        Write-Error $_
    }
}



function Save-OnlineStringNoCache{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
       
        [Parameter(Mandatory=$false)]
        [string]$ProxyAddress,
        [Parameter(Mandatory=$false)]
        [string]$ProxyUser,
        [Parameter(Mandatory=$false)]
        [string]$ProxyPassword,
        [Parameter(Mandatory=$false)]
        [string]$UserAgent=""
    )

    $ForceNoCache=$True

    $client = New-Object Net.WebClient
    if( $PSBoundParameters.ContainsKey('ProxyAddress') ){
        Write-Warning ('NetGetStringNoCache''s -ProxyAddress parameter is not tested.')
        $proxy = New-object System.Net.WebProxy "$ProxyAddress"
        $proxy.Credentials = New-Object System.Net.NetworkCredential ($ProxyUser, $ProxyPassword) 
        $client.proxy=$proxy
    }
    
    if($UserAgent -ne ""){
        $Client.Headers.Add("user-agent", "$UserAgent")     
    }else{
        $Client.Headers.Add("user-agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 13_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Mobile/15E148 Safari/604.1") 
    }

    $RequestUrl = "$Url"

    if ($ForceNoCache) {
        # doesn’t use the cache at all
        $client.CachePolicy = New-Object Net.Cache.RequestCachePolicy([Net.Cache.RequestCacheLevel]::NoCacheNoStore)

        $RandId=(new-guid).Guid
        $RandId=$RandId -replace "-"
        $RequestUrl = "$Url" + "?id=$RandId"
    }
    Log-String "NetGetStringNoCache: Requesting $RequestUrl"
    $client.DownloadString($RequestUrl)
}
