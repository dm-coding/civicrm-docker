FROM colstrom/fish:ubuntu
 
RUN apt-get update
RUN apt-get install -y wget curl git php5-cli mysql-client php5-curl php5-mcrypt php5-mysql php5-gd ssmtp npm nodejs-legacy --no-install-recommends && \
    mkdir -p /root/.composer && \
    echo extension=mcrypt.so >> /etc/php5/cli/php.ini
COPY config.json /root/.composer/config.json
COPY install.sh /usr/local/bin/install.sh
COPY ssmtp.conf /etc/ssmtp/ssmtp.conf
# To install the maximal buildkit, do this instead:
#    curl -Ls https://civicrm.org/get-buildkit.sh | bash -s -- --full --dir /buildkit
RUN git clone https://github.com/civicrm/civicrm-buildkit.git /buildkit && \
    /buildkit/bin/civi-download-tools
RUN git config --global url."https://".insteadOf "git://" && \
    /buildkit/bin/civibuild download "CiviCRM" \
        --civi-ver "master" \
        --type "drupal-clean" \
        --web-root "/buildkit/build/CiviCRM"
RUN cd /buildkit/build/CiviCRM/sites/all/modules/civicrm && \
    /buildkit/bin/composer install
RUN cd /buildkit/build/CiviCRM/sites/all/modules/civicrm && \
    npm install
RUN apt-get clean && \ 
    rm -rf /var/lib/apt/lists

VOLUME ["/buildkit/build/CiviCRM"]

CMD ["/usr/local/bin/install.sh"]