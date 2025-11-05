# Generic Nginx Uploads Server

A high-performance NGINX server for serving `/uploads/**` content, designed for deployment in Coolify with Traefik reverse proxy. Works with **any domain** without configuration changes.

## Features

- **Domain Agnostic**: Works with any domain when deployed in Coolify
- **Traefik Integration**: Automatic routing via PathPrefix(`/uploads`)
- **Long-term Caching**: 1-year cache for media files, 5-minute for misc
- **Security**: Comprehensive security headers
- **Performance**: Optimized for static file serving
- **Docker Support**: Containerized deployment ready

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and modify as needed:

```bash
# Host port mapping (optional - defaults to 80)
HOST_PORT=80

# Host uploads path (optional - defaults to ./uploads)
HOST_UPLOADS_PATH=./uploads

# Nginx config path (optional - defaults to ./nginx)
NGINX_CONFIG_PATH=./nginx
```

For Coolify deployments, use absolute paths:

```bash
HOST_UPLOADS_PATH=/data/uploads
NGINX_CONFIG_PATH=/data/nginx-uploads
```

## High-level Design

- **Coolify (Traefik) = TLS + routing**
  Route any request with `PathPrefix(/uploads)` to this Nginx service.

- **Nginx container = static origin**
  Serves `/uploads/**` from a shared host folder with caching headers.

- **Your app containers = writers**
  They mount the same host folder and save files with content-hashed names.

## File/volume Layout (Host)

```
/data/uploads/                  # shared host folder
  avatars/<userId>/<shard>/<hash>.<ext>
  banners/<userId>/<shard>/<hash>.<ext>
  characters/<userId>/<shard>/<hash>.<ext>
  scenes/<userId>/<shard>/<hash>.<ext>
  general/<userId>/<shard>/<hash>.<ext>

# Nginx config files (host-mounted)
 /data/nginx-uploads/nginx.conf
 /data/nginx-uploads/conf.d/uploads.conf
```

- **Writers (Hono)** mount: `/data/uploads -> /srv/uploads:rw`
- **Nginx** mounts: `/data/uploads -> /srv/uploads:ro`
- **Healthcheck**: `/healthz` returns `ok` and is safe to expose to orchestrators

## Deployment in Coolify

### 1. Add Docker Container

In Coolify, add a **Docker Container** (not an app proxy) with:

- **Image:** `nginx:alpine`
- **Ports:** **none** (Traefik will route internally)
- **Volumes:**
  - `/data/uploads` → `/srv/uploads:ro`
  - `/data/nginx-uploads/nginx.conf` → `/etc/nginx/nginx.conf:ro`
  - `/data/nginx-uploads/conf.d/uploads.conf` → `/etc/nginx/conf.d/uploads.conf:ro`
- **Networks:** attach it to the same network as Coolify's reverse proxy

### 2. Traefik Labels

Add these labels in Coolify "Labels" section:

```yaml
traefik.enable=true
traefik.http.routers.uploads.rule=PathPrefix(`/uploads`)
traefik.http.routers.uploads.entrypoints=websecure
traefik.http.routers.uploads.tls=true
traefik.http.services.uploads.loadbalancer.server.port=80
traefik.http.routers.uploads.priority=1
```

### 3. App Containers

Mount `/data/uploads` RW in your app services:

- Mount: `/data/uploads` → `/srv/uploads:rw`
- Upload endpoint writes to `/srv/uploads/...` with content-hashed filenames
- Return URLs like: `https://ANY-OF-YOUR-DOMAINS/uploads/avatars/<userId>/<shard>/<hash>.webp`

### Notes for Coolify Deployments

- Coolify disallows variable substitution in bind-mount definitions. When you configure the container in the Coolify UI, enter absolute host paths directly (e.g. `/data/uploads:/srv/uploads:ro`). The provided `docker-compose.yml` uses relative paths for local development; adjust or override them when deploying.
- Traefik handles TLS/hostnames, so you do **not** need to expose any ports on the container. The compose file maps `9181:80` purely for local testing—omit this in Coolify if Traefik is routing internally.

## Local Docker Compose Usage

For quick local tests:

1. Create the folders the compose file expects:
   ```bash
   mkdir -p uploads nginx/conf.d
   ```
   (The repo already contains `nginx/conf.d/uploads.conf`; ensure `uploads/` exists.)
2. Run `docker compose up --build`.
3. Verify `http://localhost:9181/healthz` returns `ok`, then hit `http://localhost:9181/uploads/...` once you copy files into `uploads/`.

Adjust the port mapping in `docker-compose.yml` if `9181` conflicts with something else on your dev machine.

## Why This Works for Every Domain

Traefik matches by **path only** (`/uploads`), so any host hitting your Coolify proxy and requesting `/uploads/**` is routed to this Nginx service. More specific app routes (Host+Path) will take precedence elsewhere.

## Quick Checklist

- [ ] Create host folders: `/data/uploads` and `/data/nginx-uploads/` with config files
- [ ] Add Nginx container in Coolify with volumes + labels
- [ ] Mount `/data/uploads` RW in your app services
- [ ] Ensure your app returns `/uploads/...` URLs and uses hashed filenames
- [ ] Test: visit `https://<any-of-your-domains>/uploads/test.png`
