#!/usr/bin/env bash
# =============================================================================
# Hermes Agent — First-Run Setup Script
# =============================================================================
# Interactive bootstrap for the Hermes Docker Compose stack.
# Usage:  bash /opt/hermes-docker/setup.sh
# =============================================================================
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
CYAN='\\033[0;36m'
BOLD='\\033[1m'
RESET='\\033[0m'

info()  { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()    { echo -e "${GREEN}[  OK]${RESET}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
err()   { echo -e "${RED}[ERR ]${RESET}  $*"; }
header(){ echo -e "\\n${BOLD}${CYAN}═══ $* ═══${RESET}\\n"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── 1. Prerequisites ─────────────────────────────────────────────────────────
header "Checking prerequisites"

# Docker
if ! command -v docker &>/dev/null; then
    err "Docker is not installed."
    echo -e "  Install it: ${CYAN}https://docs.docker.com/engine/install/${RESET}"
    echo -e "  Quick (Debian/Ubuntu):  curl -fsSL https://get.docker.com | sh"
    exit 1
fi
ok "Docker installed: $(docker --version)"

if ! docker info &>/dev/null 2>&1; then
    err "Docker daemon is not running (or you lack permissions)."
    echo -e "  Try: ${YELLOW}sudo systemctl start docker${RESET}"
    echo -e "  Or add your user to the docker group: ${YELLOW}sudo usermod -aG docker \\$USER${RESET}"
    exit 1
fi
ok "Docker daemon is running"

# Docker Compose (plugin)
if docker compose version &>/dev/null 2>&1; then
    ok "Docker Compose plugin: $(docker compose version --short 2>/dev/null || echo available)"
else
    err "Docker Compose plugin not found."
    echo -e "  Install: ${CYAN}https://docs.docker.com/compose/install/${RESET}"
    echo -e "  Or: ${YELLOW}sudo apt-get install docker-compose-plugin${RESET}"
    exit 1
fi

echo ""

# ── 2. Environment Setup ─────────────────────────────────────────────────────
header "Environment configuration"

if [[ -f .env ]]; then
    ok ".env already exists — skipping copy"
else
    if [[ ! -f .env.example ]]; then
        err ".env.example not found in $SCRIPT_DIR"
        exit 1
    fi
    cp .env.example .env
    ok "Created .env from .env.example"
fi

echo -e "\\n${BOLD}LLM Provider API Keys${RESET} (at least one required)"
echo -e "Press ${YELLOW}Enter${RESET} to skip any prompt.\\n"

# Nous Portal (recommended)
read -r -p "  Nous Portal API key (recommended, nous.ai): " NOUS_KEY
if [[ -n "$NOUS_KEY" ]]; then
    sed -i "s|^NOUS_API_KEY=.*|NOUS_API_KEY=$NOUS_KEY|" .env
    ok "Nous Portal key saved"
fi

# OpenRouter
read -r -p "  OpenRouter API key (openrouter.ai/keys): " OPENROUTER_KEY
if [[ -n "$OPENROUTER_KEY" ]]; then
    sed -i "s|^OPENROUTER_API_KEY=.*|OPENROUTER_API_KEY=$OPENROUTER_KEY|" .env
    ok "OpenRouter key saved"
fi

# Anthropic
read -r -p "  Anthropic API key (console.anthropic.com): " ANTHROPIC_KEY
if [[ -n "$ANTHROPIC_KEY" ]]; then
    sed -i "s|^ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=$ANTHROPIC_KEY|" .env
    ok "Anthropic key saved"
fi

# Google
read -r -p "  Google AI API key (aistudio.google.com/apikey): " GOOGLE_KEY
if [[ -n "$GOOGLE_KEY" ]]; then
    sed -i "s|^GOOGLE_API_KEY=.*|GOOGLE_API_KEY=$GOOGLE_KEY|" .env
    ok "Google AI key saved"
fi

# Ollama
read -r -p "  Ollama API key (local/remote, leave blank if using default): " OLLAMA_KEY
if [[ -n "$OLLAMA_KEY" ]]; then
    sed -i "s|^OLLAMA_API_KEY=.*|OLLAMA_API_KEY=$OLLAMA_KEY|" .env
    ok "Ollama key saved"
fi

# Validate at least one key was provided
HAS_KEY=false
for var in NOUS_KEY OPENROUTER_KEY ANTHROPIC_KEY GOOGLE_KEY OLLAMA_KEY; do
    if [[ -n "${!var:-}" ]]; then HAS_KEY=true; break; fi
done

# Also check if keys already existed in .env from a prior run
if ! $HAS_KEY; then
    for line in NOUS_API_KEY OPENROUTER_API_KEY ANTHROPIC_API_KEY GOOGLE_API_KEY OLLAMA_API_KEY; do
        val=$(grep -oP "^${line}=\\K.*" .env 2>/dev/null || true)
        if [[ -n "$val" && "$val" != "***" ]]; then HAS_KEY=true; break; fi
    done
fi

if ! $HAS_KEY; then
    echo ""
    warn "No LLM API key configured. The agent will not be able to respond to messages."
    warn "You can edit .env later and restart the stack."
    read -r -p "  Continue anyway? [y/N]: " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        info "Aborted. Edit .env and re-run this script."
        exit 0
    fi
fi

echo -e "\\n${BOLD}Messaging Platforms${RESET} (optional)"
echo -e "Press ${YELLOW}Enter${RESET} to skip.\\n"

read -r -p "  Telegram bot token (t.me/BotFather): " TG_TOKEN
if [[ -n "$TG_TOKEN" ]]; then
    sed -i "s|^TELEGRAM_BOT_TOKEN=.*|TELEGRAM_BOT_TOKEN=$TG_TOKEN|" .env
    ok "Telegram token saved"

    read -r -p "  Telegram allowed user IDs (comma-separated, or Enter to skip): " TG_USERS
    if [[ -n "$TG_USERS" ]]; then
        sed -i "s|^TELEGRAM_ALLOWED_USERS=.*|TELEGRAM_ALLOWED_USERS=$TG_USERS|" .env
    fi

    read -r -p "  Telegram home channel ID (e.g. -1001234567890, or Enter to skip): " TG_CHAN
    if [[ -n "$TG_CHAN" ]]; then
        sed -i "s|^TELEGRAM_HOME_CHANNEL=.*|TELEGRAM_HOME_CHANNEL=$TG_CHAN|" .env
    fi
fi

echo ""

# ── 3. Data Directory ────────────────────────────────────────────────────────
header "Data directory"

DATA_DIR=$(grep -oP '^HERMES_DATA_DIR=\\K.*' .env 2>/dev/null || true)
DATA_DIR=${DATA_DIR:-$HOME/.hermes}

mkdir -p "$DATA_DIR"
ok "Data directory ready: $DATA_DIR"

# ── 4. Pull and Start ────────────────────────────────────────────────────────
header "Pulling images"

docker compose pull

header "Starting services"

docker compose up -d

info "Waiting for containers to initialize…"
sleep 5

echo ""
docker compose ps

# Read ports for display
GATEWAY_PORT=$(grep -oP '^GATEWAY_PORT=\\K.*' .env 2>/dev/null || true)
DASHBOARD_PORT=$(grep -oP '^DASHBOARD_PORT=\\K.*' .env 2>/dev/null || true)
GATEWAY_PORT=${GATEWAY_PORT:-8642}
DASHBOARD_PORT=${DASHBOARD_PORT:-9119}

echo ""
header "Hermes is running!"
ok "Gateway API:    http://localhost:${GATEWAY_PORT}"
ok "Dashboard UI:   http://localhost:${DASHBOARD_PORT}"

# ── 5. Next Steps ────────────────────────────────────────────────────────────
header "Next steps"

cat <<NEXT
  View logs:
    ${CYAN}docker compose logs -f hermes-gateway${RESET}

  Use the CLI:
    ${CYAN}docker compose run --rm hermes-gateway hermes${RESET}

  Stop everything:
    ${CYAN}docker compose down${RESET}

  Edit configuration:
    ${CYAN}${SCRIPT_DIR}/.env${RESET}

  Documentation:
    ${CYAN}https://docs.nousresearch.com/hermes${RESET}
NEXT

echo ""
ok "Setup complete. Enjoy Hermes!"
