#!/bin/bash

# Worker script that processes one single image into a FixYourStreet.ie report, and uploads it.
# To be valid, a FixYourStreet incident report requires
# -- image (scaled down if necessary, max size 1MB)
# -- Accurate Geo co-ordinates
# -- Accurate timestamp
# -- Text description

basedir=$(dirname $BASH_SOURCE)

set -m

echo
echo -----------------------------------------
echo Processing Single Picture into FYS report
echo -----------------------------------------
echo
if [ $# -ne 5 ] && [ $# -ne 6 ]
then
echo Usage: $0 input_image output_image_filename DLB_Script randifier index [global_image_title]
exit 1
fi

#read -p "Process this image into FYS report? [y] " process_into_fys_report
#if [ "${process_into_fys_report}" != "" ] && [ "${process_into_fys_report}" != "y" ]
#then
#echo Skipping ...
#exit 0
#fi



SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

filename=$1
postprocessed_filename=$2
dlb_script=$3
randifier=$4
index=$5
global_image_title=$6

stored_coords_filename=outcoords${randifier}.txt

echo
echo Filename: ${filename}
echo



if [ "${global_image_title}" == "" ]
then
title=$(basename "${filename}")
dir=$(dirname "${filename}")
extension="${title##*.}"
title="${title%.*}"
echo Extracted Title [i.e location] : ${title}
else
title=${global_image_title}
echo Using Title [i.e location] : ${title}
fi

echo
read -p "Enter new title/location, or return to accept extracted value: " newtitle
if [ "${newtitle}" != "" ]
then
title=${newtitle}
fi

location=${title}

# first, convert whatever format it is, to jpeg
sips -s format jpeg ${filename} --out ${postprocessed_filename}
# rm ${filename}

IFS=$SAVEIFS

chmod 777 ${postprocessed_filename}

echo
echo Extracting Photo Time
year=$(exiftool -All  ${postprocessed_filename} | grep -m 1 'Create Date' | awk  ' { print $4;} ' | awk -F':' ' { print $1;}')
month=$(exiftool -All ${postprocessed_filename} | grep -m 1 'Create Date' | awk  ' { print $4;} ' | awk -F':' ' { print $2}')
date=$(exiftool -All  ${postprocessed_filename} | grep -m 1 'Create Date' | awk  ' { print $4;} ' | awk -F':' ' { print $3;}')
hour=$(exiftool -All  ${postprocessed_filename} | grep -m 1 'Create Date' | awk  ' { print $5;} ' | awk -F':' ' { print $1;}')
minute=$(exiftool -All  ${postprocessed_filename} | grep -m 1 'Create Date' | awk  ' { print $5;} ' | awk -F':' ' { print $2;}')
 
if [ "${hour}" != "" ]
then
if [ ${hour} -lt 12 ]; then ampm=am; else ampm=pm; fi
if [ ${hour} -gt 11 ]; then hour= expr ${hour}-12; fi
fi

echo
echo year,month,date,hour,minute,ampm = ${year},${month},${date},${hour},${minute},${ampm}

echo
if [ "${hour}" == "" ]
then
  read -p 'Overwrite this with today, 9am? [y] ' overwrite_time
  if [ "${overwrite_time}" == "y" ] || [ "${overwrite_time}" == "" ]
  then
    do_overwrite_time=y
  fi
else
  read -p 'Overwrite this with today, 9am? [n] ' overwrite_time
  if [ "${overwrite_time}" == "y" ]
  then
    do_overwrite_time=y
  fi
fi

if [ "${do_overwrite_time}" == "y" ] 
then
year=$(date "+%Y")
month=$(date "+%m")
date=$(date "+%d")
hour=9
minute=0
ampm=am
fi


months=(Unknown Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

# year=$(date "+%Y") # some cameras set it incorrectly to last year
if [ "${month}" != "" ] && [ "${date}" != "" ] && [ "${hour}" != "" ] && [ "${minute}" != "" ]
then
incident_time="-F incident_date=${month}/${date}/${year} -F incident_hour=${hour} -F incident_minute=${minute} -F incident_ampm=${ampm}"
trimmed_month=$(expr $month)
dublin_litter_blog_title_date="${months[$trimmed_month]} ${date} ${year}"
else
# it's required for FixYourStreet so set it to today, 9am
incident_time="-F incident_date=$(date "+%m/%d/%Y") -F incident_hour=9 -F incident_minute=0 -F incident_ampm=am"
dublin_litter_blog_title_date="${months[$(date "+%m")]} $(date "+%d") $(date "+%Y")"
fi
echo
echo incident_time: ${incident_time}

fix_your_street_title="${title}. Reported from DublinLitterBlog.com to FixYourStreet.ie"
echo
echo Using FixYourStreet Post Title: ${fix_your_street_title}

cat >> ${dlb_script} <<EOM

old_dlb_title="\${dublin_litter_blog_title}"
dublin_litter_blog_title_date="${dublin_litter_blog_title_date}"
dublin_litter_blog_title="${title}"
if [ "\${old_dlb_title}" != "" ]
then
delimiter=". "
fi
if [[ "\${old_dlb_title}" == *"\${dublin_litter_blog_title}"* ]] && [[ "\${old_dlb_title}" != *"Selection"* ]]
then
dublin_litter_blog_title=\$(echo "\${old_dlb_title}" | sed "s/\${dublin_litter_blog_title}/\${dublin_litter_blog_title} Selection/g")
else
dublin_litter_blog_title="\${old_dlb_title}\${delimiter}\${dublin_litter_blog_title}"
fi
EOM

#################

${basedir}/coords.sh "${stored_coords_filename}" "${postprocessed_filename}" "${location},dublin,ireland"
latitude=$(grep latitude ${stored_coords_filename} | awk '{ print $2 }')
longitude=$(grep longitude ${stored_coords_filename} | awk '{ print $2 }')

latitude_longitude="-F latitude=${latitude} -F longitude=${longitude}" 
echo
echo latitude_longitude: ${latitude_longitude}

##################
echo
echo GIMP scrubbing
echo --------------------
paintbrush=n
read -p "Open in GIMP? [n]" paintbrush
if [ "${paintbrush}" == "y" ]
then
echo Opening
# sudo killall GIMP
# sudo /Applications/GIMP.app/Contents/MacOS/GIMP ${postprocessed_filename} &
open -a GIMP ${postprocessed_filename} 
# osascript -e 'tell app "GIMP" to activate' ; fg
sips -s format jpeg ${postprocessed_filename} --out file_tmp.jpg
chmod 777 ${postprocessed_filename}
mv file_tmp.jpg ${postprocessed_filename}
fi

rotate=y
while [ "${rotate}" == "y" ]
do
read -p "Rotate ${postprocessed_filename} by 90? [n]" rotate
if [ "${rotate}" == "y" ]
then
echo Rotating
sips -r 90 ${postprocessed_filename}
fi
done

# reformtting as low quality jpg keeps the file size at a minimum and
# doesn't affect the quality that much either. 800x600 at low quality is roughly 50K
filesize=$(stat -f "%z" ${postprocessed_filename})
if [ ${filesize} -gt 1000000 ]
then
reformat=y
read -p "Filesize=${filesize}. Reformat JPG to low quality ? [y]" reformat_tmp
if [ "${reformat_tmp}" == "n" ]
then
reformat=n
fi
else
reformat=n
read -p "Filesize=${filesize}. Reformat JPG to low quality ? [n]" reformat_tmp
if [ "${reformat_tmp}" == "y" ]
then
reformat=y
fi
fi

if [ "${reformat}" == "y" ] 
then
echo Reformatting
sips -Z 800 --setProperty format jpeg --setProperty formatOptions normal ${postprocessed_filename} --out file_tmp.jpg
mv file_tmp.jpg ${postprocessed_filename}
chmod 777 ${postprocessed_filename}
fi

strip=n
read -p "Strip embedded EXIF tags ? [n]" strip
if [ "${strip}" == "y" ]
then
echo Stripping
exiftool -overwrite_original -all= -tagsFromFile @ -title -Orientation ${postprocessed_filename}
fi


echo
read -p "Enter FixYourStreet post description [optional]: See photo. " description

if [ "${description}" == "" ]
then
#fys_date=$(date "+%Y/%m/%d")
description="${title} - ${dublin_litter_blog_title_date}"
fi
description="See photo. ${description}"

echo Using description: ${description}
echo


echo
read -p "Graffiti ? [n] " is_graffiti
if [ "${is_graffiti}" == "y" ] 
then
fys_category=1
else
fys_category=6
fi

echo
fixyourstreet=y
read -p "Upload to FixYourStreet? [y] " fixyourstreet

if [ "${no_location_found}" == "true" ]
then
fixyourstreet_description="NB: Could not locate on map, please use text address.  ${description}"  
else
fixyourstreet_description=${description}
fi




if [ "${fixyourstreet}" == "y" ] || [ "${fixyourstreet}" == "" ]
then
curl -v -F 'task=report' -F "incident_title=${fix_your_street_title}" -F "incident_description=${fixyourstreet_description}" ${incident_time} -F "incident_category=${fys_category}" ${latitude_longitude}  -F "incident_photo[]=@${postprocessed_filename};filename=${postprocessed_filename};type=image/jpeg" -F "location_name=${filename}" -F "person_first=Admin" -F "person_last=DublinLitterBlog" -F "person_email=admin@dublinlitterblog.com" http://fixyourstreet.ie/api
# curl -v -F 'task=report' -F "incident_title=${fix_your_street_title}" -F "incident_description=${fixyourstreet_description}" ${incident_time} -F "incident_category=${fys_category}" ${latitude_longitude}  -F "incident_photo[]=@${postprocessed_filename};filename=${postprocessed_filename};type=image/jpeg" -F "location_name=${filename}" -F "person_first=Admin" -F "person_last=DublinLitterBlog" -F "person_email=admin@dublinlitterblog.com" http://fixyourstreet.ie/api
echo report_count=\"\$\(expr \${report_count} + 1\)\" >> ${dlb_script}
fi

if [ "${index}" == "1" ]
then
better_filename=$(echo ${title}-${dublin_litter_blog_title_date} | sed -e 's/[ ,.-]/_/g' | sed -e 's/___/_/g' | sed -e 's/__/_/g' | sed -e 's/^_//g' | sed -e 's/_$//g').jpg
else 
better_filename=$(echo ${title}-${dublin_litter_blog_title_date}-#${index} | sed -e 's/[ ,.-]/_/g' | sed -e 's/___/_/g' | sed -e 's/__/_/g' | sed -e 's/^_//g' | sed -e 's/_$//g').jpg
fi
echo Using BetterFilename : ${better_filename}

cp ${postprocessed_filename} ${better_filename}
echo dlb_media_string=\"\${dlb_media_string} -F media[]=@${better_filename}\" >> ${dlb_script}
echo better_filenames=\"\${better_filenames} ${better_filename}\" >> ${dlb_script}


