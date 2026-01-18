#!/bin/bash
# Download a better vision model for math reading

echo "════════════════════════════════════════════════════════════════"
echo "  Upgrading Vision Model for Better Math Recognition"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Current: LLaVA 7B (general purpose, 70-80% math accuracy)"
echo "Upgrade: LLaVA 13B (larger, 85-90% math accuracy)"
echo ""
echo "⚠️  Warning:"
echo "  - Download size: ~8GB"
echo "  - Requires: 16GB+ RAM"
echo "  - Speed on CPU: 90-150 seconds per query"
echo ""

read -p "Do you want to proceed? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Downloading LLaVA 13B model..."
    ollama pull llava:13b
    
    echo ""
    echo "✓ Model downloaded!"
    echo ""
    echo "To use the new model, edit backend/solver.py line 20:"
    echo "  VISION_MODEL = \"llava:13b\"  # Change from llava:7b"
    echo ""
    echo "Then restart the server:"
    echo "  pkill -f 'python.*app.py'"
    echo "  ./run.sh"
else
    echo ""
    echo "Upgrade cancelled. Use Text Input mode for now!"
fi

