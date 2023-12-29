# require script to run as admin!
# creates a tempoary working dir
New-TemporaryFile | ForEach-Object { Remove-Item $_; mkdir $_; Set-Location $_; } > $null

# download, extract and generate health report
Invoke-WebRequest https://github.com/aUniqueUser/automations/raw/master/smart/CrystalDiskInfoPortable.zip -OutFile CrystalDiskInfoPortable.zip > $null
Expand-Archive -Path .\CrystalDiskInfoPortable.zip > $null
.\CrystalDiskInfoPortable\DiskInfo64.exe /CopyExit > $null

# wait for the process to run its course before we continue on
$found = $false
$done = $false
Do {
    Try {
        Get-Process -Name DiskInfo64 -ErrorAction Stop > $null
        $found = $true
    }
    Catch { If ($found -eq $true) { $done = $true } }
}
While ($done -eq $false)

# report if bad health
# https://crystalmark.info/en/software/crystaldiskinfo/crystaldiskinfo-health-status/
$hashealthwarn = $false
ForEach ($_ in Get-Content .\CrystalDiskInfoPortable\DiskInfo.txt) {
    If ($_ -match "Health Status") {
        If ($_ -notmatch "Good") { 
            # TODO: Raise an alert in our backend
            Write-Output "!! WARNING: One or more block devices are reported in NON-GOOD health. !!" 
            $hashealthwarn = $true
        }
    }
}

# report if CRC error(s)
$hascrc = $false
ForEach ($_ in Get-Content .\CrystalDiskInfoPortable\DiskInfo.txt) { 
    If ($_ -match "CRC Error Count") {
        $splits = $_.Split(" ")
        For ($i = 0; $i -lt $splits.Length; $i++) {
            #  RawValues is always LEN of 12, lazy code yes
            If ($splits[$i].Length -eq 12) {
                $j = [int]$splits[$i]
                # ANY amount of CRC triggers an alert!
                If ($j -gt 0) {
                    # TODO: Raise an alert in our backend
                    Write-Output "!! CRC WARNING: One or more block devices are reported to have CRC Error(s) !!"
                    $hascrc = $true
                }
            }
        }
    }
}

if ($hashealthwarn -eq $false) { Write-Output "All block devices reported to be in GOOD health." }
if ($hascrc -eq $false) { Write-Output "All block devices are reported to NOT have any CRC Errors." }

# put the full log in stdout
Write-Output "`nFull detailed report is listed below:`n"
Get-Content .\CrystalDiskInfoPortable\DiskInfo.txt

# cleanup the mess
$Path = Get-Location | Select-Object -expand Path
Set-Location ..
Remove-Item -LiteralPath $Path -Recurse -Force
