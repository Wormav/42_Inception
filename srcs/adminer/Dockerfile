FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Création du répertoire pour Adminer
RUN mkdir -p /var/www/html

# Copie du script shell dans l'image
COPY adminer_script.sh /usr/local/bin/adminer_script.sh

# Donner les permissions d'exécution au script
RUN chmod +x /usr/local/bin/adminer_script.sh

# Exécution du script pour télécharger Adminer
RUN /usr/local/bin/adminer_script.sh

# Configuration de PHP-FPM
RUN mkdir -p /run/php

COPY www.conf /etc/php/7.4/fpm/pool.d/

# Exposition du port pour PHP-FPM
EXPOSE 9001

# Démarrage de PHP-FPM
CMD ["/usr/sbin/php-fpm7.4", "-F"]
