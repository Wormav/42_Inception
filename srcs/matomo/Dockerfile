FROM debian:bullseye

# Installer les dépendances nécessaires
RUN apt-get update && apt-get install -y \
    apache2 \
    mariadb-client \
    php \
    php-mysql \
    php-cli \
    php-curl \
    php-gd \
    php-xml \
    php-mbstring \
    wget \
    unzip \
    && apt-get clean

# Télécharger et installer Matomo
RUN wget https://builds.matomo.org/matomo.zip -O /tmp/matomo.zip && \
    unzip /tmp/matomo.zip -d /var/www/html/ && \
    rm /tmp/matomo.zip && \
    chown -R www-data:www-data /var/www/html/matomo

# Configurer Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    a2enmod rewrite && \
    service apache2 restart

# Exposer le port 80
EXPOSE 80

# Lancer Apache en tant que processus principal
CMD ["apachectl", "-D", "FOREGROUND"]
