# Get the script's directory to resolve relative paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$backendPidFile = Join-Path $ScriptDir ".backend.pid"
$frontendPidFile = Join-Path $ScriptDir ".frontend.pid"

# Stop Backend Process
if (Test-Path $backendPidFile) {
    try {
        $backendPid = Get-Content $backendPidFile -ErrorAction Stop
        Write-Host "Stopping backend process (PID: $backendPid)..."
        Stop-Process -Id $backendPid -Force -ErrorAction Stop
        Write-Host "Backend process stopped."
    } catch {
        Write-Warning "Could not stop backend process (PID: $backendPid). It might already be stopped or the PID file is invalid. Error: $($_.Exception.Message)"
    } finally {
        Remove-Item $backendPidFile -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "Backend PID file not found. Assuming backend process is not running or was not started by start-all.ps1."
}

# Stop Frontend Process
if (Test-Path $frontendPidFile) {
    try {
        $frontendPid = Get-Content $frontendPidFile -ErrorAction Stop
        Write-Host "Stopping frontend process (PID: $frontendPid)..."
        Stop-Process -Id $frontendPid -Force -ErrorAction Stop
        Write-Host "Frontend process stopped."
    } catch {
        Write-Warning "Could not stop frontend process (PID: $frontendPid). It might already be stopped or the PID file is invalid. Error: $($_.Exception.Message)"
    } finally {
        Remove-Item $frontendPidFile -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "Frontend PID file not found. Assuming frontend process is not running or was not started by start-all.ps1."
}

Write-Host "Stop script finished."