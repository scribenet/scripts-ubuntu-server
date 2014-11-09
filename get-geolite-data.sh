#!/bin/bash
cd /tmp
echo -en "Starting run: "
date
echo "Getting http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz"
wget -q http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz > /dev/null 2>&1
echo "Unzipping GeoLiteCity.dat.gz"
gunzip GeoLiteCity.dat.gz > /dev/null 2>&1
echo "Moving to /www/private/piwik/misc/GeoIPCity.dat"
mv GeoLiteCity.dat /www/private/piwik/misc/GeoIPCity.dat
echo -en "Ending run: "
date
