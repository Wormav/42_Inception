#!/bin/bash
# adminer_script.sh

# URL de téléchargement d'Adminer
ADMINER_URL="https://github.com/vrana/adminer/releases/download/v5.1.1/adminer-5.1.1.php"

# Répertoire de destination
DEST_DIR="/var/www/html"

# Création du répertoire de destination s'il n'existe pas
mkdir -p "$DEST_DIR"

# Téléchargement d'Adminer
wget -O "$DEST_DIR/index.php" "$ADMINER_URL"
