#!/bin/bash

echo "Starting backend server..."
(cd backend && npm start) &
BACKEND_PID=$!
echo "Backend PID: $BACKEND_PID"
echo $BACKEND_PID > .backend.pid

echo "Starting frontend server..."
(cd frontend && npm start) &
FRONTEND_PID=$!
echo "Frontend PID: $FRONTEND_PID"
echo $FRONTEND_PID > .frontend.pid

echo "Both servers started in the background."
echo "Check terminal output for frontend URL (e.g., http://localhost:XXXX)."
echo "Use ./stop-all.sh to stop them."