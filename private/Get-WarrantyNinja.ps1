function  Get-WarrantyNinja {
    [CmdletBinding()]
    Param(
        [string]$NinjaURL,
        [String]$Secretkey,
        [boolean]$AccessKey,
        [boolean]$OverwriteWarranty
    )
    $Date = (Get-Date -Format r)
    $Command = "GET`n`n`n$($date)`n/v1/devices"
    $EncodedCommand = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Command))

    $HMACSHA = New-Object System.Security.Cryptography.HMACSHA1
    $HMACSHA.Key = [Text.Encoding]::ASCII.GetBytes($SecretAccessKey)
    $Signature = $HMACSHA.ComputeHash([Text.Encoding]::UTF8.GetBytes($EncodedCommand))
    $Signature = [Convert]::ToBase64String($Signature)

    #Generate the Authorization string
    $Authorization = "NJ $AccessKeyID`:$Signature"
    # Bind to the namespace, using the Webserviceproxy
    $Header = @{"Authorization" = $Authorization; "Date" = $Date }

    $Devices = Invoke-RestMethod -Method GET -Uri "https://api.ninjarmm.com/v1/devices" -Headers $Header

    $warrantyObject = foreach ($device in $Devices) {
        $i++
        Write-Progress -Activity "Grabbing Warranty information" -status "Processing $($device.serial). Device $i of $($Devices.Count)" -percentComplete ($i / $Devices.Count * 100)
        $WarState =  Get-Warrantyinfo -DeviceSerial $device.serial -client $device.client

        if ($SyncWithSource -eq $true) {
            switch ($OverwriteWarranty) {
                $true {
                    write-host "NinjaRMM does not support Warranty write-back."               
                }
                $false { 
                    if ($null -eq $device.WarrantyExpirationDate -and $null -ne $warstate.EndDate) { 
                        write-host "NinjaRMM does not support Warranty write-back."      
                    } 
                }
            }
        }
        $WarState
    }
    return $warrantyObject

}