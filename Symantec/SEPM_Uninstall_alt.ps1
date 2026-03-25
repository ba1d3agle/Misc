Write-Output "========== Symantec Endpoint Protection Removal Started =========="

# Step 1 - Stop Symantec Services
Write-Output "Stopping Symantec services..."

$services = @(
"SepMasterService",
"SmcService",
"SNAC",
"Symantec Endpoint Protection",
"ccSvcHst"
)

foreach ($service in $services) {
    Get-Service -Name $service -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Status -ne "Stopped") {
            Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue
            Write-Output "Stopped service: $($_.Name)"
        }
    }
}

Write-Output "Waiting 20 seconds after stopping services..."
Start-Sleep -Seconds 20


# Step 2 - Kill Symantec Processes
Write-Output "Stopping Symantec processes..."

$processes = @(
"smc",
"ccSvcHst",
"SepMasterService",
"snac"
)

foreach ($proc in $processes) {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Output "Stopped process: $proc"
}

Write-Output "Waiting 20 seconds after stopping processes..."
Start-Sleep -Seconds 20


# Step 3 - Locate Symantec Endpoint Protection
Write-Output "Searching for Symantec Endpoint Protection uninstall entry..."

$apps = Get-ItemProperty `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" ,
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
-ErrorAction SilentlyContinue | Where-Object {
    $_.DisplayName -like "*Symantec Endpoint Protection*"
}

Write-Output "Waiting 20 seconds after registry scan..."
Start-Sleep -Seconds 20


# Step 4 - Run Uninstall
if ($apps) {

    foreach ($app in $apps) {

        Write-Output "Found installation: $($app.DisplayName)"

        $uninstallString = $app.UninstallString

        if ($uninstallString -match "MsiExec.exe") {

            $productCode = ($uninstallString -split " ")[1]

            Write-Output "Running silent uninstall using ProductCode $productCode"

            Start-Process "msiexec.exe" -ArgumentList "/x $productCode /qn /norestart" -Wait

        }
        else {

            Write-Output "Running uninstall command"

            Start-Process "cmd.exe" -ArgumentList "/c $uninstallString /qn /norestart" -Wait
        }
    }

}
else {

    Write-Output "Symantec Endpoint Protection not found."

}

Write-Output "Waiting 20 seconds after uninstall execution..."
Start-Sleep -Seconds 20


# Step 5 - Final Check
Write-Output "Performing verification..."

$check = Get-ItemProperty `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" ,
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
-ErrorAction SilentlyContinue | Where-Object {
    $_.DisplayName -like "*Symantec Endpoint Protection*"
}

if ($check) {
    Write-Output "Symantec Endpoint Protection still detected."
}
else {
    Write-Output "Symantec Endpoint Protection successfully removed."
}

Write-Output "========== SEP Removal Script Completed =========="
