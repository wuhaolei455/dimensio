#!/bin/bash

echo "======================================="
echo "Testing Dimensio API Connection"
echo "======================================="
echo ""

API_BASE="http://127.0.0.1:5000"

# Check if API server is running
echo "1. Checking if API server is running..."
if curl -s "${API_BASE}/" > /dev/null 2>&1; then
    echo "✓ API server is running"
else
    echo "✗ API server is NOT running"
    echo ""
    echo "Please start the API server first:"
    echo "  cd .."
    echo "  python -m api.server"
    exit 1
fi

echo ""
echo "2. Testing /api/experiments endpoint..."
EXPERIMENTS=$(curl -s "${API_BASE}/api/experiments")
echo "$EXPERIMENTS" | python3 -m json.tool 2>/dev/null || echo "$EXPERIMENTS"

echo ""
echo "3. Getting first experiment ID..."
FIRST_EXP=$(echo "$EXPERIMENTS" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['data'][0]['experiment_id'] if data.get('success') and data.get('data') else 'none')" 2>/dev/null)

if [ "$FIRST_EXP" != "none" ] && [ -n "$FIRST_EXP" ]; then
    echo "✓ Found experiment: $FIRST_EXP"

    echo ""
    echo "4. Testing /api/experiments/${FIRST_EXP}/history endpoint..."
    HISTORY=$(curl -s "${API_BASE}/api/experiments/${FIRST_EXP}/history")
    echo "$HISTORY" | python3 -m json.tool 2>/dev/null | head -50

    echo ""
    echo "5. Testing /api/experiments/${FIRST_EXP}/visualizations endpoint..."
    VISUALIZATIONS=$(curl -s "${API_BASE}/api/experiments/${FIRST_EXP}/visualizations")
    echo "$VISUALIZATIONS" | python3 -m json.tool 2>/dev/null
else
    echo "✗ No experiments found"
    echo ""
    echo "Please ensure you have run examples to generate compression history data"
fi

echo ""
echo "======================================="
echo "API Test Complete"
echo "======================================="
echo ""
echo "If all tests passed, you can now start the frontend:"
echo "  npm start"
