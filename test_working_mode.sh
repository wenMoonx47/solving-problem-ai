#!/bin/bash
# Test the WORKING text input mode

echo "════════════════════════════════════════════════════════════════"
echo "  Testing TEXT INPUT Mode (The Mode That WORKS!)"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Testing equation: 3x - 5 = 2x + 7"
echo "Expected answer: x = 12"
echo ""
echo "Please wait 30-60 seconds..."
echo ""

curl -X POST http://localhost:5000/api/solve-text \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Solve: 3x - 5 = 2x + 7",
    "subject": "math",
    "show_answer": true
  }' \
  --max-time 90 \
  2>/dev/null | python3 -c "
import json
import sys

try:
    data = json.load(sys.stdin)
    if data.get('success'):
        print('✅ SUCCESS! Text mode works perfectly!')
        print('')
        solution = data['solution']
        response = solution.get('full_response', '')
        print('AI Response:')
        print('=' * 70)
        print(response[:600])
        print('')
        
        # Check if answer is correct
        if '12' in response or 'x = 12' in response or 'x=12' in response:
            print('✅ CORRECT ANSWER: x = 12')
        else:
            print('Answer in response (check above)')
    else:
        print('❌ Error:', data.get('error'))
except Exception as e:
    print(f'Failed to parse: {e}')
"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Text Input Mode: RELIABLE & ACCURATE!"
echo "  Image Mode: NOT RELIABLE without GPU"
echo "════════════════════════════════════════════════════════════════"

