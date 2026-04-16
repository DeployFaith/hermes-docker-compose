# Hermes Agent Docker Compose

One-command deployment of [Hermes Agent](https://github.com/NousResearch/hermes-agent) — the self-improving AI agent by Nous Research.

## What You Get
- **Gateway** — persistent agent runtime with Telegram, Discord, Slack, WhatsApp support
- **Dashboard** — web UI for managing the agent
- **Auto-updates** — optional Watchtower integration

## Prerequisites
- Docker Engine 20.10+
- Docker Compose v2+
- At least one LLM API key (Nous Portal recommended)

## Quick Start
```bash
git clone <repo-url> hermes-docker
cd hermes-docker
bash setup.sh
```
That's it. The setup script handles everything.

For the best experience, get your API key from [Nous Portal](https://nous.ai) — it's Nous Research's own inference API with access to frontier models.

## Manual Setup
```bash
cp .env.example .env
# Edit .env — add your API keys (NOUS_API_KEY recommended)
docker compose up -d
```

## Configuration
Edit `.env` to configure. At minimum, set one LLM key:

| Variable | Where to get it |
|----------|----------------|
| `NOUS_API_KEY` (recommended) | [nous.ai](https://nous.ai) |
| `OPENROUTER_API_KEY` | [openrouter.ai/keys](https://openrouter.ai/keys) |
| `ANTHROPIC_API_KEY` | [console.anthropic.com](https://console.anthropic.com) |
| `GOOGLE_API_KEY` | [aistudio.google.com](https://aistudio.google.com/apikey) |

Optional messaging platforms: Telegram, Discord, Slack (see `.env.example`).

## Usage

### Gateway (background service)
```bash
docker compose up -d
```
Gateway API: http://localhost:8642
Dashboard: http://localhost:9119

### Interactive CLI
```bash
docker compose run --rm gateway hermes
```

### View logs
```bash
docker compose logs -f gateway
```

### Stop
```bash
docker compose down
```

### Upgrade
```bash
docker compose pull
docker compose up -d
```

### Enable auto-updates (Watchtower)
Uncomment the `watchtower` service in `docker-compose.yaml`, then:
```bash
docker compose up -d
```

## Data Persistence
All agent data lives in the directory specified by `HERMES_DATA_DIR` (default: `~/.hermes`).
This includes conversations, memory, skills, and configuration. Back up this directory to preserve your agent's state.

## Troubleshooting

**Container exits immediately:** Check `docker compose logs gateway`. Usually a missing API key or port conflict.

**Permission denied:** `chmod -R 755 ~/.hermes`

**Browser tools fail:** Playwright needs shared memory. Already configured with `shm_size: 1g`.

**arm64 / Apple Silicon:** The published image is amd64 only. Build locally:
```bash
docker compose build
```

## Resources
- [Hermes Documentation](https://hermes-agent.nousresearch.com)
- [GitHub](https://github.com/NousResearch/hermes-agent)
- [Discord](https://discord.gg/NousResearch)

## License
MIT
