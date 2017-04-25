#!/bin/bash

# Helper script called by the main control one. Computes publication time.
# Takes care of:
# - timezones & DST
# - random minutes value if the human specifies an hour
# - immediate publication, with 5 minute grace period
# Twitter, Facebook & Wordpress analytics show that the best time for publication is 7pm -> 10pm GMT.
# Maximises views.  Also good to stagger the posts.

if [ $# -ne 1 ]
then
echo Usage: $0 '<dlb_output_script>'
exit 1
fi

dlb_script=$1

publication_timezone=Europe/Dublin
echo Using publication timezone: ${publication_timezone}

echo
echo ----------------
echo Publication Time
echo ----------------
echo
echo "Enter hour [date] for publication. 08 25 means 8am on the 25th. 14 means 2pm, no date. Minutes are random." 
echo "Or, press return to publish 5 minutes from now." 
echo

while [ "${publication_time_ok}" == "" ]
do
read -p "Enter publication hour [date] or press Return: " publication_date_hour
if [ "${publication_date_hour}" == "" ]
then
#publication_datetime=$(date -j -u -v "+5M" "+%Y-%m-%dT%H:%MZ")
publication_datetime=$(TZ=${publication_timezone} date -j -v "+5M" "+%Y-%m-%dT%H:%M%z")
human_readable_publication_datetime=$(TZ=${publication_timezone} date -j -v "+5M" "+%d %B %Y %H:%M")
twitter_friendly_publication_datetime=$(TZ=${publication_timezone} date -j -v "+5M" "+%b%d %H:%M")
else
publication_hour=$(echo ${publication_date_hour} | tr "," " " | awk '{print $1;}')
publication_date=$(echo ${publication_date_hour} | tr "," " " | awk '{print $2;}')

if [ "${publication_date}" == "" ]
then
publication_date=$(TZ=${publication_timezone} date "+%d")
fi

if [ "${publication_hour}" == "" ]
then
publication_date=$(TZ=${publication_timezone} date "+%H")
fi
publication_minutes=$(expr $RANDOM % 60)
publication_datetime=$(TZ=${publication_timezone} date "+%Y-%m-")${publication_date}T${publication_hour}:${publication_minutes}$(TZ=${publication_timezone} date "+%z")
human_readable_publication_datetime=${publication_date}$(TZ=${publication_timezone} date "+ %B %Y ")${publication_hour}:${publication_minutes}
twitter_friendly_publication_datetime=$(TZ=${publication_timezone} date "+%b")${publication_date}$(echo " ")${publication_hour}:${publication_minutes}
fi

read -p "Using publication_datetime : ${publication_datetime}   OK? [y] " publish_time_accepted

if [ "${publish_time_accepted}" == "" ] || [ "${publish_time_accepted}" == "y" ]
then
publication_time_ok=y
fi


done

echo publication_datetime=\"${publication_datetime}\" >> ${dlb_script}
echo human_readable_publication_datetime=\"${human_readable_publication_datetime}\" >> ${dlb_script}
echo twitter_friendly_publication_datetime=\"${twitter_friendly_publication_datetime}\" >> ${dlb_script}
exit 0

