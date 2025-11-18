#!/bin/bash

# Dimensio Visualization Server Launcher

echo "================================================================================"
echo "                    Dimensio Visualization Server"
echo "================================================================================"
echo ""

# Check if Flask is installed
if ! python -c "import flask" 2>/dev/null; then
    echo "⚠️  Flask not found. Installing dependencies..."
    pip install -r requirements.txt
    echo ""
fi

# Check if results directory exists
if [ ! -d "../examples/results" ]; then
    echo "⚠️  Warning: results directory not found!"
    echo "   Please run examples first:"
    echo "   cd ../examples && python quick_start.py"
    echo ""
fi

# Start the server
echo "🚀 Starting server..."
echo ""
python server.py
