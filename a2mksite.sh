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

CHOICES="Overwrite Skip"

# The domain being created
DOMAIN=$1
ESCAPED_DOMAIN=${DOMAIN/\./\\\\.}

# This directory holds the templates for the apache and logrotate conf files
DEFAULT_TEMPLATE_DIR="$(dirname $0)/templates"
USER_TEMPLATE_DIR="/home/$SUDO_USER/a2mksite_templates"

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
PUBLIC_DIR="$SITE_DIR/public"
LOG_DIR="$SITE_DIR/log"

# FUNCTIONS ==========================================================

function mk_site {
  [[ ! -d $SITE_DIR ]] || rm -R "$SITE_DIR"
  echo "Creating $PUBLIC_DIR..."
  mkdir -p "$PUBLIC_DIR"
  echo "done!"
  if [[ -d $PUBLIC_TEMPLATE ]]
    then
    echo "Copying public $PUBLIC_TEMPLATE to $SITE_DIR..."
    cp -Rp "$PUBLIC_TEMPLATE" "$SITE_DIR"
    echo "done!"
  fi
  chown -R $SUDO_USER:$SUDO_GID "$SITE_DIR"
}

function mk_logs {
  if [[ ! -d $LOG_DIR ]]
    then
    echo "Creating log dir: $LOG_DIR..."
    mkdir "$LOG_DIR"
    echo "done!"
  fi
  
  touch "$LOG_DIR/access_log"
  touch "$LOG_DIR/error_log"

  echo "Chowning log dir to root..."
  chown -R 0:$SUDO_GID "$LOG_DIR"
  echo "done!"

  echo "Chmoding log dir to 1750..."
  chmod -R 750 "$LOG_DIR"
  chmod 1750 "$LOG_DIR"
  echo "done!"
}

function mk_apache_conf {
  echo "Creating apache config file: $APACHE_CONF..."
  sed -e "s:LOG_DIR:$LOG_DIR:g"\
      -e "s:SITE_DIR:$SITE_DIR:g"\
      -e "s:USER:$SUDO_USER:g"\
      -e "s:GROUP:$SUDO_GID:g"\
      -e "s:ESCAPED_DOMAIN:$ESCAPED_DOMAIN:g"\
      -e "s:THE_DOMAIN:$DOMAIN:g"\
      "$APACHE_TEMPLATE" > "$APACHE_CONF"
  echo "done!"

  echo "Chowning apache config file to root..."
  chown 0:$SUDO_GID "$APACHE_CONF"
  echo "done!"

  echo "Chmoding apache config file to 740..."
  chmod 740 "$APACHE_CONF"
  echo "done!"
}

function mk_logrotate_conf {
  echo "Creating logrotate config file: $FILE..."
  sed -e "s:LOG_DIR:$LOG_DIR:g" "$LOGROTATE_TEMPLATE" > "$LOGROTATE_CONF"
  echo "done!"

  echo "Chowning logrotate config file to root..."
  chown 0:$SUDO_GID "$LOGROTATE_CONF"
  echo "done!"

  echo "Chmoding logrotate file to 740..."
  chmod 740 "$LOGROTATE_CONF"
  echo "done!"
}

# Determine template directories ========================

# Choose the user's public/ template first
# If it doesn't exist, use the default
if [[ -d "$USER_TEMPLATE_DIR/public" ]]
  then PUBLIC_TEMPLATE="$USER_TEMPLATE_DIR/public"
elif [[ -d "$DEFAULT_TEMPLATE_DIR/public" ]]
  then PUBLIC_TEMPLATE="$DEFAULT_TEMPLATE_DIR/public"
else
  echo "No public/ template can be found. Aborted."
  exit
fi

# Choose the user's apache.conf template first
# If it doesn't exist, use the default
if [[ -f "$USER_TEMPLATE_DIR/apache.conf" ]]
  then APACHE_TEMPLATE="$USER_TEMPLATE_DIR/apache.conf"
elif [[ -f "$DEFAULT_TEMPLATE_DIR/apache.conf" ]]
  then APACHE_TEMPLATE="$DEFAULT_TEMPLATE_DIR/apache.conf"
else
  echo "No apache.conf template can be found. Aborted."
  exit
fi

# Choose the user's logrotate.conf template first
# If it doesn't exist, use the default
if [[ -f "$USER_TEMPLATE_DIR/logrotate.conf" ]]
  then LOGROTATE_TEMPLATE="$USER_TEMPLATE_DIR/logrotate.conf"
elif [[ -f "$DEFAULT_TEMPLATE_DIR/apache.conf" ]]
  then LOGROTATE_TEMPLATE="$DEFAULT_TEMPLATE_DIR/logrotate.conf"
else 
  echo "No logrotate.conf template can be found. Aborted."
  exit
fi

# Create necessary directories ==========================

if [[ ! -d "$APACHE_CONF_DIR" ]]
  then 
  mkdir -p "$APACHE_CONF_DIR"
  chgrp $SUDO_GID "$APACHE_CONF_DIR"
fi
if [[ ! -d "$LOGROTATE_SITES_DIR" ]]
  then 
  mkdir -p "$LOGROTATE_SITES_DIR"
  chgrp $SUDO_GID "$LOGROTATE_SITES_DIR"
fi
if [[ ! -d "$SITES_DIR" ]]
  then 
  mkdir -p "$SITES_DIR"
  chown $SUDO_USER:$SUDO_GID "$SITES_DIR"
fi

# Create logrotate conf file for all sites ===============

if [[ ! -f "$LOGROTATE_CONF_DIR/sites" ]]
  then
  echo "include $LOGROTATE_SITES_DIR" > "$LOGROTATE_CONF_DIR/sites"
  chgrp $SUDO_GID "$LOGROTATE_CONF_DIR/sites"
fi
  

# Run those functions ====================================

if [[ -d "$SITE_DIR" ]] 
  then
  echo "$SITE_DIR already exists..."
  select choice in $CHOICES; do
    if [ $choice ]; then
      case $choice in
        Overwrite)
          mk_site
          break;;
        Skip) break;;
        esac
    else
      echo 'Invalid selection'
    fi
  done
else
  mk_site
fi

mk_logs

if [[ -f "$APACHE_CONF" ]] 
  then
  echo "$APACHE_CONF already exists..."
  select choice in $CHOICES; do
    if [ $choice ]; then
      case $choice in
        Overwrite)
          mk_apache_conf
          break;;
        Skip) break;;
        esac
    else
      echo 'Invalid selection'
    fi
  done
  else
  mk_apache_conf
fi

if [[ -f "$LOGROTATE_CONF" ]] 
  then
  echo "$LOGROTATE_CONF already exists..."
  select choice in $CHOICES; do
    if [ $choice ]; then
      case $choice in
        Overwrite)
          mk_logrotate_conf
          break;;
        Skip) break;;
        esac
    else
      echo 'Invalid selection'
    fi
  done
  else
  mk_logrotate_conf
fi


# FINISH UP ==================================
echo "Enabling Site..."
/usr/sbin/a2ensite $DOMAIN
echo "Restarting Apache..."
/usr/sbin/apache2ctl graceful
echo "ALL DONE!"
