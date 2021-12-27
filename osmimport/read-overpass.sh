#!/bin/bash
echo "DB gis1 configuration, if it does not exist"
createdb -Upostgres -E UTF-8 gis1 && psql -Upostgres -d gis1 -c "CREATE EXTENSION postgis"

cd /work/maps/osmimport
curl --insecure --fail-with-body --silent  --show-error -d @overpass-infra.txt https://www.overpass-api.de/api/interpreter > /data/data-overpass-infra.osm.new
if [ $(stat -c%s /data/data-overpass-infra.osm.new) -gt 5000 ] ; then
    mv /data/data-overpass-infra.osm.new /data/data-overpass-infra.osm
else
    echo `date` FAIL
    cat /data/data-overpass-infra.osm.new 
    mv /data/data-overpass-infra.osm.new $(mktemp /data/error_XXXXXX)
    exit 1;
fi
echo `date` attempting to geojson
osmtogeojson /data/data-overpass-infra.osm > /data/data-overpass-infra.geo.json
osmconvert /data/data-overpass-infra.osm -o=/data/data-overpass-infra.osm.pbf
osm2pgsql -Upostgres --style osm2pgsql.style --slim --drop -d gis1 -c /data/data-overpass-infra.osm.pbf
psql -Upostgres -t -A -d gis1 -f lot_limits.sql >  /data/lot_limits.json

# send the USR2 signal to the rendering container, so the "infra" tiles are removed because they are stale
# see docker-mapnik/start.sh
kill -s USR2 1

echo `date` finished