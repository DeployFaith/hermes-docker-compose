# Hermes Agent Docker Compose

Run [Hermes Agent](https://github.com/NousResearch/hermes-agent) in Docker. Setup wizard walks you through everything.

## Quick Start

```bash
mkdir hermes && cd hermes

# Create docker-compose.yaml (copy the block below)

docker compose up -d
docker compose exec gateway hermes setup
```

The setup wizard configures your LLM provider, messaging platforms, tools, and personality.

## docker-compose.yaml

```yaml
services:
  gateway:
    image: nousresearch/hermes-agent:latest
    container_name: hermes-gateway
    command: gateway run
    restart: unless-stopped
    ports:
      - "8642:8642"
    volumes:
      - ~/.hermes:/opt/data
    shm_size: 1g

  dashboard:
    image: nousresearch/hermes-agent:latest
    container_name: hermes-dashboard
    command: dashboard --host 0.0.0.0 --insecure
    restart: unless-stopped
    depends_on:
      - gateway
    ports:
      - "9119:9119"
    environment:
      GATEWAY_HEALTH_URL: http://hermes-gateway:8642

  # Uncomment for auto-updates:
  # watchtower:
  #   image: containrrr/watchtower:latest
  #   container_name: hermes-watchtower
  #   restart: unless-stopped
  #   command: --label-enable --cleanup
  #   volumes:
  #     - /var/run/docker.sock:/var/run/docker.sock
```

## Usage

```bash
docker compose up -d                        # start
docker compose exec gateway hermes setup    # first-time setup wizard
docker compose exec gateway hermes          # interactive CLI
docker compose logs -f gateway              # logs
docker compose down                         # stop
docker compose pull && docker compose up -d # upgrade
```

## Data

Everything persists in `~/.hermes` on your host. Back it up.

## Resources

- Docs: [hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com)
- GitHub: [github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)
- Discord: [discord.gg/NousResearch](https://discord.gg/NousResearch)

## License

MIT
