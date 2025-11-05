# Nginx Static File Server

A lightweight NGINX container that serves a single host directory at the root of your domain. Optimised for Coolify deployments, but works equally well with plain Docker Compose.

## Features

- **Domain Agnostic**: Works with any domain when deployed in Coolify
- **Traefik Ready**: Point any domain or path to the container
- **Simple Caching**: Browser caching handled by your assets; Nginx just serves bytes fast
- **Health Endpoint**: `/healthz` returns `ok` for orchestrator checks
- **Performance**: Tuned Nginx defaults for static file serving
- **Docker Support**: Containerized deployment ready

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and modify as needed:

```bash
# Host port mapping (optional – defaults to 80 for local dev)
HOST_PORT=80

# Host path that will be mounted read-only under /srv/public
HOST_PUBLIC_PATH=./public

# Nginx config path (optional – defaults to ./nginx)
NGINX_CONFIG_PATH=./nginx
```

For Coolify deployments, use absolute paths, for example:

```bash
HOST_PUBLIC_PATH=/data/storage
NGINX_CONFIG_PATH=/data/nginx-static
```

## High-level Design

- **Coolify (Traefik) = TLS + routing**
  Point `storage.your-domain.com` (or any host/path) at this container.

- **Nginx container = static origin**
  Serves every file from a single host-mounted directory without rewriting paths.

## File/volume Layout (Host)

```
/data/storage/                  # directory you want to expose publicly
  index.html
  images/
  files/

# Optional Nginx config files (host-mounted)
/data/nginx-static/conf.d/site.conf
```

- **Writers/Deploy scripts** copy files into `/data/storage`
- **Nginx** mounts: `/data/storage -> /srv/public:ro`
- **Healthcheck**: `/healthz` returns `ok`

## Deployment in Coolify

### 1. Add Docker Container

In Coolify, add a **Docker Container** (not an app proxy) with:

- **Image:** `nginx:alpine`
- **Ports:** **none** (Traefik will route internally)
- **Volumes:**
  - `/data/storage` → `/srv/public:ro`
  - `/data/nginx-static/conf.d/site.conf` → `/etc/nginx/conf.d/default.conf:ro`
- **Networks:** attach it to the same network as Coolify's reverse proxy

### 2. Traefik Labels

Add labels in Coolify so Traefik routes the host to the container:

```yaml
traefik.enable=true
traefik.http.routers.storage.rule=Host(`storage.your-domain.com`)
traefik.http.routers.uploads.entrypoints=websecure
traefik.http.routers.uploads.tls=true
traefik.http.services.storage.loadbalancer.server.port=80
```

### 3. Writers / Build Pipelines

Copy files into `/data/storage` (or whatever path you mount) using your deployment pipeline or CI/CD job. The container serves them as-is.

### Notes for Coolify Deployments

- Coolify disallows variable substitution in bind-mount definitions. Provide absolute paths (e.g. `/data/storage:/srv/public:ro`).
- Traefik handles TLS/hostnames, so you do **not** need to expose ports on the container. The compose file maps `80:80` purely for local testing—omit this in Coolify if Traefik routes internally.

## Local Docker Compose Usage

For quick local tests:

1. Create the folders the compose file expects:
   ```bash
   mkdir -p public nginx/conf.d
   ```
   (The repo already contains `nginx/conf.d/site.conf`; ensure `public/` exists.)
2. Run `docker compose up --build`.
3. Verify `http://localhost:80/healthz` returns `ok`, then drop a test file into `public/` and load `http://localhost:80/your-file.ext`.

Adjust the port mapping in `docker-compose.yml` if `80` conflicts with something else on your dev machine.

## Why This Works for Any Domain

Traefik (or any reverse proxy) can point an entire host to this container. Because Nginx serves files directly from `/srv/public`, requests like `https://storage.your-domain.com/logo.png` map straight to `/data/storage/logo.png` on the host.

## Quick Checklist

- [ ] Create host folders: `/data/storage` and (optionally) `/data/nginx-static/`
- [ ] Add Nginx container in Coolify with volumes + labels
- [ ] Copy static assets into `/data/storage`
- [ ] Test: visit `https://storage.your-domain.com/`
