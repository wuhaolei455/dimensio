#!/bin/bash

###############################################################################
# Dimensio Local Development Deployment Script
# 用于本地开发环境的快速部署
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
echo -e "${BLUE}║         Dimensio Local Development Deployment             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if .env.local exists, if not create from template
if [ ! -f "$SCRIPT_DIR/.env.local" ]; then
    echo -e "${YELLOW}⚠️  .env.local not found, using default configuration${NC}"
fi

# Load local environment variables
if [ -f "$SCRIPT_DIR/.env.local" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env.local" | xargs)
    echo -e "${GREEN}✓${NC} Loaded local environment configuration"
else
    # Set default local values
    export BACKEND_PORT=5001
    export FRONTEND_PORT=3001
    export NGINX_PORT=8080
    export ENV=local
fi

# Check Docker
echo ""
echo -e "${BLUE}[1/5] Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo -e "${YELLOW}Please install Docker Desktop from: https://www.docker.com/products/docker-desktop${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker is installed: $(docker --version)"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker Compose is available"

# Check if ports are available
echo ""
echo -e "${BLUE}[2/5] Checking port availability...${NC}"
check_port() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${YELLOW}⚠️  Port $port ($service) is in use${NC}"
        read -p "Stop the process using port $port? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            local pid=$(lsof -ti:$port)
            kill -9 $pid 2>/dev/null || true
            echo -e "${GREEN}✓${NC} Stopped process on port $port"
        else
            echo -e "${YELLOW}⚠️  Continuing with port conflict. Service may fail to start.${NC}"
        fi
    else
        echo -e "${GREEN}✓${NC} Port $port ($service) is available"
    fi
}

check_port ${BACKEND_PORT:-5001} "Backend"
check_port ${FRONTEND_PORT:-3001} "Frontend"
check_port ${NGINX_PORT:-8080} "Nginx"

# Create necessary directories
echo ""
echo -e "${BLUE}[3/5] Creating directories...${NC}"
mkdir -p "$PROJECT_ROOT/data"
mkdir -p "$PROJECT_ROOT/result"
mkdir -p "$PROJECT_ROOT/logs"
echo -e "${GREEN}✓${NC} Directories created"

# Stop existing containers
echo ""
echo -e "${BLUE}[4/5] Stopping existing containers...${NC}"
cd "$SCRIPT_DIR/docker"
docker-compose -f docker-compose.local.yml -p dimensio-local down 2>/dev/null || true
echo -e "${GREEN}✓${NC} Existing containers stopped"

# Build and start containers
echo ""
echo -e "${BLUE}[5/5] Building and starting services...${NC}"
echo -e "${YELLOW}This may take a few minutes...${NC}"

docker-compose -f docker-compose.local.yml -p dimensio-local up -d --build

# Wait for services to be ready
echo ""
echo -e "${BLUE}Waiting for services to be ready...${NC}"
sleep 5

# Check service health
echo ""
echo -e "${BLUE}Checking service health...${NC}"

# Check backend
if curl -sf http://localhost:${BACKEND_PORT:-5001}/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Backend is running"
else
    echo -e "${YELLOW}⚠️  Backend may still be starting...${NC}"
fi

# Check nginx
if curl -sf http://localhost:${NGINX_PORT:-8080}/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Nginx is running"
else
    echo -e "${YELLOW}⚠️  Nginx may still be starting...${NC}"
fi

# Print success message
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Deployment Successful! 🎉                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Local Development URLs:${NC}"
echo -e "  • Frontend:  ${GREEN}http://localhost:${NGINX_PORT:-8080}${NC}"
echo -e "  • Backend:   ${GREEN}http://localhost:${BACKEND_PORT:-5001}${NC}"
echo -e "  • API:       ${GREEN}http://localhost:${NGINX_PORT:-8080}/api${NC}"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo -e "  • View logs:        ${YELLOW}docker-compose -f docker-compose.local.yml logs -f${NC}"
echo -e "  • Stop services:    ${YELLOW}docker-compose -f docker-compose.local.yml down${NC}"
echo -e "  • Restart services: ${YELLOW}docker-compose -f docker-compose.local.yml restart${NC}"
echo -e "  • View status:      ${YELLOW}docker-compose -f docker-compose.local.yml ps${NC}"
echo ""
echo -e "${BLUE}Data Directories:${NC}"
echo -e "  • Data:    ${YELLOW}$PROJECT_ROOT/data${NC}"
echo -e "  • Results: ${YELLOW}$PROJECT_ROOT/result${NC}"
echo -e "  • Logs:    ${YELLOW}$PROJECT_ROOT/logs${NC}"
echo ""
