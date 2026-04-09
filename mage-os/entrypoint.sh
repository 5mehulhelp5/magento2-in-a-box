#!/bin/bash

if [ "$ENABLE_VARNISH" = "true" ]; then
  # When Varnish is enabled, the PHP built-in server needs to listen on port 8080
  # because Varnish will listen on port 80 and proxy to the backend on 8080.
  sed -i 's/0.0.0.0:80/0.0.0.0:8080/' /etc/supervisor/conf.d/webserver.conf
fi

# Comes from the parent image, starts supervisord (mysql, elasticsearch, php-fpm,
# webserver, and optionally varnish when ENABLE_VARNISH=true)
./start-services

if [ "$ENABLE_VARNISH" = "true" ]; then
  php bin/magento config:set system/full_page_cache/caching_application 2
  php bin/magento cache:flush
fi

if [ -n "$URL" ]; then
  php bin/magento config:set web/unsecure/base_url $URL
  php bin/magento config:set web/secure/base_url $URL
  php bin/magento config:set web/unsecure/base_link_url $URL
  php bin/magento config:set web/secure/base_link_url $URL
  php bin/magento cache:flush
fi

# Allow to set the commands in an environment variable
if [[ ! -z "${CUSTOM_ENTRYPOINT_COMMAND}" ]]; then
  echo "${CUSTOM_ENTRYPOINT_COMMAND}" > custom-entrypoint.sh
fi

if [ -f custom-entrypoint.sh ]; then
  bash ./custom-entrypoint.sh
fi

if [ "$FLAT_TABLES" = "true" ]; then
  echo "Enabling Flat Tables"
  php bin/magento config:set catalog/frontend/flat_catalog_category 1
  php bin/magento config:set catalog/frontend/flat_catalog_product 1
  php bin/magento cache:flush
  php bin/magento indexer:reindex
fi

if [ "$DISABLE_2FA" = "true" ] && grep -q Magento_TwoFactorAuth "app/etc/config.php"; then
  echo "Disabling Two Factor Authentication"
  php bin/magento module:disable Magento_TwoFactorAuth -f
fi

while sleep 5; do
  ps aux |grep elasticsearch |grep -q -v grep
  ELASTICSEARCH_STATUS=$?
  ps aux |grep mysqld_safe |grep -q -v grep
  MYSQL_STATUS=$?
  ps aux |grep php |grep -q -v grep
  PHP_STATUS=$?

  if [ $ELASTICSEARCH_STATUS -ne 0 -o $MYSQL_STATUS -ne 0 -o $PHP_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi

  if [ "$ENABLE_VARNISH" = "true" ]; then
    ps aux |grep varnishd |grep -q -v grep
    VARNISH_STATUS=$?
    if [ $VARNISH_STATUS -ne 0 ]; then
      echo "Varnish has exited."
      exit 1
    fi
  fi
done
