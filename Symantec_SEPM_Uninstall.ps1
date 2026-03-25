# This script works smooth after disabling tamper protection via the SEPM cloud console
# The password requirement to disable / tamper with the SEPM uninstaller has been disabled

$in = (Get-WmiObject Win32_Product | Where-Object { $_.Name -like "*Symantec*" }).IdentifyingNumber

Write-Output "$in"
if ($in) {
    Start-Process msiexec.exe -ArgumentList "/x $in /qn /norestart" -Wait
}
