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

## Why This Works for Every Domain

Traefik matches by **path only** (`/uploads`), so any host hitting your Coolify proxy and requesting `/uploads/**` is routed to this Nginx service. More specific app routes (Host+Path) will take precedence elsewhere.

## Quick Checklist

- [ ] Create host folders: `/data/uploads` and `/data/nginx-uploads/` with config files
- [ ] Add Nginx container in Coolify with volumes + labels
- [ ] Mount `/data/uploads` RW in your app services
- [ ] Ensure your app returns `/uploads/...` URLs and uses hashed filenames
- [ ] Test: visit `https://<any-of-your-domains>/uploads/test.png`
