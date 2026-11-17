# ==========================================
# ETAPA 1: Construcción de assets con Vite (Node.js)
# ==========================================
FROM node:20-alpine AS frontend
WORKDIR /app

COPY package*.json ./
RUN npm ci || npm install

COPY . .
RUN npm run build

# ==========================================
# ETAPA 2: Servidor PHP 8.2 + Apache para Producción
# ==========================================
FROM php:8.2-apache

# Instalar dependencias del sistema y extensiones de PHP necesarias
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    libpq-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    python3 \
    python3-pip \
    python3-venv \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_pgsql pdo_mysql gd zip bcmath \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Entorno virtual de Python para generación de reportes Word (generate_report.py)
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir python-docx
ENV PATH="/opt/venv/bin:$PATH"

# Instalar Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Configurar Apache para servir desde la carpeta public de Laravel
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Habilitar mod_rewrite de Apache para rutas de Laravel
RUN a2enmod rewrite

WORKDIR /var/www/html

# Copiar el código fuente
COPY . .

# Copiar los assets compilados por Vite desde la etapa 1
COPY --from=frontend /app/public/build ./public/build

# Instalar dependencias PHP de Composer sin dependencias de desarrollo
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Otorgar permisos correctos a storage y bootstrap/cache
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Copiar script de arranque
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Render expone la aplicación a través de la variable $PORT (usualmente 10000)
EXPOSE 10000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
