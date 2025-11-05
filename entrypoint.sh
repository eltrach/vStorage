#!/bin/sh
set -e

# Create required directories if they don't exist
mkdir -p /var/cache/nginx
mkdir -p /var/log/nginx
mkdir -p /var/run/nginx
mkdir -p /tmp/nginx_cache
mkdir -p "${ROOT_PATH}"

# Set permissions
chmod -R 755 /var/cache/nginx \
            /var/log/nginx \
            /var/run/nginx \
            /tmp/nginx_cache \
            "${ROOT_PATH}"

# Remove the nginx.pid file if it exists
rm -f /var/run/nginx/nginx.pid

# Substitute environment variables in the template
envsubst '${NGINX_PORT} ${SERVER_NAME} ${ROOT_PATH}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

# Test nginx configuration
nginx -t

# Start nginx as root
exec "$@" 