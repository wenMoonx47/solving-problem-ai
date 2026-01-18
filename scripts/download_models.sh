#!/bin/bash

# ============================================
# SolveAssist AI - Model Download Script
# ============================================
# Downloads all required AI models for offline use
# Run this ONCE while you have internet connection
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           SolveAssist AI - Model Downloader                   ║"
echo "║                                                               ║"
echo "║   This script downloads AI models for offline operation      ║"
echo "║   Run this ONCE while connected to the internet              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo -e "${RED}Error: Ollama is not installed.${NC}"
    echo -e "Please run ${YELLOW}./setup.sh${NC} first, or install Ollama manually:"
    echo -e "  curl -fsSL https://ollama.com/install.sh | sh"
    exit 1
fi

# Start Ollama if not running
if ! pgrep -x "ollama" > /dev/null; then
    echo -e "${YELLOW}Starting Ollama service...${NC}"
    ollama serve > /dev/null 2>&1 &
    sleep 3
fi

echo -e "\n${CYAN}Available model options:${NC}"
echo "1. Minimal (Text only)     - ~2GB   - Basic problem solving"
echo "2. Standard (Recommended)  - ~7GB   - Image + Text understanding"
echo "3. Full (Best quality)     - ~15GB  - Multiple model options"
echo ""

read -p "Choose option (1-3) [2]: " choice
choice=${choice:-2}

case $choice in
    1)
        echo -e "\n${CYAN}Downloading minimal models...${NC}"
        
        echo -e "\n${YELLOW}[1/1] Llama 3.2 (3B) - Text reasoning${NC}"
        ollama pull llama3.2:latest
        ;;
    
    2)
        echo -e "\n${CYAN}Downloading standard models (recommended)...${NC}"
        
        echo -e "\n${YELLOW}[1/2] Llama 3.2 (3B) - Text reasoning (~2GB)${NC}"
        ollama pull llama3.2:latest
        
        echo -e "\n${YELLOW}[2/2] LLaVA 7B - Vision + Language (~4.7GB)${NC}"
        ollama pull llava:7b
        ;;
    
    3)
        echo -e "\n${CYAN}Downloading full model suite...${NC}"
        
        echo -e "\n${YELLOW}[1/4] Llama 3.2 (3B) - Fast text reasoning (~2GB)${NC}"
        ollama pull llama3.2:latest
        
        echo -e "\n${YELLOW}[2/4] LLaVA 7B - Vision + Language (~4.7GB)${NC}"
        ollama pull llava:7b
        
        echo -e "\n${YELLOW}[3/4] LLaVA 13B - Better vision quality (~8GB)${NC}"
        ollama pull llava:13b
        
        echo -e "\n${YELLOW}[4/4] Mistral 7B - Alternative reasoning (~4GB)${NC}"
        ollama pull mistral:latest
        ;;
    
    *)
        echo -e "${RED}Invalid option. Exiting.${NC}"
        exit 1
        ;;
esac

# Show downloaded models
echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Download Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}Installed models:${NC}"
ollama list

echo -e "\n${CYAN}Model storage location:${NC}"
echo -e "  ~/.ollama/models/"

echo -e "\n${GREEN}You can now use SolveAssist AI completely offline!${NC}"
echo -e "Run ${YELLOW}./run.sh${NC} to start the application."
echo ""

