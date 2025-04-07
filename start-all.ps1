# Get the script's directory to resolve relative paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Starting backend server in a new window..."
# Use npm.cmd explicitly for Start-Process
# Removed -WindowStyle Hidden to make the window visible
$backendCommand = "npm.cmd"
$backendArgs = "start"
$backendDir = Join-Path $ScriptDir "backend"
$backendProcess = Start-Process -FilePath $backendCommand -ArgumentList $backendArgs -WorkingDirectory $backendDir -PassThru
$backendProcess.Id | Out-File -Encoding ASCII -FilePath (Join-Path $ScriptDir ".backend.pid")
Write-Host "Backend PID: $($backendProcess.Id)"

Write-Host "Starting frontend server in a new window..."
# Use npm.cmd explicitly for Start-Process
# Removed -WindowStyle Hidden to make the window visible
$frontendCommand = "npm.cmd"
$frontendArgs = "start"
$frontendDir = Join-Path $ScriptDir "frontend"
$frontendProcess = Start-Process -FilePath $frontendCommand -ArgumentList $frontendArgs -WorkingDirectory $frontendDir -PassThru
$frontendProcess.Id | Out-File -Encoding ASCII -FilePath (Join-Path $ScriptDir ".frontend.pid")
Write-Host "Frontend PID: $($frontendProcess.Id)"

Write-Host "Both servers started in separate windows."
Write-Host "Check the frontend server window for the URL (e.g., http://localhost:XXXX)."
Write-Host "Use .\stop-all.ps1 to stop them."