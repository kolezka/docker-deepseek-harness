# docker-deepseek-harness

Run the [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) Web UI in a locked-down Docker container.

Upstream is a developer preview. Its own [safety notice](https://github.com/deepseek-ai/deepseek-harness/blob/master/SAFETY.md) says it is unaudited, runs model-generated commands, and should live in a disposable container or VM. This repo is that container. It is not affiliated with DeepSeek.

## What it does

- Runs `dsh web` as an unprivileged user (uid 10001), pinned to one npm version.
- Publishes the UI on the host's `127.0.0.1:3080` only. Nothing is reachable from the LAN.
- Read-only root filesystem, all capabilities dropped, `no-new-privileges`, pid and memory limits.
- The agent sees one host directory: `./workspace`.
- Settings, API keys and sessions live in the `dsh-home` volume.
- OpenTelemetry upload is off (`DSH_TELEMETRY_MODE=DISABLED`).

## Run

```sh
docker compose up -d --build
docker compose logs dsh   # prints http://<container-ip>:3080/?token=...
```

Open the printed URL with the host swapped for `127.0.0.1:3080`, keeping `?token=...`. The token is a login credential: anyone with it, or with access to `docker logs`, can use the UI.

On a remote server, tunnel the port instead of opening it:

```sh
ssh -N -L 3080:127.0.0.1:3080 user@server
```

Then open **Settings → Models** and add a DeepSeek API key. Use a key with a spending limit.

## Before you trust it

**Session logs go to DeepSeek by default.** The upstream base bundle sends your session log with requests to the official DeepSeek API. Turn it off in **Settings → General → Upload Session Log when using the official model API** if your workspace is private.

**The container can still reach your LAN.** dsh's `web_fetch` tool can call loopback and private-network hosts without asking. Docker does not stop that. On a Linux host, block private ranges for this container's bridge:

```sh
sudo ./scripts/block-lan.sh   # after `docker compose up`
```

The rules do not survive a reboot. Persist them with your distro's iptables or nftables service.

**Don't weaken the container.** Never mount `/var/run/docker.sock`, never add `privileged: true`, and don't mount your home directory. Each one hands the agent the host.

## Configuration

| Setting | Where | Default |
|---|---|---|
| dsh version | `DSH_VERSION` build arg in `Dockerfile` | `0.2.1-rc.2` |
| Bind address inside the container | `DSH_BIND_IP` env | first `hostname -i` address |
| Port | `DSH_PORT` env, plus the `ports` mapping | `3080` |
| Workspace | `./workspace` volume | empty |

Extra `dsh web` flags can go after the image name with `docker compose run`, or in a `command:` entry in `compose.yml`.

## Notes

- dsh refuses wildcard binds like `0.0.0.0`, so the entrypoint binds the container's own IP.
- dsh copies its native addons into a cache dir before loading them. Docker's tmpfs is `noexec` by default, which makes them fail with `failed to map segment from shared object`. The compose file gives that cache (`NARB_NATIVE_CACHE_DIR`) its own exec tmpfs and keeps `/tmp` noexec.
- dsh's own command sandbox (bwrap or Landlock) may not work inside Docker's default seccomp profile. That hasn't been tested here. The container is meant to be the boundary.

## Tested

Built and started on Docker Desktop (linux/arm64) with dsh 0.2.1-rc.2:

- the UI answers 401 without the token
- the token login returns 200 with the DeepSeek Harness page
- the LAN address refuses connections

Not yet tested:

- linux/amd64
- running an agent task
- the inner sandbox mode
- `scripts/block-lan.sh`

## License

MIT. DeepSeek Harness itself is MIT-licensed by DeepSeek-AI.
