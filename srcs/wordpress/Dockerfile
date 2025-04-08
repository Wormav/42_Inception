FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt upgrade -y && \
    apt install -y curl php-fpm php-mysqli zsh && \
    apt clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/php && chown www-data:www-data /run/php

COPY www.conf /etc/php/7.4/fpm/pool.d/

WORKDIR /var/www/html/

COPY script.sh .

RUN chmod +x script.sh

EXPOSE 9000

ENTRYPOINT ["/var/www/html/script.sh"]

CMD ["php-fpm7.4", "-F"]
