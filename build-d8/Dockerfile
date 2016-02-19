FROM colstrom/fish:ubuntu
 
RUN apt-get update
RUN apt-get install -y wget curl git nano php5-cli mysql-client php5-curl php5-mcrypt php5-mysql php5-gd ssmtp npm nodejs-legacy --no-install-recommends && \
    mkdir -p /root/.composer && \
    echo extension=mcrypt.so >> /etc/php5/cli/php.ini
COPY config.json /root/.composer/config.json
COPY install.sh /usr/local/bin/install.sh
COPY ssmtp.conf /etc/ssmtp/ssmtp.conf
RUN git config --global url."https://".insteadOf "git://" && \
    git clone https://github.com/civicrm/civicrm-buildkit.git /buildkit && \
    /buildkit/bin/civi-download-tools
# To install the maximal buildkit, do this instead:
#    curl -Ls https://civicrm.org/get-buildkit.sh | bash -s -- --full --dir /buildkit
RUN /buildkit/bin/civibuild download "${SITE_NAME:-CiviCRM}" \
        --civi-ver "${CIVIVER:-d8-master}" \
        --type "${SITE_TYPE:-drupal8-clean}" \
        --web-root "${WEB_ROOT:-/buildkit/build/CiviCRM}"
RUN cd ${WEB_ROOT:-/buildkit/build/CiviCRM}/modules/civicrm && \
    /buildkit/bin/composer install
RUN cd ${WEB_ROOT:-/buildkit/build/CiviCRM}/modules/civicrm && \
    npm install
RUN cd ${WEB_ROOT:-/buildkit/build/CiviCRM}/modules/civicrm && \
    echo '{ "allow_root": true }' > /root/.bowerrc && \
    node /buildkit/node_modules/bower/bin/bower install -f
RUN apt-get clean && \ 
    rm -rf /var/lib/apt/lists

VOLUME ["${WEB_ROOT:-/buildkit/build/CiviCRM}"]
VOLUME ["${PRIVATE_ROOT:-/buildkit/app/private}"]
VOLUME ["/etc/ssmtp"]

CMD ["/usr/local/bin/install.sh"]
