# ==========================================
# ETAPA 1: Construir el Frontend (Flutter Web)
# ==========================================
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-builder

# Establecer directorio de trabajo para el frontend
WORKDIR /app

# Copiar el código del frontend al contenedor
COPY frontend/app/ ./

# Limpiar caché y obtener dependencias de Flutter
RUN flutter clean
RUN flutter pub get

# Construir la versión web de Flutter para producción
RUN flutter build web --release

# ==========================================
# ETAPA 2: Construir el Backend (Laravel) y Servir Todo
# ==========================================
FROM php:8.2-apache

# Instalar dependencias del sistema requeridas por PHP y Laravel
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    curl \
    libpq-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd

# Instalar Node.js (para compilar assets de Laravel)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Instalar Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Habilitar mod_rewrite de Apache
RUN a2enmod rewrite

# Establecer el directorio de trabajo del Backend
WORKDIR /var/www/html

# Copiar archivos de configuración primero para optimizar caché de Docker
COPY backend/coopropera/composer.json backend/coopropera/composer.lock backend/coopropera/package.json ./

# Instalar dependencias de PHP y Node
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist
RUN npm install

# Copiar TODO el código del backend al directorio html de Apache
COPY backend/coopropera/ .

# Generar autoloader de PHP y compilar assets
RUN composer dump-autoload --optimize
RUN npm run build

# --- LA MAGIA MULTI-STAGE ---
# Copiar el build de la web de Flutter desde la Etapa 1 a la carpeta public de Laravel
COPY --from=flutter-builder /app/build/web/ /var/www/html/public/

# Configurar Apache para apuntar a la carpeta public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Configurar permisos requeridos por Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Exponer el puerto por defecto
EXPOSE 80

# Preparar y asignar el script de inicio
RUN cp start.sh /usr/local/bin/start.sh && chmod +x /usr/local/bin/start.sh

# Ejecutar script al iniciar
CMD ["start.sh"]
