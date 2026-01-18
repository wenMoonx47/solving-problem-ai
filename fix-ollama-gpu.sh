#!/bin/bash
# ============================================
# Fix Ollama to Use GPU
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║            Fix Ollama GPU Configuration                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Step 1: Check GPU
echo -e "${CYAN}Step 1: Checking GPU...${NC}"
if nvidia-smi > /dev/null 2>&1; then
    echo -e "${GREEN}✓ NVIDIA GPU detected${NC}"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
else
    echo -e "${RED}✗ No NVIDIA GPU found!${NC}"
    exit 1
fi

# Step 2: Stop Ollama
echo -e "\n${CYAN}Step 2: Stopping Ollama...${NC}"
sudo systemctl stop ollama
sleep 2
echo -e "${GREEN}✓ Ollama stopped${NC}"

# Step 3: Configure Ollama to use GPU
echo -e "\n${CYAN}Step 3: Configuring Ollama for GPU...${NC}"

# Create systemd override directory
sudo mkdir -p /etc/systemd/system/ollama.service.d/

# Create override file to enable GPU
sudo tee /etc/systemd/system/ollama.service.d/gpu.conf > /dev/null << EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_KEEP_ALIVE=24h"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="CUDA_VISIBLE_DEVICES=0,1"
EOF

echo -e "${GREEN}✓ GPU configuration created${NC}"

# Step 4: Reload systemd and restart Ollama
echo -e "\n${CYAN}Step 4: Restarting Ollama with GPU support...${NC}"
sudo systemctl daemon-reload
sudo systemctl start ollama
sleep 5

# Verify Ollama is running
if systemctl is-active --quiet ollama; then
    echo -e "${GREEN}✓ Ollama service started${NC}"
else
    echo -e "${RED}✗ Ollama failed to start!${NC}"
    sudo journalctl -u ollama -n 50
    exit 1
fi

# Step 5: Verify GPU usage
echo -e "\n${CYAN}Step 5: Testing GPU usage...${NC}"
echo -e "${YELLOW}Running a test query to verify GPU...${NC}"

# Run a small test
timeout 30 ollama run llama3.2 "What is 2+2? Answer in one word." > /dev/null 2>&1 &
sleep 10

# Check if GPU is being used
if nvidia-smi | grep -q "ollama"; then
    echo -e "${GREEN}✓ Ollama is using GPU!${NC}"
    nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader | grep ollama
else
    echo -e "${YELLOW}! GPU not showing usage yet (may need more time)${NC}"
    echo -e "  Run: watch -n 1 nvidia-smi"
    echo -e "  Then make a request and check GPU memory increase"
fi

# Step 6: Final verification
echo -e "\n${CYAN}Step 6: Checking model locations...${NC}"
ollama list

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Ollama GPU Configuration Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Verification:${NC}"
echo -e "  1. Run your SolveAssist app: ./run.sh"
echo -e "  2. Make a request"
echo -e "  3. Watch GPU usage: watch -n 1 nvidia-smi"
echo -e "  4. You should see GPU memory increase to 3-5 GB during inference"
echo ""
echo -e "${YELLOW}Expected GPU memory usage during inference:${NC}"
echo -e "  - llama3.2:latest: ~2-3 GB"
echo -e "  - llava:7b:        ~4-6 GB"
echo ""

