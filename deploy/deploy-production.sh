#!/bin/bash

###############################################################################
# Dimensio Production Deployment Script
# 用于生产环境服务器的部署
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Dimensio Production Deployment                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}⚠️  This script should be run with sudo for production deployment${NC}"
    echo -e "${YELLOW}Continuing without sudo... Some operations may fail.${NC}"
    echo ""
fi

# Load production environment variables
if [ -f "$SCRIPT_DIR/.env.production" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env.production" | xargs)
    echo -e "${GREEN}✓${NC} Loaded production environment configuration"
else
    echo -e "${YELLOW}⚠️  .env.production not found, using default configuration${NC}"
    # Set default production values
    export BACKEND_PORT=5000
    export FRONTEND_PORT=3000
    export NGINX_PORT=80
    export ENV=production
    export USE_DOCKER_MIRROR=true
fi

# Check Docker
echo ""
echo -e "${BLUE}[1/7] Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo -e "${YELLOW}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com | bash
fi
echo -e "${GREEN}✓${NC} Docker is installed: $(docker --version)"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker Compose is available"

# Configure Docker registry mirror if needed
if [ "${USE_DOCKER_MIRROR}" = "true" ]; then
    echo ""
    echo -e "${BLUE}[2/7] Configuring Docker registry mirror...${NC}"
    if [ -f "$SCRIPT_DIR/fix-docker-registry.sh" ]; then
        bash "$SCRIPT_DIR/fix-docker-registry.sh"
    else
        echo -e "${YELLOW}⚠️  fix-docker-registry.sh not found, skipping mirror configuration${NC}"
    fi
fi

# Check and free ports
echo ""
echo -e "${BLUE}[3/7] Checking port availability...${NC}"
if [ -f "$SCRIPT_DIR/free-ports.sh" ]; then
    bash "$SCRIPT_DIR/free-ports.sh"
else
    echo -e "${YELLOW}⚠️  free-ports.sh not found, skipping port check${NC}"
fi

# Create necessary directories
echo ""
echo -e "${BLUE}[4/7] Creating directories...${NC}"
mkdir -p "$PROJECT_ROOT/data"
mkdir -p "$PROJECT_ROOT/result"
mkdir -p "$PROJECT_ROOT/logs"
echo -e "${GREEN}✓${NC} Directories created"

# Stop existing containers
echo ""
echo -e "${BLUE}[5/7] Stopping existing containers...${NC}"
cd "$SCRIPT_DIR/docker"
docker-compose -f docker-compose.production.yml down 2>/dev/null || true
echo -e "${GREEN}✓${NC} Existing containers stopped"

# Build and start containers
echo ""
echo -e "${BLUE}[6/7] Building and starting services...${NC}"
echo -e "${YELLOW}This may take several minutes...${NC}"

docker-compose -f docker-compose.production.yml up -d --build

# Wait for services to be ready
echo ""
echo -e "${BLUE}[7/7] Waiting for services to be ready...${NC}"
sleep 10

# Check service health
echo ""
echo -e "${BLUE}Checking service health...${NC}"

MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -sf http://localhost:${BACKEND_PORT:-5000}/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Backend is running"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo -e "${YELLOW}⚠️  Backend is not responding. Check logs with: docker-compose logs backend${NC}"
    else
        sleep 2
    fi
done

if curl -sf http://localhost:${NGINX_PORT:-80}/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Nginx is running"
else
    echo -e "${YELLOW}⚠️  Nginx is not responding. Check logs with: docker-compose logs nginx${NC}"
fi

# Print success message
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Deployment Successful! 🎉                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Production URLs:${NC}"
echo -e "  • Frontend:  ${GREEN}http://${SERVER_IP:-localhost}${NC}"
echo -e "  • Backend:   ${GREEN}http://${SERVER_IP:-localhost}:${BACKEND_PORT:-5000}${NC}"
echo -e "  • API:       ${GREEN}http://${SERVER_IP:-localhost}/api${NC}"
echo ""
echo -e "${BLUE}Container Status:${NC}"
docker-compose -f docker-compose.production.yml ps
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo -e "  • View logs:        ${YELLOW}docker-compose -f docker-compose.production.yml logs -f${NC}"
echo -e "  • Stop services:    ${YELLOW}docker-compose -f docker-compose.production.yml down${NC}"
echo -e "  • Restart services: ${YELLOW}docker-compose -f docker-compose.production.yml restart${NC}"
echo -e "  • View status:      ${YELLOW}docker-compose -f docker-compose.production.yml ps${NC}"
echo ""
