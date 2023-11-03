FROM nginxinc/nginx-unprivileged
COPY index.html /usr/share/nginx/html

EXPOSE 8080