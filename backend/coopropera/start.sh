#!/bin/bash

# Generar caché de configuración, rutas y vistas
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Ejecutar las migraciones a la base de datos y correr los seeders
# La bandera --force es necesaria en producción para evitar el prompt de confirmación
php artisan migrate --force --seed

# Ajustar puerto de Apache para Render (se hace aquí en tiempo de ejecución, no en el Dockerfile)
sed -i "s/80/${PORT:-80}/g" /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# IMPORTANTE: Reasignar permisos a www-data. 
# Como este script se ejecuta como root, los archivos de caché generados arriba pertenecen a root.
# Apache corre como www-data, así que fallará (Error 500) si no le devolvemos los permisos.
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Iniciar Apache en primer plano
apache2-foreground
