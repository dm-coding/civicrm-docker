# CiviCRM Docker

A small number of Docker containers for CiviCRM exist already, however most are either lacking documentation, do not build successfully, require convoluted steps to install, or do not follow established Docker principles.

In contrast, this container is designed to be:

* Simple -- it installs only what is needed for the buildkit and does not bundle extraneous extras like postfix or sshd

* Composable -- most importantly, the web server and the SQL database server are kept in separate containers. This allows you to swap them out with other containers, modify their workings, or even scale them out to separate hosts.

* Useable -- every thing you need is here. Even email works out of the box (just modify the SSMTP configuration). Every runs automatically with docker-compose and requires no manual build steps.

In particular it is superior to my other buildkit-based docker container in that it does not just "naively" run buildkit inside the docker environment. However if you did need to run buildkit naively inside the Docker environment, this is probably the best container to use: https://github.com/djcf/civibuildkit-docker

# Architecture

This composition is made up of three separate containers:

* The web server. We use richarvey/nginx-fpm as our base, then modify it to install ssmtp. However, you can swap it for any server container you like. The only requirement is that the server container meets CiviCRM's requirements and has its web root set to the location in the data container where CiviCRM is installed. By default, that's /buildkit/build/CiviCRM.

* The data container. We use colstrom/ubuntu:fish because we like fish but you can base it on any container which uses apt-get. In the build stage we download the CiviCRM buildkit tools, then we use them to download CiviCRM and your CMS, which is Drupal 7 by default. Then we user composer, npm and bower to install CiviCRM depencencies and finalise the image. In the run stage we patch the installer so that the buildkit doesn't worry about talking directly to the SQL server or configuring vhosts, then we wait for the SQL container to be ready before installing the CiviCRM database. The data container exits at this point, its volumes now ready to be consumed by the web server container.

* The SQL container. We use the official mysql image for this, allowing you to use all of the Docker mysql patterns you are used to. For example:

   $ docker run -it --link some-mysql:mysql --rm mysql sh -c 'exec mysql -h"$MYSQL_PORT_3306_TCP_ADDR" -P"$MYSQL_PORT_3306_TCP_PORT" -uroot -p"$MYSQL_ENV_MYSQL_ROOT_PASSWORD"'
   
Find out more here: https://hub.docker.com/_/mysql/

In theory you could swap this for any database container which provides a database CiviCRM supports. But if you use MySQL, it *must* provide mysql:5.5, not later.

# How to Use

$ git clone https://github.com/djcf/civicrm-docker; cd civicrm-docker

$ docker-compose up

You may want to set up the installation first by configuring docker-compose.yml. In particular, the following environment variables are exposed for you to customise:

    MYSQL_ROOT_PASSWORD: 32720283b5fb32
    MYSQL_DATABASE: civi
    MYSQL_USER: civi
    MYSQL_PASSWORD: f90bff2494d
    WEB_ROOT: /var/www/html
    SITE_NAME: CiviCRM
    SITE_URL: localhost
    SITE_PORT: 80
    ADMIN_PASS: 123
    ADMIN_EMAIL: admin@example.com
    SITE_TYPE=drupal-clean (this is the only one which has been tested)
    PRIVATE_ROOT: /buildkit/app/private

If you use a different web server container, you may need to adjust the file permissions of either the data container or the web server container. The file permissions for the data container are adjustable with the $GID and $UID variables.
    
In theory, you could also change the database type by setting environment variables in the docker-compose file. The environment variables match the ones the buildscript's installation script expects to find.

# To-do

* Rebase off of Alpine linux or -- at the very least -- Debian.

* Test other buildscripts, e.g. D8 and backdrop.