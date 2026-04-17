# Hermes Agent Docker Compose

Run [Hermes Agent](https://github.com/NousResearch/hermes-agent) in Docker in under 2 minutes.

## Quick Start

### 1. Create a directory and .env file
```bash
mkdir hermes && cd hermes
```

### 2. Create docker-compose.yaml
```yaml
# =============================================================================
# Hermes Agent Docker Compose Stack
# =============================================================================
# Usage:
#   docker compose -f /opt/hermes-docker/docker-compose.yaml up -d
#
# Environment:
#   Place a .env file in /opt/hermes-docker/ (or pass one via env_file)
#   Variables:
#     HERMES_DATA_DIR   - Host path for hermes data (default: ~/.hermes)
#     GATEWAY_PORT      - Host port for the gateway API (default: 8642)
#     DASHBOARD_PORT    - Host port for the dashboard UI (default: 9119)
# =============================================================================


services:
  # ---------------------------------------------------------------------------
  # Hermes Gateway — core agent runtime & API
  # ---------------------------------------------------------------------------
  gateway:
    image: nousresearch/hermes-agent:latest
    container_name: hermes-gateway
    command: gateway run
    restart: unless-stopped
    ports:
      - "${GATEWAY_PORT:-8642}:8642"
    volumes:
      - ${HERMES_DATA_DIR:-~/.hermes}:/opt/data
    shm_size: 1g
    networks:
      - hermes-net
    healthcheck:
      test: ["CMD-SHELL", "ss -tln | grep -q 8642 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  # ---------------------------------------------------------------------------
  # Hermes Dashboard — web UI for managing the agent
  # ---------------------------------------------------------------------------
  dashboard:
    image: nousresearch/hermes-agent:latest
    container_name: hermes-dashboard
    command: dashboard --host 0.0.0.0 --insecure
    restart: unless-stopped
    depends_on:
      - gateway
    ports:
      - "${DASHBOARD_PORT:-9119}:9119"
    environment:
      GATEWAY_HEALTH_URL: http://hermes-gateway:8642
    networks:
      - hermes-net

  # ---------------------------------------------------------------------------
  # Watchtower (opt-in) — auto-update hermes containers
  # ---------------------------------------------------------------------------
  # Uncomment the block below to enable automatic image updates via Watchtower.
  # It will watch every container on this compose project and pull new images
  # when available, then restart them seamlessly.
  #
  # watchtower:
  #   image: containrrr/watchtower:latest
  #   container_name: hermes-watchtower
  #   restart: unless-stopped
  #   command: --label-enable --cleanup
  #   volumes:
  #     - /var/run/docker.sock:/var/run/docker.sock
  #   networks:
  #     - hermes-net

networks:
  hermes-net:
    driver: bridge
```

### 3. Create .env with your API key
```bash
echo "NOUS_API_KEY=your-key-here" > .env
```

### 4. Run it
```bash
docker compose up -d
```

Done. Gateway at `http://localhost:8642`, Dashboard at `http://localhost:9119`.

## Setup Script (alternative)
```bash
git clone https://github.com/DeployFaith/hermes-docker-compose.git
cd hermes-docker-compose
bash setup.sh
```

## Configuration

### LLM Providers (pick one)
| Provider | Variable | Get a key |
|----------|----------|-----------|
| Nous Portal (recommended) | `NOUS_API_KEY` | [portal.nousresearch.com](https://portal.nousresearch.com/) |
| OpenRouter | `OPENROUTER_API_KEY` | [openrouter.ai/keys](https://openrouter.ai/keys) |
| OpenAI | `OPENAI_API_KEY` | [platform.openai.com](https://platform.openai.com) |
| OpenCode Go | `OPENCODE_GO_API_KEY` | [opencode.ai](https://opencode.ai) |

### Messaging (optional)
Set these in `.env` to connect a platform:

**Telegram:**
```
TELEGRAM_BOT_TOKEN=your-token
TELEGRAM_ALLOWED_USERS=your-user-id
```

**Discord:**
```
DISCORD_BOT_TOKEN=your-token
```

See `.env.example` for all options.

## Usage
```bash
docker compose up -d                        # start
docker compose logs -f gateway              # logs
docker compose run --rm gateway hermes      # interactive CLI
docker compose down                         # stop
docker compose pull && docker compose up -d # upgrade
```

## Data
Everything persists in the mounted directory (default: `~/.hermes`). Back it up.

## Resources
- Docs: [hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com)
- GitHub: [github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)
- Discord: [discord.gg/NousResearch](https://discord.gg/NousResearch)

## License
MIT
