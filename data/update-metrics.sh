#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# -------------------------------------------------------------------------------------------------
# V A R I A B L E S
# -------------------------------------------------------------------------------------------------

###
### Program name
###
NAME="update-metrics.sh"


# -------------------------------------------------------------------------------------------------
# F U N C T I O N S
# -------------------------------------------------------------------------------------------------

###
### Function called by trap
###
do_this_on_ctrl_c(){
    exit 0
}


# -------------------------------------------------------------------------------------------------
# E N T R Y P O I N T
# -------------------------------------------------------------------------------------------------

###
### Add Trap for Ctrl+c
###
trap 'do_this_on_ctrl_c' SIGINT


###
### How often to update the metrics
###
if env | grep -q '^UPDATE_TIME='; then
	UPDATE_TIME="$( env | grep '^UPDATE_TIME=' | sed 's/^UPDATE_TIME=//g' )"
else
	UPDATE_TIME=60
fi


###
### Update metrics endlessly
###
while true; do
	sleep "${UPDATE_TIME}"
	START=$(date +%s)
	if /usr/bin/aws-ec2-sg-exporter > /var/www/index.html.new; then
		END=$(date +%s)
		mv -f /var/www/index.html.new /var/www/index.html
		printf "[OK]  %s (%s): %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "${NAME}" "Metrics updated in $(( ${END} - ${START} )) sec"
	else
		END=$(date +%s)
		>&2 printf "[ERR] %s (%s): %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "${NAME}" "Failed to update metrics after $(( ${END} - ${START} )) sec"
		false
	fi
done
