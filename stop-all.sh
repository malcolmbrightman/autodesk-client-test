#!/bin/bash

echo "Stopping servers..."

if [ -f .frontend.pid ]; then
    FRONTEND_PID=$(cat .frontend.pid)
    echo "Stopping frontend server (PID: $FRONTEND_PID and related Parcel processes)..."
    # Attempt to kill by PID first (graceful then force)
    kill -15 $FRONTEND_PID 2>/dev/null
    sleep 1
    if ps -p $FRONTEND_PID > /dev/null; then
        echo "Frontend (PID $FRONTEND_PID) did not stop gracefully, forcing..."
        kill -9 $FRONTEND_PID 2>/dev/null
    fi
    # Also try to kill any lingering parcel processes by command name/pattern
    echo "Attempting to stop any lingering Parcel processes..."
    pkill -f "parcel index.html"
    sleep 1 # Give pkill a moment
    rm .frontend.pid
    echo "Frontend server stopped."
else
    echo "Frontend PID file not found. Maybe it wasn't running?"
fi

if [ -f .backend.pid ]; then
    BACKEND_PID=$(cat .backend.pid)
    echo "Stopping backend server (PID: $BACKEND_PID and related Node processes)..."
    # Attempt to kill by PID first (graceful then force)
    kill -15 $BACKEND_PID 2>/dev/null
    sleep 1
    if ps -p $BACKEND_PID > /dev/null; then
        echo "Backend (PID $BACKEND_PID) did not stop gracefully, forcing..."
        kill -9 $BACKEND_PID 2>/dev/null
    fi
    # Also try to kill any lingering node server processes by command name/pattern
    echo "Attempting to stop any lingering Node server processes..."
    pkill -f "node server.js"
    sleep 1 # Give pkill a moment
    rm .backend.pid
    echo "Backend server stopped."
# fi removed from here, the one after 'else' is correct
else
    echo "Backend PID file not found. Maybe it wasn't running?"
fi

echo "Servers stopped."