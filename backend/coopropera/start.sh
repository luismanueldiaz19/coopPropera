#!/bin/bash

# Generar caché de configuración, rutas y vistas
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Ejecutar las migraciones a la base de datos (se necesita tener configuradas las variables DB_* en Render)
# La bandera --force es necesaria en producción para evitar el prompt de confirmación
php artisan migrate --force

# Ajustar puerto de Apache para Render (se hace aquí en tiempo de ejecución, no en el Dockerfile)
sed -i "s/80/${PORT:-80}/g" /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Iniciar Apache en primer plano
apache2-foreground
