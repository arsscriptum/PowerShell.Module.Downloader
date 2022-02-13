<#
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
##
##  Quebec City, Canada, MMXXI
#>

#===============================================================================
# Dependencies
#===============================================================================

$ModuleDependencies = @( 'CodeCastor.PowerShell.Core' )
$FunctionDependencies = @( 'Show-ExceptionDetails','Get-ScriptDirectory' )
$EnvironmentVariable = @( 'OrganizationHKCU', 'OrganizationHKLM' )

try{
    $ScriptMyInvocation = $Script:MyInvocation.MyCommand.Path
    $CurrentScriptName = $Script:MyInvocation.MyCommand.Name
    $PSScriptRootValue = 'null' ; if($PSScriptRoot) { $PSScriptRootValue = $PSScriptRoot}
    $ModuleName = (Get-Item $PSScriptRootValue).Name
    Write-Host "===============================================================================" -f DarkRed
    Write-Host "MODULE $ModuleName BUILD CONFIGURATION AND VALIDATION" -f DarkYellow;
    Write-Host "===============================================================================" -f DarkRed    

    Write-Host "[CONFIG] " -f Blue -NoNewLine
    Write-Host "CHECKING ENVIRONMENT VARIABLE.."
    $EnvironmentVariable.ForEach({
        $EnvVar=$_
        $Var = [System.Environment]::GetEnvironmentVariable($EnvVar,[System.EnvironmentVariableTarget]::User)
        if($Var -eq $null){
            throw "ERROR: MISSING $EnvVar Environment Variable"
        }else{
            Write-Host "`t`t[OK]`t" -f DarkGreen -NoNewLine
            Write-Host "$EnvVar"
        }
    })
    Write-Host "[CONFIG] " -f Blue -NoNewLine
    Write-Host "CHECKING MODULE DEPENDENCIES..."
    $ModuleDependencies.ForEach({
        $ModuleName=$_
        $ModPtr = Get-Module "$ModuleName" -ErrorAction Ignore
        if($ModPtr -eq $null){
            throw "ERROR: MISSING $ModuleName module. Please import the dependency $ModuleName"
        }else{
            Write-Host "`t`t[OK]`t" -f DarkGreen -NoNewLine
            Write-Host "$ModuleName"
        }
    })
    Write-Host "[CONFIG] " -f Blue -NoNewLine
    Write-Host "CHECKING FUNCTION DEPENDENCIES..."
    $FunctionDependencies.ForEach({
        $Function=$_
        $FunctionPtr = Get-Command "$Function" -ErrorAction Ignore
        if($FunctionPtr -eq $null){
            throw "ERROR: MISSING $Function function. Please import the required dependencies"
        }else{
            Write-Host "`t`t[OK]`t" -f DarkGreen -NoNewLine
            Write-Host "$Function"
        }
    })
}catch{

}

# SIG # Begin signature block
# MIIFxAYJKoZIhvcNAQcCoIIFtTCCBbECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNyZX0Rnru0v4qVgPuTeDRTPa
# wZ6gggNNMIIDSTCCAjWgAwIBAgIQmkSKRKW8Cb1IhBWj4NDm0TAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0yMjAyMDkyMzI4NDRaFw0zOTEyMzEyMzU5NTlaMCUxIzAhBgNVBAMTGkFyc1Nj
# cmlwdHVtIFBvd2VyU2hlbGwgQ1NDMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEA60ec8x1ehhllMQ4t+AX05JLoCa90P7LIqhn6Zcqr+kvLSYYp3sOJ3oVy
# hv0wUFZUIAJIahv5lS1aSY39CCNN+w47aKGI9uLTDmw22JmsanE9w4vrqKLwqp2K
# +jPn2tj5OFVilNbikqpbH5bbUINnKCDRPnBld1D+xoQs/iGKod3xhYuIdYze2Edr
# 5WWTKvTIEqcEobsuT/VlfglPxJW4MbHXRn16jS+KN3EFNHgKp4e1Px0bhVQvIb9V
# 3ODwC2drbaJ+f5PXkD1lX28VCQDhoAOjr02HUuipVedhjubfCmM33+LRoD7u6aEl
# KUUnbOnC3gVVIGcCXWsrgyvyjqM2WQIDAQABo3YwdDATBgNVHSUEDDAKBggrBgEF
# BQcDAzBdBgNVHQEEVjBUgBD8gBzCH4SdVIksYQ0DovzKoS4wLDEqMCgGA1UEAxMh
# UG93ZXJTaGVsbCBMb2NhbCBDZXJ0aWZpY2F0ZSBSb290ghABvvi0sAAYvk29NHWg
# Q1DUMAkGBSsOAwIdBQADggEBAI8+KceC8Pk+lL3s/ZY1v1ZO6jj9cKMYlMJqT0yT
# 3WEXZdb7MJ5gkDrWw1FoTg0pqz7m8l6RSWL74sFDeAUaOQEi/axV13vJ12sQm6Me
# 3QZHiiPzr/pSQ98qcDp9jR8iZorHZ5163TZue1cW8ZawZRhhtHJfD0Sy64kcmNN/
# 56TCroA75XdrSGjjg+gGevg0LoZg2jpYYhLipOFpWzAJqk/zt0K9xHRuoBUpvCze
# yrR9MljczZV0NWl3oVDu+pNQx1ALBt9h8YpikYHYrl8R5xt3rh9BuonabUZsTaw+
# xzzT9U9JMxNv05QeJHCgdCN3lobObv0IA6e/xTHkdlXTsdgxggHhMIIB3QIBATBA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdAIQ
# mkSKRKW8Cb1IhBWj4NDm0TAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAig
# AoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUnad6Im/XXfwoR6QAD1Sm
# yf1Kvl4wDQYJKoZIhvcNAQEBBQAEggEAJnh+q1q984hWWL20U+9OKcMIglxHChug
# LA5xaW6czQ4XhddGNmBwoZHnnCXjNH/cWmlq6AN7mjjx9fU3mpVDNEW/ceMMMQoC
# PLiua6BiMXEj6NGMBAQ4JZSKt0mCDmQErnEgNfTtaZD0zbUXu3JN+EGog8OSxzL5
# qB6mP6iPyfmzkrQQRPNnP6meu0HTAdeJLZRQQqK2EIRzMqzjrL6hrq/oB09UEnA7
# Q5Y0YKinCqVj9XwDtslLMs2F8kb3N8N4OS5s/2DOZX0ILwNCJQo2CSfskTUb//RK
# p0WZXrbyck7wC/ZZKABPtvI0Xfg2b+MwAAYwZmUEm1gzfH5+co6UMw==
# SIG # End signature block
