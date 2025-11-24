# Tutoriel : Reconstruire le Projet Inception de A à Z

Ce guide a pour but de vous accompagner, étape par étape, dans la reconstruction complète du projet Inception. Il est conçu pour être didactique, afin de vous aider à expliquer chaque composant à quelqu'un qui découvre le projet.

## Introduction : L'Objectif

Le but d'Inception est de monter une infrastructure web complète en utilisant Docker. Chaque service essentiel (serveur web, base de données, application) sera isolé dans son propre conteneur, et tout sera orchestré par Docker Compose. C'est une compétence fondamentale en développement et en DevOps.

**Les services que nous allons mettre en place :**
- **Nginx :** Le serveur web qui reçoit les requêtes des visiteurs.
- **MariaDB :** La base de données qui stockera toutes les données de notre site.
- **WordPress :** L'application (CMS) qui fera tourner notre site.
- **Adminer (en bonus) :** Un outil pour gérer notre base de données via une interface web.

---

## Étape 1 : La Structure du Projet

Une bonne organisation est la clé. Tous nos fichiers de configuration seront dans un dossier `srcs`, lui-même subdivisé par service.

Ouvrez votre terminal et créez l'arborescence :
```bash
mkdir -p srcs/{nginx,wordpress,mariadb}
```
Vous devriez avoir :
```
.
└── srcs/
    ├── mariadb/
    ├── nginx/
    └── wordpress/
```

---

## Étape 2 : MariaDB - La Base de Données

Commençons par le service le plus indépendant : la base de données.

#### 1. Le `Dockerfile` (`srcs/mariadb/Dockerfile`)
Ce fichier construit l'image de notre conteneur MariaDB.

```dockerfile
# On part d'une image Debian Bullseye (version stable)
FROM debian:bullseye

# On installe le serveur MariaDB et le client
RUN apt update && apt install -y mariadb-client mariadb-server gettext-base

# On copie notre fichier de configuration personnalisé
COPY server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# On copie un script qui s'exécutera au premier démarrage pour initialiser la BDD
COPY init.sql.template /docker-entrypoint-initdb.d/.

# On crée le dossier nécessaire au bon fonctionnement de mysqld
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

# Le port standard de MySQL/MariaDB
EXPOSE 3306

# On copie et on rend exécutable notre script d'entrée
COPY docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh
ENTRYPOINT ["./docker-entrypoint.sh"]

# Commande par défaut pour lancer le serveur
CMD ["mysqld"]
```

#### 2. Le script d'entrée (`srcs/mariadb/docker-entrypoint.sh`)
Ce script s'assure que la base de données est bien initialisée avant de lancer le service.

```bash
#!/bin/sh
# Ce script permet de s'assurer que les variables d'environnement sont bien prises en compte
# par le template SQL avant de lancer le processus principal.

# 'envsubst' va remplacer les variables comme ${MYSQL_USER} dans le template
# par leurs vraies valeurs (qui viendront du fichier .env)
envsubst < /docker-entrypoint-initdb.d/init.sql.template > /docker-entrypoint-initdb.d/init.sql

# 'exec "$@"' lance ensuite la commande principale du Dockerfile (CMD)
exec "$@"
```

#### 3. Le template SQL (`srcs/mariadb/init.sql.template`)
Ce template est utilisé une seule fois pour créer la base `wordpress` et son utilisateur.

```sql
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON wordpress.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

#### 4. La configuration du serveur (`srcs/mariadb/server.cnf`)
Ce fichier de configuration indique à MariaDB d'écouter les connexions venant de partout (et pas seulement de `localhost`), ce qui est crucial dans un environnement Docker.

```ini
[mysqld]
bind-address = 0.0.0.0
```

---

## Étape 3 : WordPress - Le Cœur du Site

Ce conteneur ne contiendra que l'application WordPress, qui tourne grâce à PHP-FPM (un gestionnaire de processus PHP).

#### 1. Le `Dockerfile` (`srcs/wordpress/Dockerfile`)
```dockerfile
# On part de la même base Debian pour la cohérence
FROM debian:bullseye

# On désactive les questions interactives pendant l'installation
ENV DEBIAN_FRONTEND=noninteractive

