# Navigate to the backend directory, install dependencies, and start the server
Write-Host "Installing backend dependencies..."
Push-Location backend
npm install
Write-Host "Starting backend server..."
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "npm start"
Pop-Location

# Navigate to the frontend directory, install dependencies, and start the development server
Write-Host "Installing frontend dependencies..."
Push-Location frontend
npm install
Write-Host "Starting frontend development server..."
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "npm start"
Pop-Location

Write-Host "Application start initiated."