#!/bin/bash

# Docker Build Optimization Script
# Speeds up Docker builds by using build cache and layer optimization

set -e

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DEPLOY_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "========================================"
echo "  🔧 Docker Build Optimizer"
echo "========================================"
echo ""

# Function to show options
show_options() {
    echo "Select optimization strategy:"
    echo ""
    echo "  ${CYAN}1${NC}) Fast build (with cache, ~30s-1min)"
    echo "  ${CYAN}2${NC}) Incremental build (rebuild only changed layers)"
    echo "  ${CYAN}3${NC}) Use BuildKit (parallel builds, faster)"
    echo "  ${CYAN}4${NC}) Pull cached images from registry (if available)"
    echo "  ${CYAN}5${NC}) Clean cache and rebuild"
    echo ""
    read -p "Enter choice (1-5): " choice
    echo ""

    case $choice in
        1) fast_build ;;
        2) incremental_build ;;
        3) buildkit_build ;;
        4) pull_cached ;;
        5) clean_rebuild ;;
        *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
    esac
}

# Fast build with cache
fast_build() {
    echo -e "${GREEN}Fast build with cache${NC}"
    cd "$DEPLOY_DIR/docker"

    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1

    echo -e "${BLUE}Building with cache...${NC}"
    time docker-compose build --parallel

    echo ""
    echo -e "${GREEN}✓ Build completed${NC}"
    echo "Start with: cd $DEPLOY_DIR && ./quick-start.sh cached"
}

# Incremental build
incremental_build() {
    echo -e "${GREEN}Incremental build${NC}"
    echo "Only rebuilding services with changes..."

    cd "$DEPLOY_DIR/docker"

    # Check which files changed
    echo -e "${BLUE}Checking for changes...${NC}"

    BACKEND_CHANGED=false
    FRONTEND_CHANGED=false

    # Check if we should rebuild backend
    if git diff HEAD~1 --name-only 2>/dev/null | grep -qE "(api/|requirements.txt|Dockerfile.backend)"; then
        BACKEND_CHANGED=true
    fi

    # Check if we should rebuild frontend
    if git diff HEAD~1 --name-only 2>/dev/null | grep -qE "(front/|Dockerfile.frontend)"; then
        FRONTEND_CHANGED=true
    fi

    if [ "$BACKEND_CHANGED" = true ]; then
        echo -e "${YELLOW}Rebuilding backend...${NC}"
        docker-compose build backend
    else
        echo -e "${CYAN}Backend unchanged, using cache${NC}"
    fi

    if [ "$FRONTEND_CHANGED" = true ]; then
        echo -e "${YELLOW}Rebuilding frontend...${NC}"
        docker-compose build frontend
    else
        echo -e "${CYAN}Frontend unchanged, using cache${NC}"
    fi

    echo ""
    echo -e "${GREEN}✓ Incremental build completed${NC}"
}

# BuildKit parallel build
buildkit_build() {
    echo -e "${GREEN}BuildKit parallel build${NC}"
    echo "Using BuildKit for faster parallel builds"

    cd "$DEPLOY_DIR/docker"

    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1

    echo -e "${BLUE}Building with BuildKit...${NC}"
    time docker-compose build \
        --parallel \
        --progress=plain \
        backend frontend

    echo ""
    echo -e "${GREEN}✓ BuildKit build completed${NC}"
}

# Pull cached images
pull_cached() {
    echo -e "${GREEN}Pull cached images${NC}"
    echo "This works if you have pre-built images in a registry"

    cd "$DEPLOY_DIR/docker"

    # Try to pull images
    echo -e "${BLUE}Pulling base images...${NC}"
    docker pull python:3.9-slim 2>/dev/null || true
    docker pull node:18-alpine 2>/dev/null || true
    docker pull nginx:alpine 2>/dev/null || true

    echo -e "${BLUE}Building with pulled cache...${NC}"
    docker-compose build --pull

    echo ""
    echo -e "${GREEN}✓ Cached build completed${NC}"
}

# Clean rebuild
clean_rebuild() {
    echo -e "${YELLOW}Clean rebuild (this will be slow)${NC}"
    read -p "Are you sure? This removes all cache. (y/N) " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi

    cd "$DEPLOY_DIR/docker"

    echo -e "${BLUE}Removing old images...${NC}"
    docker-compose down --rmi local 2>/dev/null || true

    echo -e "${BLUE}Building from scratch...${NC}"
    time docker-compose build --no-cache --pull

    echo ""
    echo -e "${GREEN}✓ Clean build completed${NC}"
}

# Show build stats
show_stats() {
    echo ""
    echo "========================================"
    echo "  📊 Build Statistics"
    echo "========================================"
    echo ""

    cd "$DEPLOY_DIR/docker"

    echo "Images:"
    docker-compose images

    echo ""
    echo "Disk usage:"
    docker system df
}

# Main menu
if [ -z "$1" ]; then
    show_options
else
    case "$1" in
        fast) fast_build ;;
        incremental) incremental_build ;;
        buildkit) buildkit_build ;;
        pull) pull_cached ;;
        clean) clean_rebuild ;;
        stats) show_stats ;;
        *)
            echo "Usage: $0 [fast|incremental|buildkit|pull|clean|stats]"
            exit 1
            ;;
    esac
fi

# Show stats at the end
show_stats
