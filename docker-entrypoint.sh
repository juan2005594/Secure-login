#!/bin/bash
set -e

PORT="${PORT:-10000}"
sed -i "s/Listen 80/Listen ${PORT}/g" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost \*:${PORT}>/g" /etc/apache2/sites-available/000-default.conf

php artisan storage:link || true

php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

if [ -n "$DB_URL" ] || [ -n "$DATABASE_URL" ] || [ -n "$DB_HOST" ]; then
    echo ">> Ejecutando migraciones de base de datos..."
    php artisan migrate --force || echo ">> Aviso: No se pudieron ejecutar migraciones inmediatamente."
    
    if [ "$RUN_SEEDERS" = "true" ]; then
        echo ">> Ejecutando seeders de datos iniciales..."
        php artisan db:seed --force || echo ">> Aviso: Fallo al ejecutar seeders."
    fi
fi

echo ">> Servidor iniciado en puerto $PORT"
exec apache2-foreground
