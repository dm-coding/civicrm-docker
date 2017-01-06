FROM colstrom/fish:ubuntu

# For D8, use d8master. For backdrop, use bmaster or bcmaster.
ENV CIVIVER "master"

# Use drupal-clean, drupal-demo, d8-clean, or d8-demo
ENV SITE_TYPE "drupal-clean"
ENV SITE_NAME "CiviCRM"
ENV WEB_ROOT "/buildkit/build/CiviCRM"
# For D8, use $WEB_ROOT/modules/civicrm
ENV CIVI_ROOT "/buildkit/build/CiviCRM/sites/all/modules/civicrm"

RUN apt-get update
RUN apt-get install -y wget curl bzip2 git nano php5-cli mysql-client php5-curl php5-intl php5-mcrypt php5-imap php5-mysql php5-gd ssmtp npm nodejs-legacy unzip zip --no-install-recommends && \
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
        --civi-ver "${CIVIVER}" \
        --type "${SITE_TYPE}" \
        --web-root "${WEB_ROOT}"
RUN cd ${CIVI_ROOT} && \
    /buildkit/bin/composer install
RUN cd ${CIVI_ROOT} && \
    npm install
RUN cd ${CIVI_ROOT} && \
    echo '{ "allow_root": true }' > /root/.bowerrc && \
    node /buildkit/node_modules/bower/bin/bower install -f
RUN cd /tmp && \
    wget "https://download.civicrm.org/civicrm-4.7.2-l10n.tar.gz?src=donate" && \
    tar -zxvf "civicrm-4.7.2-l10n.tar.gz?src=donate" && \
    mv civicrm/sql/* $CIVI_ROOT/sql && \
    mv civicrm/l10n $CIVI_ROOT
RUN apt-get clean && \
    rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists

VOLUME ["${WEB_ROOT}"]
VOLUME ["${PRIVATE_ROOT:-/buildkit/app/private}"]
VOLUME ["/etc/ssmtp"]

CMD ["/usr/local/bin/install.sh"]
