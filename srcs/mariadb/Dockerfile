FROM debian:bullseye

RUN apt update && apt install -y mariadb-client mariadb-server zsh gettext-base

# Copy MariaDB server configuration
COPY server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

RUN mkdir /docker-entrypoint-initdb.d

COPY init.sql.template /docker-entrypoint-initdb.d/.

RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

# Expose the default MariaDB port
EXPOSE 3306

COPY docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh
ENTRYPOINT ["./docker-entrypoint.sh"]

CMD ["mysqld"]
