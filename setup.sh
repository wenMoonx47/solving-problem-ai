#!/bin/bash

# ============================================
# SolveAssist AI - Offline Setup Script
# ============================================
# This script sets up everything needed to run
# SolveAssist AI completely offline.
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                      SolveAssist AI                           ║"
echo "║         Instant problem-solving guidance for learning         ║"
echo "║                                                               ║"
echo "║                    OFFLINE SETUP SCRIPT                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if running with sudo when needed
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Some operations may require sudo access.${NC}"
    fi
}

# Step 1: Check Python installation
echo -e "\n${BLUE}[1/6] Checking Python installation...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓ $PYTHON_VERSION found${NC}"
else
    echo -e "${RED}✗ Python 3 not found. Please install Python 3.9 or higher.${NC}"
    exit 1
fi

# Step 2: Create virtual environment
echo -e "\n${BLUE}[2/6] Setting up Python virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${GREEN}✓ Virtual environment already exists${NC}"
fi

# Activate virtual environment
source venv/bin/activate

# Step 3: Install Python dependencies
echo -e "\n${BLUE}[3/6] Installing Python dependencies...${NC}"
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt
echo -e "${GREEN}✓ Python dependencies installed${NC}"

# Step 4: Check/Install Tesseract OCR
echo -e "\n${BLUE}[4/6] Checking Tesseract OCR...${NC}"
if command -v tesseract &> /dev/null; then
    TESSERACT_VERSION=$(tesseract --version 2>&1 | head -n1)
    echo -e "${GREEN}✓ $TESSERACT_VERSION found${NC}"
else
    echo -e "${YELLOW}! Tesseract not found. Attempting to install...${NC}"
    
    # Detect package manager and install
    if command -v apt-get &> /dev/null; then
        echo "Using apt-get..."
        sudo apt-get update && sudo apt-get install -y tesseract-ocr tesseract-ocr-eng
    elif command -v dnf &> /dev/null; then
        echo "Using dnf..."
        sudo dnf install -y tesseract tesseract-langpack-eng
    elif command -v pacman &> /dev/null; then
        echo "Using pacman..."
        sudo pacman -S --noconfirm tesseract tesseract-data-eng
    else
        echo -e "${RED}✗ Could not detect package manager. Please install Tesseract manually:${NC}"
        echo "  Ubuntu/Debian: sudo apt-get install tesseract-ocr"
        echo "  Fedora: sudo dnf install tesseract"
        echo "  Arch: sudo pacman -S tesseract"
    fi
    
    if command -v tesseract &> /dev/null; then
        echo -e "${GREEN}✓ Tesseract installed successfully${NC}"
    fi
fi

# Step 5: Check/Install Ollama
echo -e "\n${BLUE}[5/6] Checking Ollama (Local AI runtime)...${NC}"
if command -v ollama &> /dev/null; then
    echo -e "${GREEN}✓ Ollama is installed${NC}"
else
    echo -e "${YELLOW}! Ollama not found. Installing...${NC}"
    
    # Download and install Ollama
    curl -fsSL https://ollama.com/install.sh | sh
    
    if command -v ollama &> /dev/null; then
        echo -e "${GREEN}✓ Ollama installed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to install Ollama. Please install manually from https://ollama.com${NC}"
    fi
fi

# Step 6: Download AI Models
echo -e "\n${BLUE}[6/6] Downloading AI models for offline use...${NC}"
echo -e "${YELLOW}Note: This requires internet connection. Models will be stored locally.${NC}"
echo -e "${YELLOW}After this step, the app works completely offline.${NC}\n"

# Start Ollama service if not running
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama service..."
    ollama serve &
    sleep 3
fi

# Download models
echo -e "\n${CYAN}Downloading LLaVA (Vision-Language Model) - ~4.7GB${NC}"
echo "This model can understand images and explain visual problems..."
ollama pull llava:7b

echo -e "\n${CYAN}Downloading Llama 3.2 (Text Reasoning) - ~2GB${NC}"
echo "This model provides step-by-step reasoning and explanations..."
ollama pull llama3.2:latest

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}To start SolveAssist AI:${NC}"
echo -e "  1. Run: ${YELLOW}./run.sh${NC}"
echo -e "  2. Open: ${YELLOW}http://localhost:5000${NC} in your browser"
echo -e "\n${CYAN}The app now works completely offline!${NC}"
echo ""

