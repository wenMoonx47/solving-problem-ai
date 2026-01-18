#!/bin/bash
# ============================================
# SolveAssist AI - Prepare Offline Package
# ============================================
# MOVES (not copies) models to project folder to save disk space
# Creates a complete offline package ready to zip
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        SolveAssist AI - Offline Package Preparation          ║"
echo "║             Moving Models to Project Folder                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if Ollama models exist
if [ ! -d "/usr/share/ollama/.ollama/models" ]; then
    echo -e "${RED}✗ Ollama models directory not found!${NC}"
    echo -e "${YELLOW}Please run setup.sh first to download models${NC}"
    exit 1
fi

# Step 1: MOVE Ollama models to project
echo -e "${CYAN}Step 1: Moving Ollama models to project folder...${NC}"
MODEL_SOURCE="/usr/share/ollama/.ollama/models"
MODEL_DEST="./ollama_models"

# Check current size
MODEL_SIZE=$(du -sh "$MODEL_SOURCE" | cut -f1)
echo -e "  Models size: ${YELLOW}${MODEL_SIZE}${NC}"

# Move the models
sudo mv "$MODEL_SOURCE" "$MODEL_DEST"
sudo chown -R $(whoami):$(whoami) "$MODEL_DEST"

echo -e "${GREEN}✓ Models moved to: ${MODEL_DEST}${NC}"

# Step 2: Create symbolic link (so Ollama still works)
echo -e "\n${CYAN}Step 2: Creating symbolic link for Ollama...${NC}"
sudo mkdir -p /usr/share/ollama/.ollama
sudo ln -s "$SCRIPT_DIR/ollama_models" /usr/share/ollama/.ollama/models

echo -e "${GREEN}✓ Symbolic link created${NC}"

# Verify Ollama still works
if ollama list > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama can still access models${NC}"
else
    echo -e "${RED}✗ Ollama cannot access models, reverting...${NC}"
    sudo rm /usr/share/ollama/.ollama/models
    sudo mv "$MODEL_DEST" "$MODEL_SOURCE"
    exit 1
fi

# Step 3: Package structure check
echo -e "\n${CYAN}Step 3: Verifying package structure...${NC}"

REQUIRED_DIRS="backend frontend models tessdata ollama_models venv"
for dir in $REQUIRED_DIRS; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}  ✓ $dir${NC}"
    else
        echo -e "${RED}  ✗ $dir (missing)${NC}"
    fi
done

# Step 4: Show package size
echo -e "\n${CYAN}Step 4: Package size estimation...${NC}"
echo "  backend/        $(du -sh backend | cut -f1)"
echo "  frontend/       $(du -sh frontend | cut -f1)"
echo "  venv/           $(du -sh venv | cut -f1)"
echo "  ollama_models/  $(du -sh ollama_models | cut -f1)"
echo "  tessdata/       $(du -sh tessdata | cut -f1)"
echo "  ────────────────────────────────"
TOTAL_SIZE=$(du -sh . | cut -f1)
echo -e "  ${YELLOW}TOTAL:          ${TOTAL_SIZE}${NC}"

# Step 5: Create installation instructions
cat > OFFLINE_INSTALLATION.txt << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║          SolveAssist AI - Offline Installation                ║
╚═══════════════════════════════════════════════════════════════╝

REQUIREMENTS:
- Ubuntu 22.04 LTS (or compatible)
- 16GB+ RAM
- 20GB+ disk space
- NO INTERNET REQUIRED

INSTALLATION STEPS:
─────────────────────────────────────────────────────────────────

Step 1: Extract the Package
────────────────────────────
unzip solveassist-ai-offline.zip
cd solve-assist-ai/

Step 2: Install System Dependencies
────────────────────────────────────
sudo apt update
sudo apt install -y python3.11 python3.11-venv tesseract-ocr

Step 3: Install Ollama
───────────────────────
# If offline, install from provided binary:
sudo dpkg -i ollama_offline.deb

# OR download if internet available:
curl -fsSL https://ollama.com/install.sh | sh

Step 4: Setup Ollama Models
────────────────────────────
sudo mkdir -p /usr/share/ollama/.ollama/
sudo ln -s $(pwd)/ollama_models /usr/share/ollama/.ollama/models

# Verify models
ollama list
# Should show: llava:7b, llama3.2:latest

Step 5: Start Services
───────────────────────
# Start Ollama
sudo systemctl start ollama

# Wait a moment
sleep 5

# Verify Ollama is running
ollama list

Step 6: Run Application
────────────────────────
./run.sh

# Or run in background:
nohup ./run.sh > app.log 2>&1 &

Step 7: Access Application
───────────────────────────
Open browser: http://localhost:5000

Or access from other computers on network:
http://<server-ip>:5000

TROUBLESHOOTING:
─────────────────────────────────────────────────────────────────

Problem: "Command not found: ollama"
Solution: Install Ollama (see Step 3)

Problem: "No models found"
Solution: Check symbolic link
  sudo ln -s $(pwd)/ollama_models /usr/share/ollama/.ollama/models

Problem: Port 5000 already in use
Solution: Edit backend/app.py line 257, change port to 5001

Problem: Slow response times
Solution: First request takes 1-2 minutes (models loading)
         Subsequent requests: 30-90 seconds

SUPPORT:
─────────────────────────────────────────────────────────────────
For issues, check:
1. app.log file for application logs
2. sudo systemctl status ollama
3. tail -f app.log

Contact: [Your Support Email]
EOF

echo -e "${GREEN}✓ Installation instructions created${NC}"

# Step 6: Summary
echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Offline Package Preparation Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Package Contents:${NC}"
echo -e "  • Application code (backend, frontend)"
echo -e "  • Python virtual environment with all dependencies"
echo -e "  • Ollama AI models (LLaVA 7B + Llama 3.2)"
echo -e "  • Tesseract OCR data"
echo -e "  • Installation instructions"
echo ""
echo -e "${YELLOW}Total Size: ${TOTAL_SIZE}${NC}"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo -e "  1. Test locally: ./run.sh"
echo -e "  2. Create zip: ./create-offline-zip.sh"
echo -e "  3. Send zip file to client"
echo ""

