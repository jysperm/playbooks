FROM nextcloud:25-fpm-alpine

RUN apk --no-cache add shadow &&\
    userdel xfs &&\
    find / -user $(id -u www-data) -exec chown -h 33 {} \; &&\
    find / -group $(id -g www-data) -exec chgrp -h 33 {} \; &&\
    usermod -u 33 www-data &&\
    groupmod -g 33 www-data

RUN ln -s /usr/local/bin/php /usr/bin/php

RUN echo '*/15 * * * * php -f /var/www/html/occ files:scan --all' >> /etc/crontabs/www-data
