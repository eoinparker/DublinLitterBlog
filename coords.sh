#!/bin/bash

# Script to compute the geo-coords of an image
# If it has embedded coords, use them.
# If not, use the supplied street address and look it up 3 ways : Google, Bing, OpenStreetMap
# If 2 of those 3 match, great, if not, ask for human assistence

basedir=$(dirname $BASH_SOURCE)

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

if [ "$#" -lt 3 ] 
then
echo Usage: $0 '<tmp_output_filename>' '<image_filename>' '<address_to_search>'
exit 1
fi

if [ ! -r ${basedir}/bing_oauth_token.txt ] 
then
  echo Warning: the file ${basedir}/bing_oauth_token.txt should exist and be readable.
  echo bing_oauth_token.txt should contain the Microsoft Bing issued OAuth2 token value, as a single value string in a 1 line file. 
  echo Without Bing, Geocode lookups will use anonymous GoogleMaps and OpenStreetMap lookups only,  and so will be less accurate.
fi

bing_oauth_token=$(cat ${basedir}/bing_oauth_token.txt)

tmp_output_filename=$1
image_filename=$2
shift
shift
input_term="$*"

IFS=$SAVEIFS

echo
echo ----------------------------------------
echo Computing Location
longitude=$(exiftool -All -c "%.6f" "${image_filename}" | grep 'GPS Position' | awk '{ print "-"$6 }')
latitude=$(exiftool -All -c "%.6f"  "${image_filename}" | grep 'GPS Position' | awk '{ print $4 }')
echo Embedded latitude,longitude = ${latitude},${longitude}

if [ "${latitude}" != "" ] && [ "${longitude}" != "" ]
then
read -p "Verify in Browser? [n] " open_embed_in_safari
if [ "${open_embed_in_safari}" != "n" ] && [ "${open_embed_in_safari}" != "" ]
then
#open -g -a /Applications/Safari.app https://maps.google.com/maps?q=${latitude},${longitude}
open -g https://maps.google.com/maps?q=${latitude},${longitude}
fi
echo 
read -p "OK to use these co-ords? [y] " use_embedded_gps
if [ "${use_embedded_gps}" == "" ] || [ "${use_embedded_gps}" == "y" ]
then
echo Writing ${coords} to  ${tmp_output_filename}
echo ${latitude},${longitude} > ${tmp_output_filename}
echo latitude ${latitude} >> ${tmp_output_filename}
echo longitude ${longitude} >> ${tmp_output_filename}
exit 0
fi
fi

# Embedded coords not working. Try geocoding on addresss

geocode_timeout=5
search_term="${input_term}"

bing_results=$(geocode -t ${geocode_timeout} -s bing -k "${bing_oauth_token}" "${search_term}")
bing_retval=$?
if [ "${bing_retval}" != "0" ]
then
bing_results=
fi
google_results=$(geocode -t ${geocode_timeout} -s google "${search_term}")
google_retval=$?
if [ "${google_retval}" != "0" ]
then
google_results=
fi
#echo openstreetmap_results=$(geocode -t ${geocode_timeout} -s nominatim "${search_term}")
openstreetmap_results=$(geocode -t ${geocode_timeout} -s nominatim "${search_term}")
#echo WWW ${openstreetmap_results}
openstreetmap_retval=$?
if [ "${openstreetmap_retval}" != "0" ]
then
openstreetmap_results=
fi

# also yandex (russians), geocoder_ca (canadians)

echo GOOGLE [1]
echo ${google_results} 
echo
echo BING [2]
echo ${bing_results} 
echo
echo OPENSTREETMAP [3]
echo ${openstreetmap_results}
echo

google_latitude3=$(echo ${google_results} | awk '{printf ("%.3f",$2); }')
google_longitude3=$(echo ${google_results} | awk '{printf ("%.3f",$4); }')
bing_latitude3=$(echo ${bing_results} | awk '{printf ("%.3f",$2); }')
bing_longitude3=$(echo ${bing_results} | awk '{printf ("%.3f",$4); }')
openstreetmap_latitude3=$(echo ${openstreetmap_results} | awk '{printf ("%.3f",$2); }')
openstreetmap_longitude3=$(echo ${openstreetmap_results} | awk '{printf ("%.3f",$4); }')

