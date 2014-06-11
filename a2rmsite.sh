#!/bin/bash -
PATH=/bin:/usr/bin:/sbin:/usr/sbin

if [[ -z "$1" ]]
then
  echo "Usage: $0 domain.com"
  exit
fi

if [[ -z "$SUDO_USER" ]]
  then
  echo "Use sudo"
  exit
fi

# The domain being created
DOMAIN=$1
ESCAPED_DOMAIN=${DOMAIN/\./\\\\.}

# This is where we'll create the conf files
APACHE_CONF_DIR="/etc/apache2/sites-available"
LOGROTATE_CONF_DIR="/etc/logrotate.d"
LOGROTATE_SITES_DIR="$LOGROTATE_CONF_DIR/sites.d"

# These are the conf files
APACHE_CONF="$APACHE_CONF_DIR/$DOMAIN"
LOGROTATE_CONF="$LOGROTATE_SITES_DIR/$DOMAIN.conf"

# This is where the site itself will be created
SITES_DIR="/var/www/sites"
SITE_DIR="$SITES_DIR/$DOMAIN"
REMOVED_SITE_DIR="$SITES_DIR/$DOMAIN.removed"

# FUNCTIONS ==========================================================

function mv_site {
  [[ -d $SITE_DIR ]]
  echo "Renaming $SITE_DIR to $REMOVED_SITE_DIR..."
  mv "$SITE_DIR" "$REMOVED_SITE_DIR"
  echo "done!"
}

function rm_apache_conf {
  echo "Removing apache config file: $APACHE_CONF..."
  rm "$APACHE_CONF"
  echo "done!"
}

function rm_logrotate_conf {
  echo "Removing logrotate config file: $FILE..."
  "$LOGROTATE_CONF"
  echo "done!"
}

# Disable stuff ==========================================

echo "Disablinig Site..."
/usr/sbin/a2dissite $DOMAIN
echo "Restarting Apache..."
/usr/sbin/apache2ctl graceful

# Run those functions ====================================

if [[ -f "$APACHE_CONF" ]]
  then
  read -p "Remove $APACHE_CONF? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
    then
    rm_apache_conf
  fi
fi

if [[ -f "$LOGROTATE_CONF" ]]
  then
  read -p "Remove $LOGROTATE_CONF? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
    then
    rm_logrotate_conf
  fi
fi

if [[ -d "$SITE_DIR" ]]
  then
  mv_site
fi

# FINISH UP ==================================
echo "ALL DONE!"
