FROM nginx:stable

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Add custom config
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/symfony.conf /etc/nginx/sites-enabled/symfony.conf

# Set user for permissions
RUN usermod -u 1000 www-data
