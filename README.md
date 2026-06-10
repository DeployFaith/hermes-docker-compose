# Hermes Agent Docker Compose

Run [Hermes Agent](https://github.com/NousResearch/hermes-agent) in Docker. Setup wizard walks you through everything.

## Quick Start

```bash
git clone https://github.com/DeployFaith/hermes-docker-compose.git
cd hermes-docker-compose

docker compose up -d
docker compose exec gateway hermes setup
```

The setup wizard configures your LLM provider, messaging platforms, tools, and personality.

## Usage

```bash
docker compose up -d                        # start
docker compose exec gateway hermes setup    # first-time setup wizard
docker compose exec gateway hermes          # interactive CLI
docker compose logs -f gateway              # logs
docker compose down                         # stop
docker compose pull && docker compose up -d # upgrade
```

## Configuration

Copy `.env.example` to `.env` and edit as needed:

```bash
cp .env.example .env
```

| Variable | Default | Description |
|---|---|---|
| `HERMES_DATA_DIR` | `~/.hermes` | Host path for persistent data |
| `GATEWAY_PORT` | `8642` | Host port for the gateway API |
| `DASHBOARD_PORT` | `9120` | Host port for the dashboard UI |

## Data

Everything persists in `~/.hermes` on your host. Back it up.

## Auto-Updates

Uncomment the `watchtower` block in `docker-compose.yml` to enable automatic image updates.

## Resources

- Docs: [hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com)
- GitHub: [github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)
- Discord: [discord.gg/NousResearch](https://discord.gg/NousResearch)

## License

MIT
