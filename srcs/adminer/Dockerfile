FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Création du répertoire pour Adminer
RUN mkdir -p /var/www/html

# Téléchargement d'Adminer
RUN wget -O /var/www/html/index.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php

# Configuration de PHP-FPM
RUN mkdir -p /run/php

COPY www.conf /etc/php/7.4/fpm/pool.d/

# Exposition du port pour PHP-FPM
EXPOSE 9000

# Démarrage de PHP-FPM
CMD ["/usr/sbin/php-fpm7.4", "-F"]
