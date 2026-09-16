FROM nginx:alpine

# Copiar el código web al directorio de Nginx
COPY . /usr/share/nginx/html

# Exponer el puerto 80 HTTP
EXPOSE 80

# Nginx arranca en primer plano por defecto
CMD ["nginx", "-g", "daemon off;"]
