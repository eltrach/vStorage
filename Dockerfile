# Use the official Nginx image as the base image
FROM nginx:alpine

# Remove the default Nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy the main nginx configuration
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf

# Create conf.d directory and copy uploads configuration
RUN mkdir -p /etc/nginx/conf.d
COPY ./nginx/conf.d/uploads.conf /etc/nginx/conf.d/uploads.conf

# Create the uploads directory (will be overridden by volume mount)
RUN mkdir -p /srv/uploads && \
    chown -R nginx:nginx /srv/uploads && \
    chmod -R 755 /srv/uploads

# Expose port 80 (Traefik will route internally)
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]

