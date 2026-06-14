#!/bin/bash

# Generar caché de configuración, rutas y vistas
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Ejecutar las migraciones a la base de datos (se necesita tener configuradas las variables DB_* en Render)
# La bandera --force es necesaria en producción para evitar el prompt de confirmación
php artisan migrate --force

# Iniciar Apache en primer plano
apache2-foreground
