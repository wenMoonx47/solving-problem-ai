#!/bin/bash
# ============================================
# Fix Ollama to Use GPU (Process Mode)
# ============================================
# For when Ollama runs as process, not systemd
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         Fix Ollama GPU (Process Mode)                         ║"
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

# Step 2: Stop any running Ollama processes
echo -e "\n${CYAN}Step 2: Stopping Ollama processes...${NC}"
pkill ollama || true
pkill -f "ollama serve" || true
sleep 3
echo -e "${GREEN}✓ Ollama processes stopped${NC}"

# Step 3: Set GPU environment variables
echo -e "\n${CYAN}Step 3: Configuring GPU environment...${NC}"

# Create a startup script with GPU enabled
cat > start-ollama-gpu.sh << 'EOF'
#!/bin/bash
# Start Ollama with GPU support

# Enable GPU
export CUDA_VISIBLE_DEVICES=0,1  # Use both RTX A4000 GPUs
export OLLAMA_MAX_LOADED_MODELS=2
export OLLAMA_NUM_PARALLEL=2
export OLLAMA_HOST=0.0.0.0:11434

# Start Ollama
echo "Starting Ollama with GPU support..."
ollama serve
EOF

chmod +x start-ollama-gpu.sh
echo -e "${GREEN}✓ GPU startup script created${NC}"

# Step 4: Start Ollama with GPU
echo -e "\n${CYAN}Step 4: Starting Ollama with GPU...${NC}"
nohup ./start-ollama-gpu.sh > ollama-gpu.log 2>&1 &
sleep 5

# Verify Ollama is running
if pgrep ollama > /dev/null; then
    echo -e "${GREEN}✓ Ollama started with GPU support${NC}"
else
    echo -e "${RED}✗ Ollama failed to start!${NC}"
    cat ollama-gpu.log
    exit 1
fi

# Step 5: Test GPU usage
echo -e "\n${CYAN}Step 5: Testing GPU usage...${NC}"
echo -e "${YELLOW}Running test query... (check nvidia-smi in another terminal)${NC}"

# Start a test query in background
(timeout 30 ollama run llama3.2 "What is 2+2? Answer in one word." > /dev/null 2>&1) &
TEST_PID=$!

sleep 8

# Check if GPU is being used
if nvidia-smi | grep -i ollama > /dev/null; then
    echo -e "${GREEN}✓ Ollama is using GPU!${NC}"
    echo -e "\nGPU processes:"
    nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv
else
    echo -e "${YELLOW}⚠️  GPU not detected yet${NC}"
    echo -e "  This is normal for quick queries"
    echo -e "  Try a longer request and watch: watch -n 1 nvidia-smi"
fi

# Wait for test to complete
wait $TEST_PID 2>/dev/null || true

# Step 6: Final instructions
echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Ollama GPU Configuration Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Ollama is now running with GPU support!${NC}"
echo ""
echo -e "To verify GPU usage:"
echo -e "  1. Run: ${YELLOW}watch -n 1 nvidia-smi${NC}"
echo -e "  2. Make a request to SolveAssist AI"
echo -e "  3. Watch GPU memory spike to 3-6 GB"
echo ""
echo -e "To restart Ollama with GPU:"
echo -e "  ${YELLOW}./start-ollama-gpu.sh${NC}"
echo ""
echo -e "To stop Ollama:"
echo -e "  ${YELLOW}pkill ollama${NC}"
echo ""

