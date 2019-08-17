#!/usr/bin/env bash

# Be strict
set -e
set -u
set -o pipefail


###
### Create metrics before starting up anything
###
START=$(date +%s)
if /usr/bin/aws-ec2-sg-exporter > /var/www/index.html.new; then
	END=$(date +%s)
	mv -f /var/www/index.html.new /var/www/index.html
	printf "[OK]  %s (%s): %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "docker-entrypoint.sh" "Metrics updated in $(( ${END} - ${START} )) sec"
else
	END=$(date +%s)
	>&2 printf "[ERR] %s (%s): %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "docker-entrypoint.sh" "Failed to update metrics after $(( ${END} - ${START} )) sec"
	exit 1
fi


###
### Start up
###
exec /usr/bin/supervisord -c /etc/supervisord.conf
