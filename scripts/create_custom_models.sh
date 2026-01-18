#!/bin/bash

# ============================================
# SolveAssist AI - Custom Model Creator
# ============================================
# Creates optimized Ollama models for problem solving
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="$PROJECT_DIR/models"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           SolveAssist AI - Custom Model Creator               ║"
echo "║                                                               ║"
echo "║   Creates optimized models for problem solving                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if Ollama is running
if ! pgrep -x "ollama" > /dev/null; then
    echo -e "${YELLOW}Starting Ollama service...${NC}"
    ollama serve > /dev/null 2>&1 &
    sleep 3
fi

# Check base models are available
echo -e "${CYAN}Checking base models...${NC}"

if ! ollama list | grep -q "llama3.2"; then
    echo -e "${YELLOW}Downloading base text model (llama3.2)...${NC}"
    ollama pull llama3.2:latest
fi

if ! ollama list | grep -q "llava"; then
    echo -e "${YELLOW}Downloading base vision model (llava)...${NC}"
    ollama pull llava:7b
fi

echo -e "${GREEN}✓ Base models available${NC}"

# Create custom models
echo -e "\n${CYAN}Creating custom models...${NC}"

echo -e "\n${YELLOW}[1/3] Creating SolveAssist-Math model...${NC}"
cd "$MODELS_DIR"
if ollama create solveassist-math -f SolveAssist-Math.modelfile; then
    echo -e "${GREEN}✓ solveassist-math created${NC}"
else
    echo -e "${RED}✗ Failed to create solveassist-math${NC}"
fi

echo -e "\n${YELLOW}[2/3] Creating SolveAssist-Vision model...${NC}"
if ollama create solveassist-vision -f SolveAssist-Vision.modelfile; then
    echo -e "${GREEN}✓ solveassist-vision created${NC}"
else
    echo -e "${RED}✗ Failed to create solveassist-vision${NC}"
fi

echo -e "\n${YELLOW}[3/3] Creating SolveAssist-Physics model...${NC}"
if ollama create solveassist-physics -f SolveAssist-Physics.modelfile; then
    echo -e "${GREEN}✓ solveassist-physics created${NC}"
else
    echo -e "${RED}✗ Failed to create solveassist-physics${NC}"
fi

# List all models
echo -e "\n${CYAN}Available models:${NC}"
ollama list

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Custom models created successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}To use custom models, update backend/solver.py:${NC}"
echo -e "  VISION_MODEL = 'solveassist-vision'"
echo -e "  TEXT_MODEL = 'solveassist-math'"
echo -e "  MATH_MODEL = 'solveassist-math'"

echo -e "\n${CYAN}Or test directly:${NC}"
echo -e "  ollama run solveassist-math 'Solve: 2x + 5 = 13'"
echo ""