# On installe les outils : curl (pour télécharger), php-fpm (pour faire tourner WP)
# et php-mysqli (pour que PHP puisse parler à MariaDB)
RUN apt update && \
    apt upgrade -y && \
    apt install -y curl php-fpm php-mysqli && \
    apt clean && rm -rf /var/lib/apt/lists/*

# On crée le dossier pour le socket de communication de PHP-FPM
RUN mkdir -p /run/php && chown www-data:www-data /run/php

# On copie la configuration de notre "pool" PHP-FPM
COPY www.conf /etc/php/7.4/fpm/pool.d/

# On se place dans le dossier où sera le site
WORKDIR /var/www/html/

# On copie notre script d'installation
COPY script.sh .
RUN chmod +x script.sh

# Le port sur lequel PHP-FPM écoute
EXPOSE 9000

# Le script d'installation sera le point d'entrée
ENTRYPOINT ["/var/www/html/script.sh"]

# Commande par défaut : lancer PHP-FPM et le garder au premier plan
CMD ["php-fpm7.4", "-F"]
```

#### 2. La configuration PHP-FPM (`srcs/wordpress/www.conf`)
Ce fichier dit à PHP-FPM d'écouter sur le port `9000` les requêtes venant de n'importe où (pas seulement `localhost`). C'est ce qui permettra à Nginx de communiquer avec WordPress.

```ini
[www]
user = www-data
group = www-data
listen = 0.0.0.0:9000
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

#### 3. Le script d'installation (`srcs/wordpress/script.sh`)
C'est la magie du projet. Ce script utilise `wp-cli`, un outil en ligne de commande pour WordPress, afin d'automatiser toute l'installation.

```bash
#!/bin/sh

# On attend que la base de données soit prête à accepter des connexions
# C'est une sécurité pour éviter que le script ne se lance trop tôt
while ! mariadb -h mariadb -u ${DB_USER} -p${DB_PASS} --silent; do
    sleep 1
done

cd /var/www/html

# On installe wp-cli et on télécharge WordPress
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
./wp-cli.phar core download --allow-root

# On crée le fichier wp-config.php avec les infos de la BDD
./wp-cli.phar config create --dbname=wordpress --dbuser=$DB_USER --dbpass=$DB_PASS --dbhost=mariadb --allow-root

# On installe WordPress (création des tables, de l'admin...)
./wp-cli.phar core install --url=jlorette.42.fr --title=inception --admin_user=$WP_USER --admin_password=$WP_PASS --admin_email=admin@admin.com --allow-root

# On crée un deuxième utilisateur non-admin
./wp-cli.phar user create batman batman@gotham.com --user_pass=$WP_PASS --role=author --allow-root

# On exécute la commande par défaut du Dockerfile (lancement de php-fpm)
exec "$@"
```

---

## Étape 4 : Nginx - La Vitrine

Nginx est le seul service exposé à Internet. Il gère le HTTPS et redirige les requêtes PHP vers le conteneur WordPress.

#### 1. Le `Dockerfile` (`srcs/nginx/Dockerfile`)
```dockerfile
FROM debian:bullseye

# On installe Nginx et openssl pour créer notre certificat
RUN apt update  && apt install -y nginx openssl && \
    # On crée notre certificat SSL auto-signé
    mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -out /etc/nginx/ssl/certificate.crt \
    -keyout /etc/nginx/ssl/certificate.key \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=jlorette.42.fr/emailAddress=jlorette@student.42.fr"

# On copie notre fichier de configuration principal
COPY nginx.conf /etc/nginx/conf.d

# Le port HTTPS
EXPOSE 443

# On lance Nginx en mode "démon off" pour qu'il reste au premier plan
CMD ["nginx", "-g", "daemon off;"]
```

#### 2. La configuration Nginx (`srcs/nginx/nginx.conf`)
C'est le cerveau de notre serveur web.

```nginx
server {
    # On n'écoute que sur le port 443 (HTTPS)
    listen 443 ssl;
    listen [::]:443 ssl;

    # Le nom de domaine de notre site
    server_name jlorette.42.fr;

    # Emplacement des certificats SSL
    ssl_certificate /etc/nginx/ssl/certificate.crt;
    ssl_certificate_key /etc/nginx/ssl/certificate.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    # La racine des fichiers du site
    root /var/www/html;
    index index.php index.html;

    # Configuration standard pour WordPress
    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    # Toutes les requêtes se terminant par .php sont envoyées à notre
    # conteneur WordPress sur le port 9000
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+);
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

---

## Étape 5 : Docker Compose - L'Orchestrateur

Maintenant, on assemble les pièces du puzzle.

#### 1. Le fichier `.env` (`srcs/.env`)
Ce fichier contiendra toutes nos variables. Il est crucial pour la sécurité et la flexibilité.

```env
# Identifiants pour la base de données
DB_USER=user
DB_PASS=password
MYSQL_USER=user
MYSQL_PASSWORD=password

# Identifiants pour l'administrateur WordPress (ne pas utiliser "admin" !)
WP_USER=jlorette
WP_PASS=adminpass

# Chemin sur votre machine pour stocker les données (à adapter si besoin)
DATA_DIR=/Users/jeremy/data
```

#### 2. Le fichier `docker-compose.yml` (`srcs/docker-compose.yml`)
C'est le chef d'orchestre.

```yaml
volumes:
  wordpress:
    name: wordpress
    driver: local
    driver_opts:
      device: ${DATA_DIR}/wordpress
      o: bind
      type: none
  mariadb:
    name: mariadb
    driver: local
    driver_opts:
      device: ${DATA_DIR}/mariadb
      o: bind
      type: none

services:
  wordpress:
    container_name: wordpress
    build:
      context: ./wordpress/
      dockerfile: Dockerfile
    image: wordpress
    networks:
      - docker-network
    volumes:
      - wordpress:/var/www/html
    depends_on:
      - mariadb
    expose:
      - "9000"
    env_file:
      - .env
    restart: unless-stopped

  mariadb:
    container_name: mariadb
    build:
      context: ./mariadb/
      dockerfile: Dockerfile
    image: mariadb
    networks:
      - docker-network
    volumes:
      - mariadb:/var/lib/mysql
    expose:
      - "3306"
    environment:
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASS}
    restart: unless-stopped

  nginx:
    container_name: nginx
    build:
      context: ./nginx/
      dockerfile: Dockerfile
    image: nginx
    networks:
      - docker-network
    volumes:
      - wordpress:/var/www/html
    ports:
      - "443:443"
    depends_on:
      - wordpress
    restart: unless-stopped

networks:
  docker-network:
    name: docker-network
    driver: bridge
```

---

## Étape 6 : Makefile - Les Raccourcis

Pour éviter de taper des commandes `docker compose` à rallonge, on crée un `Makefile` à la **racine** du projet.

#### Le `Makefile` (`Makefile`)
```makefile
# Chemin pour les données (utilisez '~' pour votre dossier personnel)
DATA_DIR=~/data

all: dirs build start

dirs:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress

build:
	docker compose -f srcs/docker-compose.yml build

start:
	docker compose -f srcs/docker-compose.yml up -d

stop:
	docker compose -f srcs/docker-compose.yml down

clean: stop

fclean: clean
	@echo "Removing data directories at $(DATA_DIR)..."
	@sudo rm -rf $(DATA_DIR)

.PHONY: all dirs build start stop clean fclean
```

---

## Étape 7 : Lancement Final

1.  **Modifiez votre fichier `/etc/hosts`** pour ajouter :
    `127.0.0.1 jlorette.42.fr`

2.  **Lancez tout** avec une seule commande :
    `make`

3.  **Visitez `https://jlorette.42.fr`** et admirez le travail !

---

## Étape Bonus : Ajout d'Adminer

Adminer est un outil léger pour visualiser et gérer votre base de données.

1.  **Créez le dossier** `srcs/adminer`.

2.  **Créez `srcs/adminer/Dockerfile`** :
    ```dockerfile
    FROM debian:bullseye
    RUN apt-get update && apt-get install -y php7.4-fpm php7.4-mysql wget && rm -rf /var/lib/apt/lists/*
    RUN mkdir -p /var/www/html
    COPY adminer_script.sh /usr/local/bin/adminer_script.sh
    RUN chmod +x /usr/local/bin/adminer_script.sh
    RUN /usr/local/bin/adminer_script.sh
    RUN mkdir -p /run/php
    COPY www.conf /etc/php/7.4/fpm/pool.d/
    EXPOSE 9000
    CMD ["/usr/sbin/php-fpm7.4", "-F"]
    ```
3.  **Créez `srcs/adminer/adminer_script.sh`** (qui télécharge Adminer) :
    ```bash
    #!/bin/sh
    wget "http://www.adminer.org/latest.php" -O /var/www/html/index.php
    echo "Adminer has been downloaded."
    ```
4.  **Copiez `srcs/wordpress/www.conf` vers `srcs/adminer/www.conf`**. C'est la même configuration.

5.  **Modifiez `srcs/docker-compose.yml`** pour ajouter le service `adminer` :
    ```yaml
    # ... à la fin de la section 'services'
      adminer:
        container_name: adminer
        build:
          context: ./adminer/
          dockerfile: Dockerfile
        image: adminer
        networks:
          - docker-network
        depends_on:
          - mariadb
        restart: always
    ```
    N'oubliez pas aussi d'ajouter un volume pour `adminer` en haut du fichier.

6.  **Modifiez `srcs/nginx/nginx.conf`** pour ajouter la route vers Adminer :
    ```nginx
    # ... à l'intérieur du bloc 'server'
    	 location /adminer {
            fastcgi_pass adminer:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME /var/www/html/index.php;
        }
    ```

7.  Relancez tout avec `make re` (ou `make fclean && make`), et visitez `https://jlorette.42.fr/adminer` !

Voilà ! Vous avez maintenant un guide complet pour reconstruire le projet et expliquer chaque morceau. Bon courage à vous et à votre amie !
