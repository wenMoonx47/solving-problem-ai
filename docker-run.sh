#!/bin/bash
# ============================================
# SolveAssist AI - Quick Docker Run
# ============================================
# Runs the container locally for testing
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

IMAGE_NAME="solveassist-ai"
CONTAINER_NAME="solveassist-ai"
PORT=3333

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              SolveAssist AI - Docker Run                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Stop existing container if running
if docker ps -q -f name=${CONTAINER_NAME} | grep -q .; then
    echo -e "${YELLOW}Stopping existing container...${NC}"
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
fi

# Run the container
echo -e "${CYAN}Starting SolveAssist AI container...${NC}"
docker run -d \
    --name ${CONTAINER_NAME} \
    -p ${PORT}:3333 \
    --restart unless-stopped \
    ${IMAGE_NAME}:latest

echo -e "${GREEN}✓ Container started!${NC}"
echo ""
echo -e "${YELLOW}Waiting for services to initialize (30 seconds)...${NC}"
sleep 30

# Check health
if curl -s http://localhost:${PORT}/api/health | grep -q "healthy"; then
    echo -e "${GREEN}✓ Health check passed!${NC}"
else
    echo -e "${YELLOW}! Services still initializing, please wait...${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "SolveAssist AI is running!"
echo -e "Open browser: ${CYAN}http://localhost:${PORT}${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Useful commands:"
echo -e "  View logs: ${CYAN}docker logs -f ${CONTAINER_NAME}${NC}"
echo -e "  Stop: ${CYAN}docker stop ${CONTAINER_NAME}${NC}"
echo -e "  Start: ${CYAN}docker start ${CONTAINER_NAME}${NC}"

