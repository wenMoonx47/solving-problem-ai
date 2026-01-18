#!/bin/bash
# ============================================
# SolveAssist AI - Docker Entrypoint
# ============================================
# This script starts both Ollama and Flask app
# ============================================

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                      SolveAssist AI                           ║"
echo "║            Docker Container - Offline Mode                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Step 1: Start Ollama service in background
echo -e "${YELLOW}Starting Ollama AI service...${NC}"
ollama serve &
OLLAMA_PID=$!
sleep 5

# Verify Ollama is running
if kill -0 $OLLAMA_PID 2>/dev/null; then
    echo -e "${GREEN}✓ Ollama service started (PID: $OLLAMA_PID)${NC}"
else
    echo -e "${RED}✗ Failed to start Ollama service${NC}"
    exit 1
fi

# Step 2: Check if models are available
echo -e "${CYAN}Checking AI models...${NC}"
if ollama list 2>/dev/null | grep -q "llava"; then
    echo -e "${GREEN}✓ Vision model (LLaVA) available${NC}"
else
    echo -e "${YELLOW}! Vision model not found in cache${NC}"
fi

if ollama list 2>/dev/null | grep -q "llama3"; then
    echo -e "${GREEN}✓ Text model (Llama 3.2) available${NC}"
else
    echo -e "${YELLOW}! Text model not found in cache${NC}"
fi

# Step 3: Activate virtual environment
source /app/venv/bin/activate

# Step 4: Start Flask application with Gunicorn
echo -e "\n${GREEN}Starting SolveAssist AI Web Server...${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  Web interface available at: ${GREEN}http://localhost:3333${NC}"
echo -e "  API health check: ${GREEN}http://localhost:3333/api/health${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"

cd /app/backend

# Use Gunicorn for production
exec gunicorn \
    --bind 0.0.0.0:3333 \
    --workers 2 \
    --timeout 300 \
    --keep-alive 5 \
    --access-logfile - \
    --error-logfile - \
    --capture-output \
    app:app

