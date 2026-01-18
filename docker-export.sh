#!/bin/bash
# ============================================
# SolveAssist AI - Docker Export Script
# ============================================
# Exports the Docker image as a single .tar file
# for offline deployment to clients
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
echo "║              SolveAssist AI - Docker Export                   ║"
echo "║           Creating Offline Distribution Package               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Configuration
IMAGE_NAME="solveassist-ai"
IMAGE_TAG="v1.0-offline"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
DATE_STAMP=$(date +%Y%m%d)
OUTPUT_DIR="./docker-export"
TAR_FILE="${OUTPUT_DIR}/${IMAGE_NAME}_${IMAGE_TAG}_${DATE_STAMP}.tar"
COMPRESSED_FILE="${TAR_FILE}.gz"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Check if image exists
if ! docker image inspect "${FULL_IMAGE_NAME}" > /dev/null 2>&1; then
    echo -e "${RED}✗ Image ${FULL_IMAGE_NAME} not found!${NC}"
    echo -e "${YELLOW}Please run ./docker-build.sh first${NC}"
    exit 1
fi

# Step 1: Export Docker image
echo -e "${CYAN}Step 1: Exporting Docker image to tar file...${NC}"
echo -e "${YELLOW}This may take 5-10 minutes depending on image size${NC}"

docker save -o "${TAR_FILE}" "${FULL_IMAGE_NAME}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker image exported to ${TAR_FILE}${NC}"
else
    echo -e "${RED}✗ Failed to export Docker image!${NC}"
    exit 1
fi

# Step 2: Compress the tar file
echo -e "\n${CYAN}Step 2: Compressing...${NC}"
gzip -f "${TAR_FILE}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Compressed to ${COMPRESSED_FILE}${NC}"
else
    echo -e "${RED}✗ Failed to compress!${NC}"
    exit 1
fi

# Step 3: Create deployment instructions
INSTRUCTIONS_FILE="${OUTPUT_DIR}/DEPLOYMENT_INSTRUCTIONS.txt"
cat > "${INSTRUCTIONS_FILE}" << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║            SolveAssist AI - Deployment Instructions           ║
╚═══════════════════════════════════════════════════════════════╝

REQUIREMENTS:
- Docker installed on target machine
- At least 16GB RAM
- 20GB disk space

STEP 1: Load the Docker Image
─────────────────────────────
gunzip -k solveassist-ai_*.tar.gz
docker load -i solveassist-ai_*.tar

STEP 2: Run the Container
─────────────────────────────
docker run -d \
    --name solveassist-ai \
    -p 3333:3333 \
    --restart unless-stopped \
    solveassist-ai:v1.0-offline

STEP 3: Verify Installation
─────────────────────────────
# Wait 60 seconds for models to initialize
sleep 60

# Check health
curl http://localhost:3333/api/health

# Open in browser
http://localhost:3333

STEP 4: Management Commands
─────────────────────────────
# View logs
docker logs -f solveassist-ai

# Stop container
docker stop solveassist-ai

# Start container
docker start solveassist-ai

# Remove container
docker rm -f solveassist-ai

# Remove image (to free space)
docker rmi solveassist-ai:v1.0-offline

TROUBLESHOOTING:
─────────────────────────────
1. If container fails to start:
   docker logs solveassist-ai

2. If port 3333 is in use:
   docker run -d -p 3334:3333 --name solveassist-ai solveassist-ai:v1.0-offline

3. Memory issues:
   Ensure at least 16GB RAM available
   docker run -d -p 3333:3333 --memory=12g solveassist-ai:v1.0-offline

SUPPORT:
─────────────────────────────
Contact: [Your Support Email]
EOF

echo -e "${GREEN}✓ Deployment instructions created${NC}"

# Step 4: Show summary
echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Export Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Export Directory: ${CYAN}${OUTPUT_DIR}${NC}"
echo ""
ls -lh "${OUTPUT_DIR}"
echo ""
echo -e "Files to send to client:"
echo -e "  1. ${CYAN}${COMPRESSED_FILE}${NC}"
echo -e "  2. ${CYAN}${INSTRUCTIONS_FILE}${NC}"
echo ""
echo -e "Total size: $(du -sh ${OUTPUT_DIR} | cut -f1)"
echo ""
echo -e "${YELLOW}NOTE: Image is approximately 8-12 GB (includes AI models)${NC}"