google_latitude=$(echo ${google_results} | awk '{printf ("%.6f",$2); }')
google_longitude=$(echo ${google_results} | awk '{printf ("%.6f",$4); }')
bing_latitude=$(echo ${bing_results} | awk '{printf ("%.6f",$2); }')
bing_longitude=$(echo ${bing_results} | awk '{printf ("%.6f",$4); }')
openstreetmap_latitude=$(echo ${openstreetmap_results} | awk '{printf ("%.6f",$2); }')
openstreetmap_longitude=$(echo ${openstreetmap_results} | awk '{printf ("%.6f",$4); }')

if [ "${google_results}" != "" ] && [ "${bing_results}" != "" ] && [ "${google_latitude3}" == "${bing_latitude3}" ] && [ "${google_longitude3}" == "${bing_longitude3}" ]
then
echo BING AND GOOGLE MATCH
coords="${bing_latitude},${bing_longitude}"
elif [ "${openstreetmap_results}" != "" ] && [ "${bing_results}" != "" ] && [ "${bing_latitude3}" == "${openstreetmap_latitude3}" ] && [ "${bing_longitude3}" == "${openstreetmap_longitude3}" ]
then
echo BING AND OSM MATCH
coords="${bing_latitude},${bing_longitude}"
elif [ "${google_results}" != "" ] && [ "${openstreetmap_results}" != "" ] && [ "${google_latitude3}" == "${openstreetmap_latitude3}" ] && [ "${google_longitude3}" == "${openstreetmap_longitude3}" ]
then
echo GOOGLE AND OSM MATCH
coords="${google_latitude},${google_longitude}"
else
# theyve all returned different co-ords
echo ALL 3 HAVE RETURNED DIFFERENT RESULTS
# favour the one which contains the search term
# problems with apostrohpes etc
# echo "hart's corner" | sed -e 's/[^[:alnum:]| ]//g'
#echo "${google_results}" | grep -qi "${input_term}" && coords="${google_latitude},${google_longitude}" && echo "Google contained search term"
#echo "${openstreetmap_results}" | grep -qi "${input_term}" && coords="${openstreetmap_latitude},${openstreetmap_longitude}" && echo "OSM contained search term"
#echo "${bing_results}" | grep -qi "${input_term}" && coords="${bing_latitude},${bing_longitude}" && echo "Bing contained search term"

fi

echo CO-ORDS DECISION: ${coords}
echo

if [ "${coords}" == "" ]
then
while [ "${coords_choice}" == "" ]
do
read -p "Enter your choice of co-ords [1,2 or 3]: " coords_choice
if [ "${coords_choice}" != "1" ] && [ "${coords_choice}" != "2" ] && [ "${coords_choice}" != "3" ]
then
coords_choice=
fi
done
fi

if [ "${coords_choice}" == "1" ]
then
coords="${google_latitude},${google_longitude}"
elif [ "${coords_choice}" == "2" ]
then
coords="${bing_latitude},${bing_longitude}"
elif [ "${coords_choice}" == "3" ]
then
coords="${openstreetmap_latitude},${openstreetmap_longitude}"
fi 

read -p "Verify in Browser ? [y] " open_gps_in_safari
if [ "${open_gps_in_safari}" == "y" ] || [ "${open_gps_in_safari}" == "" ]
then
#open -g -a /Applications/Safari.app https://maps.google.com/maps?q=${coords}
open -g https://maps.google.com/maps?q=${coords}
fi

echo
read -p "Enter new co-ords, or accept the current choice [${coords}]: " new_coords
if [ "${new_coords}" != "" ]
then
coords=${new_coords}
fi

echo ${coords} > ${tmp_output_filename}
echo latitude $(echo ${coords} | tr "," " " | awk ' { print $1; }') >> ${tmp_output_filename}
echo longitude $(echo ${coords} | tr "," " " | awk ' { print $2; }') >> ${tmp_output_filename}


