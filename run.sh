#!/bin/bash

# ============================================
# SolveAssist AI - Run Script
# ============================================
# Starts the SolveAssist AI application
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                      SolveAssist AI                           ║"
echo "║         Instant problem-solving guidance for learning         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Virtual environment not found. Running setup first...${NC}"
    ./setup.sh
fi

# Activate virtual environment
source venv/bin/activate

# Start Ollama if not running
if ! pgrep -x "ollama" > /dev/null; then
    echo -e "${YELLOW}Starting Ollama AI service...${NC}"
    ollama serve > /dev/null 2>&1 &
    sleep 2
    echo -e "${GREEN}✓ Ollama service started${NC}"
else
    echo -e "${GREEN}✓ Ollama service already running${NC}"
fi

# Check if models are available
echo -e "${CYAN}Checking AI models...${NC}"
if ollama list | grep -q "llava"; then
    echo -e "${GREEN}✓ Vision model (LLaVA) available${NC}"
else
    echo -e "${YELLOW}! Vision model not found. Pulling llava:7b...${NC}"
    ollama pull llava:7b
fi

if ollama list | grep -q "llama3"; then
    echo -e "${GREEN}✓ Text model (Llama 3.2) available${NC}"
else
    echo -e "${YELLOW}! Text model not found. Pulling llama3.2...${NC}"
    ollama pull llama3.2:latest
fi

# Start the Flask application
echo -e "\n${GREEN}Starting SolveAssist AI...${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  Open your browser and go to: ${GREEN}http://localhost:5000${NC}"
echo -e "  Press ${YELLOW}Ctrl+C${NC} to stop the server"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"

cd backend
python app.py

