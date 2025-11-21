#!/bin/bash

# Dimensio Quick Start Script
# Provides multiple fast startup options for development

set -e

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DEPLOY_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print banner
echo ""
echo "========================================"
echo "  🚀 Dimensio Quick Start"
echo "========================================"
echo ""

# Function to show usage
show_usage() {
    echo "Usage: ./quick-start.sh [MODE]"
    echo ""
    echo "Available modes:"
    echo ""
    echo "  ${CYAN}local${NC}      - Start with local Python & Node.js (fastest, default)"
    echo "               No Docker required, instant startup"
    echo ""
    echo "  ${CYAN}docker-dev${NC} - Start with Docker in dev mode (fast)"
    echo "               Mount source code, no rebuild needed"
    echo ""
    echo "  ${CYAN}docker${NC}     - Start with Docker production mode (slow)"
    echo "               Full rebuild, suitable for production testing"
    echo ""
    echo "  ${CYAN}cached${NC}     - Use existing Docker images (very fast)"
    echo "               Skip build, start containers directly"
    echo ""
    echo "Examples:"
    echo "  ./quick-start.sh local       # Local development (instant)"
    echo "  ./quick-start.sh docker-dev  # Docker dev mode (fast)"
    echo "  ./quick-start.sh cached      # Use cached images (very fast)"
    echo ""
}

# Check if help is requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Default mode
MODE="${1:-local}"

# === Mode 1: Local Development (Fastest) ===
start_local() {
    echo -e "${GREEN}Starting in LOCAL mode (fastest)${NC}"
    echo "This uses your local Python and Node.js environment"
    echo ""

    if [ -f "$PROJECT_ROOT/start-all.sh" ]; then
        cd "$PROJECT_ROOT"
        bash start-all.sh
    else
        echo -e "${RED}Error: start-all.sh not found${NC}"
        exit 1
    fi
}

# === Mode 2: Docker Dev Mode (Fast) ===
start_docker_dev() {
    echo -e "${GREEN}Starting in DOCKER-DEV mode (fast)${NC}"
    echo "This mounts your source code, no rebuild needed"
    echo ""

    # Create docker-compose.dev.yml if not exists
    DEV_COMPOSE="$DEPLOY_DIR/docker/docker-compose.dev.yml"

    if [ ! -f "$DEV_COMPOSE" ]; then
        echo -e "${YELLOW}Creating dev compose file...${NC}"
        cat > "$DEV_COMPOSE" << 'EOF'
version: '3.8'

services:
  # Backend with mounted source code
  backend:
    image: python:3.9-slim
    container_name: dimensio-backend-dev
    working_dir: /app
    command: bash -c "pip install --quiet -r requirements.txt -r api/requirements.txt && python api/server.py"
    ports:
      - "5000:5000"
    volumes:
      - ../..:/app
    environment:
      - FLASK_APP=api/server.py
      - PYTHONUNBUFFERED=1
      - FLASK_ENV=development
    networks:
      - dimensio-network

  # Frontend with mounted source code
  frontend:
    image: node:18-alpine
    container_name: dimensio-frontend-dev
    working_dir: /app
    command: sh -c "npm config set registry https://registry.npmmirror.com && npm install --quiet && npm run dev"
    ports:
      - "3000:3000"
    volumes:
      - ../../front:/app
    networks:
      - dimensio-network
    depends_on:
      - backend

networks:
  dimensio-network:
    driver: bridge
EOF
        echo -e "${GREEN}✓ Dev compose file created${NC}"
    fi

    cd "$DEPLOY_DIR/docker"
    echo -e "${BLUE}Starting containers...${NC}"
    docker-compose -f docker-compose.dev.yml up
}

# === Mode 3: Docker Production (Slow) ===
start_docker() {
    echo -e "${YELLOW}Starting in DOCKER PRODUCTION mode (slow)${NC}"
    echo "This will rebuild all images"
    echo ""

    read -p "This will take several minutes. Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi

    cd "$DEPLOY_DIR/docker"

    echo -e "${BLUE}Building images...${NC}"
    docker-compose build

    echo -e "${BLUE}Starting containers...${NC}"
    docker-compose up -d

    echo ""
    echo -e "${GREEN}✓ Services started${NC}"
    echo ""
    echo "Access the application at:"
    echo "  → Frontend: http://localhost:3000"
    echo "  → Backend:  http://localhost:5000"
    echo "  → Nginx:    http://localhost:80"
    echo ""
    echo "View logs: docker-compose logs -f"
    echo "Stop:      docker-compose down"
}

# === Mode 4: Cached (Very Fast) ===
start_cached() {
    echo -e "${GREEN}Starting in CACHED mode (very fast)${NC}"
    echo "Using existing Docker images"
    echo ""

    cd "$DEPLOY_DIR/docker"

    # Check if images exist
    if ! docker images | grep -q "dimensio"; then
        echo -e "${YELLOW}No cached images found. Building first...${NC}"
        docker-compose build
    fi

    echo -e "${BLUE}Starting containers...${NC}"
    docker-compose up -d

    echo ""
    echo -e "${GREEN}✓ Services started${NC}"
    echo ""
    echo "Access the application at:"
    echo "  → Frontend: http://localhost:3000"
    echo "  → Backend:  http://localhost:5000"
    echo "  → Nginx:    http://localhost:80"
    echo ""
    echo "View logs: docker-compose logs -f"
    echo "Stop:      docker-compose down"
}

# Main switch
case "$MODE" in
    local)
        start_local
        ;;
    docker-dev)
        start_docker_dev
        ;;
    docker)
        start_docker
        ;;
    cached)
        start_cached
        ;;
    *)
        echo -e "${RED}Error: Unknown mode '$MODE'${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac
