#!/bin/bash
export PATH=/buildkit/bin:$PATH
WEB_ROOT=/buildkit/build/CiviCRM

echo "Installing CiviCRM..."

# Tell amp the root DSN for the database
amp config:set --mysql_dsn=mysql://root:ftf@mysql:3306/civi

# Get rid of the amp_install function since docker manages our web and sql servers.
sed -i 's/amp_install//g' /buildkit/app/config/drupal-clean/install.sh

# Hard-code some of our CMS DB params since they will be set using docker environment variables...
read -d '' CONF <<"EOF"
    SITE_NAME=civi
    SITE_TYPE=drupal-clean
    WEB_ROOT=/buildkit/build/CiviCRM
    ADMIN_EMAIL="admin@example.com"
    ADMIN_PASS=123
    CMS_URL=localhost
    CMS_DB_DSN=mysql://civi:civi@mysql:3306/civi
    CMS_DB_HOST=mysql
    CMS_DB_PASS=civi
    CMS_DB_PORT=3306
    CMS_DB_USER=civi
    CMS_DB_NAME=civi
    CMS_DB_ARGS='-h mysql -u civi -pcivi -P 3306 civi'
    CMS_TITLE=CiviCRM
    CMS_ROOT=/buildkit/build/CiviCRM
EOF
echo "$CONF" > /buildkit/install.conf

# ... but allow amp to configure the CiviCRM DB params.
amp create -f --root="$WEB_ROOT" --name=civi --prefix=CIVI_ --skip-url >> /buildkit/install.conf

# Experimental: Since amp *insists* on managing the civi database, we'd like to load its parameters back into our environment in the rare case of interactive administrator logon:
echo "source /buildkit/install.conf" >> /root/.bashrc

# Force the install script to recognise our new environment variables ^
sed -i 's/function drupal_install() {/function drupal_install() {\n  source \/buildkit\/install.conf/g' /buildkit/src/civibuild.lib.sh

# Stop bower from complaining when it runs as root
echo '{ "allow_root": true }' > /root/.bowerrc

# Fix this bug: http://drupal.stackexchange.com/questions/126880/how-do-i-prevent-drupal-raising-a-segmentation-fault-when-using-a-node-js-themin which is caused as a result of https://www.drupal.org/node/1917530
rm -f /buildkit/build/CiviCRM/sites/all/modules/civicrm/node_modules/bower/lib/node_modules/handlebars/coverage/lcov.info
rm -f /./build/CiviCRM/sites/all/modules/civicrm/node_modules/bower/lib/node_modules/cli-width/coverage/lcov.info
#better:
#find /buildkit -name '*.info' -type f | grep node_modules | xargs rm -f

# Install application (with civibuild)
civibuild install "CiviCRM" \
  --url "http://localhost:80" \
  --admin-pass "123" \
  --web-root "/buildkit/build/CiviCRM"

# Should move to web server container
# TODO: Only chown the directories which actually need to be writeable (will improve security)
chown -R www-data:www-data /buildkit/build/CiviCRM