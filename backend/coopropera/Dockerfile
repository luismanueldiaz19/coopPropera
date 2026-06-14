FROM php:8.2-apache

# Instalar dependencias del sistema requeridas
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

# Instalar Node.js (para compilar assets con Vite)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Instalar Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Habilitar mod_rewrite de Apache para URLs amigables de Laravel
RUN a2enmod rewrite

# Establecer el directorio de trabajo
WORKDIR /var/www/html

# Copiar archivos de dependencias primero para aprovechar la cache de Docker
COPY composer.json composer.lock package.json ./
# NOTA: Si usas package-lock.json o yarn.lock, asegúrate de añadirlos aquí.

# Instalar dependencias de PHP (sin ejecutar scripts todavía)
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

# Instalar dependencias de NPM
RUN npm install

# Copiar el resto del código del proyecto
COPY . .

# Generar el autoload de Composer e intentar ejecutar scripts
RUN composer dump-autoload --optimize

# Compilar los assets de Vite para producción
RUN npm run build

# Configurar el DocumentRoot de Apache a la carpeta public de Laravel
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Configurar permisos para storage y bootstrap/cache
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Exponer el puerto por defecto
EXPOSE 80

# Copiar script de inicio
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Comando para ejecutar al iniciar el contenedor
CMD ["start.sh"]
