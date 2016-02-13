FROM richarvey/nginx-php-fpm
ARG WEB_ROOT=/buildkit/build/CiviCRM
RUN apt-get update && \
    apt-get install -y -q --no-install-recommends nginx-extras ssmtp && \
    apt-get clean &&  \
    rm -rf /var/lib/apt/lists /etc/ssmtp && \
    sed -i "s,/usr/share/nginx/html,${WEB_ROOT},g" /etc/nginx/sites-enabled/default.conf