# Find and stop the backend server process
Write-Host "Attempting to stop backend server..."
$backendProcesses = Get-CimInstance Win32_Process -Filter "Name = 'node.exe' AND CommandLine LIKE '%server.js%'"
if ($backendProcesses) {
    $backendProcesses | ForEach-Object {
        Write-Host "Stopping backend process with PID: $($_.ProcessId)"
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Backend server process(es) stopped."
} else {
    Write-Host "Backend server process not found."
}

# Find and stop the frontend development server process
Write-Host "Attempting to stop frontend development server..."
# Parcel often spawns multiple node processes, look for the main parcel command
$frontendProcesses = Get-CimInstance Win32_Process -Filter "Name = 'node.exe' AND CommandLine LIKE '%parcel%index.html%'"
if ($frontendProcesses) {
    $frontendProcesses | ForEach-Object {
        Write-Host "Stopping frontend process with PID: $($_.ProcessId)"
        # Stopping the main parcel process should terminate its children
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
     Write-Host "Frontend development server process(es) stopped."
} else {
    Write-Host "Frontend development server process not found."
}

Write-Host "Application stop process completed."