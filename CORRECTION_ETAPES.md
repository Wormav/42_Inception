# Étapes et Démos pour l'Évaluation Inception

Ce fichier décrit les étapes et les démonstrations à effectuer pour mener à bien l'évaluation.

---

### Étape 0: Préparation (Très Important !) - Modifier le fichier `hosts`

Pour que votre ordinateur puisse accéder à votre site via `https://jlorette.42.fr`, vous devez le faire pointer vers votre machine locale (`127.0.0.1`).

1.  **Ouvrez le fichier `hosts` en mode administrateur** :
    ```bash
    sudo nano /etc/hosts
    ```
2.  **Ajoutez la ligne suivante** à la fin du fichier :
    ```
    127.0.0.1 jlorette.42.fr
    ```
3.  **Enregistrez et fermez le fichier.**

---

### Étape 1: Démarrage à partir d'un environnement propre

L'évaluateur commencera par cette commande (ou une similaire) pour tout supprimer.
```bash
make fclean
```
Ensuite, démarrez le projet :
```bash
make
```

---

### Étape 2: Vérifications de base

1.  **Accès au site**: Ouvrez `https://jlorette.42.fr`.
    *   ✅ Le site WordPress doit s'afficher, pas la page d'installation.
    *   ✅ L'avertissement de sécurité SSL est normal.

2.  **Accès HTTP impossible**: Essayez d'accéder à `http://jlorette.42.fr`.
    *   ✅ La connexion doit échouer.

3.  **Vérification des services**: Montrez que tout est en cours d'exécution.
    ```bash
    docker compose -f srcs/docker-compose.yml ps
    ```
    *   ✅ Les 4 services (`nginx`, `wordpress`, `mariadb`, `adminer`) doivent être visibles et "running".

---

### Étape 3: Démonstrations spécifiques

#### A. Démo des utilisateurs (Admin vs Non-Admin)

Le but est de montrer que vous avez au moins deux utilisateurs avec des droits différents.

1.  **Connectez-vous en tant qu'administrateur** :
    *   Allez sur `https://jlorette.42.fr/wp-admin`.
    *   Utilisateur : `jlorette`, Mot de passe : `adminpass` (celui de votre `.env`).
    *   Montrez le tableau de bord complet : accès aux thèmes, plugins, réglages...

2.  **Déconnectez-vous.**

3.  **Connectez-vous en tant qu'utilisateur non-admin** :
    *   Utilisateur : `batman`, Mot de passe : `adminpass` (le même que l'admin, comme défini dans le script).
    *   Montrez le tableau de bord **restreint**. L'utilisateur "Auteur" peut créer des articles, mais ne peut pas changer les réglages du site.

#### B. Démo de la base de données (MariaDB)

Le but est de prouver que la base de données est fonctionnelle et contient des données.

1.  **Connectez-vous au conteneur MariaDB** :
    ```bash
    docker exec -it mariadb mysql -u user -ppassword wordpress
    ```
    *(Note : les identifiants `user` et `password` sont ceux de votre .env. Le `-p` est collé au mot de passe)*

2.  Une fois dans le client `mysql`, **prouvez que la base de données n'est pas vide**. La commande `SHOW TABLES;` est parfaite pour ça.
    ```sql
    SHOW TABLES;
    ```
    *   ✅ Une liste de tables WordPress (`wp_users`, `wp_posts`...) doit s'afficher.

3.  Vous pouvez même aller plus loin en montrant les utilisateurs que vous venez de tester :
    ```sql
    SELECT user_login, user_email FROM wp_users;
    ```
    *   ✅ Vous devriez voir `jlorette` et `batman` dans le résultat.
    *   Tapez `exit` pour quitter.

---

### Étape 4: Test de la persistance des données

C'est le test le plus important pour valider les volumes. Il doit être fait après un redémarrage **complet** de la machine.

1.  **Créez une preuve** : Sur le site, en étant connecté en tant que `jlorette`, créez un nouvel article avec un titre clair comme "Test de persistance". Publiez-le.

2.  **Redémarrez la machine** :
    ```bash
    sudo reboot
    ```

3.  **Après le redémarrage**, retournez dans le dossier du projet et relancez les services :
    ```bash
    make
    ```

4.  **Vérifiez la preuve** :
    *   Ouvrez `https://jlorette.42.fr`.
    *   ✅ L'article "Test de persistance" doit toujours être visible sur le site. Les données ont bien été conservées.

---

### Étape 5: Nettoyage final

Une fois l'évaluation terminée, vous pouvez tout nettoyer.
```bash
make fclean
```