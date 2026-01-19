#!/bin/bash
# ============================================
# SolveAssist AI - Docker Build Script
# ============================================
# Builds the complete Docker image with all
# dependencies, models, and code for offline use
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
echo "║              SolveAssist AI - Docker Build                    ║"
echo "║           Building Complete Offline Image                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Configuration
IMAGE_NAME="solveassist-ai"
IMAGE_TAG="v1.0-offline"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo -e "${YELLOW}Building Docker image: ${FULL_IMAGE_NAME}${NC}"
echo -e "${YELLOW}This will take 15-30 minutes (downloading models ~10GB)${NC}"
echo ""

# Step 1: Build the Docker image
echo -e "${CYAN}Step 1: Building Docker image...${NC}"
docker build \
    --no-cache \
    -t "${FULL_IMAGE_NAME}" \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker image built successfully!${NC}"
else
    echo -e "${RED}✗ Docker build failed!${NC}"
    exit 1
fi

# Step 2: Show image size
echo -e "\n${CYAN}Step 2: Image Information${NC}"
docker images "${IMAGE_NAME}"

# Step 3: Provide next steps
echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "To ${CYAN}run locally${NC}:"
echo -e "  docker run -d -p 3333:3333 --name solveassist ${FULL_IMAGE_NAME}"
echo ""
echo -e "To ${CYAN}export for offline deployment${NC}:"
echo -e "  ./docker-export.sh"
echo ""
echo -e "To ${CYAN}test the container${NC}:"
echo -e "  docker run -d -p 3333:3333 --name solveassist-test ${FULL_IMAGE_NAME}"
echo -e "  curl http://localhost:3333/api/health"
echo ""

