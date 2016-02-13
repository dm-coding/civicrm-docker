#!/bin/bash
export PATH=/buildkit/bin:$PATH

# It's important that we only ever do this once.
if [ -e /buildkit/civi.installed.lock ]; then
    echo "Data Container: CiviCRM already installed."
    exit 0
fi

if [ -z "$DBTYPE" ]; then
    DBTYPE=mysql
fi
if [ -z "$CMS_DB_USER" ]; then
    CMS_DB_USER=$DB_ENV_MYSQL_USER
fi
if [ -z "$CMS_DB_PASS" ]; then
    CMS_DB_PASS=$DB_ENV_MYSQL_PASSWORD
fi
if [ -z "$SQLROOTPSWD" ]; then
    SQLROOTPSWD=$DB_ENV_MYSQL_ROOT_PASSWORD
fi
if [ -z "$SQLROOT" ]; then
    SQLROOT=root
fi
if [ -z "$CMS_DB_PORT" ]; then
    CMS_DB_PORT=3306
fi
if [ -z "$CMS_DB_NAME" ]; then
    CMS_DB_NAME=$DB_ENV_MYSQL_DATABASE
fi
if [ -z "$CMS_DB_HOST" ]; then
    CMS_DB_HOST=db
fi
if [ -z "$SITE_PROTO" ]; then
    SITE_PROTO=http
fi
if [ -z "$WEB_ROOT" ]; then
    WEB_ROOT=/buildkit/build/CiviCRM
fi
if [ -z "$UID" ]; then
    UID=33
fi
if [ -z "$GID" ]; then
    GID=33
fi

ROOTDSN="$DBTYPE://$SQLROOT:$SQLROOTPSWD@$CMS_DB_HOST:$SQLPORT/$CMS_DB_NAME"
CMS_DB_DSN="$DBTYPE://$CMS_DB_USER:$CMS_DB_PASS@$CMS_DB_HOST:$SQLPORT/$CMS_DB_NAME"

# Get rid of the amp_install function since docker manages our web and sql servers.
sed -i 's/amp_install//g' /buildkit/app/config/$SITE_TYPE/install.sh

# Hard-code some of our CMS DB params since they are set using docker environment variables and need to not be sanatised away when the installer runs...
# They will be loaded into the build environment after a modification to line 728 of /buildkit/src/civibuild.lib.sh (see line 75)
CONF="
    SITE_NAME=$SITE_NAME
    SITE_TYPE=$SITE_TYPE
    WEB_ROOT=$WEB_ROOT
    ADMIN_EMAIL="$ADMIN_EMAIL"
    ADMIN_PASS=$ADMIN_PASS
    CMS_URL=$CMS_URL
    CMS_DB_DSN=$CMS_DB_DSN
    CMS_DB_HOST=$CMS_DB_HOST
    CMS_DB_PASS=$CMS_DB_PASS
    CMS_DB_PORT=$CMS_DB_PORT
    CMS_DB_USER=$CMS_DB_USER
    CMS_DB_NAME=$CMS_DB_NAME
    CMS_DB_ARGS='-h $CMS_DB_HOST -u $CMS_DB_USER -p$CMS_DB_PASS -P $CMS_DB_PORT $CMS_DB_NAME'
    CMS_TITLE=$SITE_NAME
    CMS_ROOT=$WEB_ROOT
"
echo "$CONF" > /buildkit/install.conf

# Experimental: Since amp *insists* on managing the civi database, we'd like to load its parameters back into our environment in the rare case of interactive administrator logon:
echo "source /buildkit/install.conf" >> /root/.bashrc

# Force the install script to recognise our new environment variables ^
sed -i 's/function drupal_install() {/function drupal_install() {\n  source \/buildkit\/install.conf/g' /buildkit/src/civibuild.lib.sh

# Fix this bug: http://drupal.stackexchange.com/questions/126880/how-do-i-prevent-drupal-raising-a-segmentation-fault-when-using-a-node-js-themin which is caused as a result of https://www.drupal.org/node/1917530
rm -f /buildkit/build/CiviCRM/sites/all/modules/civicrm/node_modules/bower/lib/node_modules/handlebars/coverage/lcov.info
rm -f /./build/CiviCRM/sites/all/modules/civicrm/node_modules/bower/lib/node_modules/cli-width/coverage/lcov.info
#better:
#find /buildkit -name '*.info' -type f | grep node_modules | xargs rm -f

echo "Waiting for SQL container..."
# The SQL container probably *isn't* ready for us yet, so we'll have to wait for it.
while ! mysqladmin ping -h"$CMS_DB_HOST" --silent; do
    sleep 1
done

# Tell amp the root DSN for the database
amp config:set --mysql_dsn=$ROOTDSN

# ... Allow amp to configure the CiviCRM DB params.
amp create -f --root="$WEB_ROOT" --name="$CMS_DB_NAME" --prefix=CIVI_ --skip-url >> /buildkit/install.conf

echo "SQL container ready; installing CiviCRM"

# Install application (with civibuild)
civibuild install "$SITE_NAME" \
  --type $SITE_TYPE \
  --url "$SITE_PROTO://$CMS_URL:$CMS_DB_PORT" \
  --admin-pass "$ADMIN_PASS" \
  --admin-email "$ADMIN_EMAIL" \
  --web-root "$WEB_ROOT"
  
# TODO: Make only the writeable directories owned by www-data (more secure)
chown -R $UID:$GID $WEB_ROOT
chown -R $UID:$GID /buildkit/app/private

echo "Finished installing CiviCRM."

touch /buildkit/civi.installed.lock
