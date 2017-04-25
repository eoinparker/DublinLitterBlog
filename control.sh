#!/bin/bash 

# Main entrypoint.  This script invokes all the other ones repeatedly.
# Operates by building a temporary script dedicated to the current collection of images (usually there's just one),
# and calling it.

clear

if [ $# -lt 1 ]
then
echo Usage: $0 pic1 [pic2 ... ]
exit 1
fi

basedir=$(dirname $BASH_SOURCE)

if [ ! -r ${basedir}/wordpress_oauth_token.txt ] || [ ! -r ${basedir}/wordpress_rest_endpoint.txt ]
then
  echo The 2 files ${basedir}/wordpress_oauth_token.txt and ${basedir}/wordpress_rest_endpoint.txt must both exist and be readable.
  echo wordpress_oauth_token.txt must contain the Wordpress issued OAuth2 token,  typically a 64 char ASCII string.
  echo wordpress_rest_endpoint.txt should contain a URL like https://public-api.wordpress.com/rest/v1/sites/dublinlitterblog.wordpress.com
  exit 1
fi

wordpress_oauth_token=$(cat ${basedir}/wordpress_oauth_token.txt)
wordpress_rest_endpoint=$(cat ${basedir}/wordpress_rest_endpoint.txt)


if [ $# -gt 1 ]
then
read -p "Enter a global image title [optional]: " global_image_title
fi

randifier=$RANDOM

dlb_script=./dlb${randifier}.sh
rm -f ${dlb_script}
echo "#!/bin/bash" > ${dlb_script}

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
echo global_image_title=\"${global_image_title}\" >> ${dlb_script}
echo image_count=$# >> ${dlb_script}
echo report_count=0 >> ${dlb_script}
index=0
filename_uid=file${randifier}

for filename in $*
do
echo $filename
index=$(expr ${index} + 1)
postprocessed_filename=${filename_uid}${index}.jpg
${basedir}/process.sh ${filename} ${postprocessed_filename} ${dlb_script} ${randifier} ${index} ${global_image_title}
done

IFS=$SAVEIFS

clear

echo
echo ------------------------------------------------ 
echo Creating DublinLitterBlog Post, using all images
echo ------------------------------------------------

${basedir}/publication_time.sh ${dlb_script}


cat >> ${dlb_script} <<EOF

if [ "\${global_image_title}" != "" ]
then
dublin_litter_blog_title="\${global_image_title}"
fi


echo
echo ----------------------------------
echo Using DublinLitterBlog Post Title . Date :  \${dublin_litter_blog_title}. \${dublin_litter_blog_title_date}
echo ----------------------------------
echo
read -p "Enter a new TITLE TITLE TITLE [optional]: " new_title
if [ "\${new_title}" != "" ]
then
dublin_litter_blog_content=\${dublin_litter_blog_title}
dublin_litter_blog_title="\${new_title}"
fi

echo
echo -------------------
echo Punchline
echo -------------------
echo
read -p "Enter a punchline [optional]: " punchline
if [ "\${punchline}" != "" ]
then
dublin_litter_blog_title="\${punchline} -> \${dublin_litter_blog_title}"
fi


echo
echo ------------------------------------
echo Using DublinLitterBlog Post Content:  \${dublin_litter_blog_content}
echo ------------------------------------
echo
read -p "Enter new content [optional]: " new_content
if [ "\${new_content}" != "" ]
then
dublin_litter_blog_content="\${new_content}"
fi

echo
echo ----
echo TAGS
echo ----
echo
echo 0=vermin, 1=dumping, 2=domestic, 3=loose litter
echo 4=bulky waste, 5=electrical, 6=hazard, 7=dog fouling
echo 8=privatisation, 9=tagged but rejected, 10=tagged but uncollected
echo 11=rogue landlord, 12=derelict or vacant property, 13=commercial
echo 14=graffiti, 15=anti-social \& anti-neighbour, 16=funny, 17=good news
echo
builtin_tags=("vermin" "dumping" "domestic" "loose litter" "bulky waste" "electrical" "hazard" "dog fouling" "privatisation" "tagged but rejected" "tagged but uncollected" "rogue landlord" "derelict or vacant property" "commercial" "graffiti" "anti-social & anti-neighbour" "funny" "good news")
echo 
read -p "Enter tag indices [optional, comma separated]: " tags_indices             
for i in \$(echo \${tags_indices} | tr "," "\n")
do
tags="\${tags}\${comma}\${builtin_tags[\${i}]}"
comma=","
done

echo Using tags: \${tags}

echo
echo ---------------
dublinlitterblog=y
read -p "Upload to DublinLitterBlog? [y] " dublinlitterblog
echo ---------------

if [ "\${dublinlitterblog}" == "y" ] || [ "\${dublinlitterblog}" == "" ]
then
if [ "\${image_count}" == "1" ]
then
curl -v -F "format=image" -F "title=\${dublin_litter_blog_title}. \${dublin_litter_blog_title_date}" -F "content=\${dublin_litter_blog_content}" -F "status=schedule" -F "date=\${publication_datetime}" -F "tags=\${tags}"  \${dlb_media_string} -H 'Authorization: Bearer ${wordpress_oauth_token}' '${wordpress_rest_endpoint}/posts/new' > new_post${randifier}.json 2>/dev/null
else
curl -v -F "format=image" -F "title=\${dublin_litter_blog_title}. \${dublin_litter_blog_title_date}" -F "content=\${dublin_litter_blog_content}" -F "status=schedule" -F "date=\${publication_datetime}" -F "tags=\${tags}"  \${dlb_media_string} -H 'Authorization: Bearer ${wordpress_oauth_token}' '${wordpress_rest_endpoint}/posts/new' > new_post${randifier}.json 2>/dev/null
fi
fi

# echo
# echo -------------------
# echo NEW_POST_JSON:
# cat new_post${randifier}.json
# echo

echo
echo ---------------
echo SETTING THE FEATURED IMAGE 

new_post_attachment0_id=\$(cat new_post${randifier}.json  | jsawk 'var atts = this.attachments ; min_prop=100000000 ; for (var prop in atts) if (prop < min_prop) min_prop=prop; return atts[min_prop]["ID"]')
new_post_ID=\$(cat new_post${randifier}.json  | jsawk 'return this["ID"]' )

echo
echo SETTING ATTACHMENT_ID \$new_post_attachment0_id onto POST_ID \$new_post_ID
curl -X POST -H 'Authorization: Bearer ${wordpress_oauth_token}' --data-urlencode featured_image=\${new_post_attachment0_id} ${wordpress_rest_endpoint}/posts/\${new_post_ID} > /dev/null 2>&1


echo
echo -------------------
echo Updating Counters...
echo

current_image_count=\$(curl -H 'Authorization: Bearer ${wordpress_oauth_token}' '${wordpress_rest_endpoint}/posts/2788' 2>/dev/null |  jsawk -n 'out(this.title)' | awk ' {print \$1;}')
echo
echo "Current Image Count: \${current_image_count}"
new_image_count=\$(expr \${current_image_count} + \${image_count} ) 
echo
echo "New Image Count: \${new_image_count}"

current_post_count=\$(curl -H 'Authorization: Bearer ${wordpress_oauth_token}' '${wordpress_rest_endpoint}/posts/2797' 2>/dev/null |  jsawk -n 'out(this.title)' | awk ' {print \$1;}')
echo
echo "Current Post Count: \${current_post_count}"
new_post_count=\$(expr \${current_post_count} + 1)
echo
echo "New Post Count: \${new_post_count}"

current_report_count=\$(curl -H 'Authorization: Bearer ${wordpress_oauth_token}' '${wordpress_rest_endpoint}/posts/2799' 2>/dev/null |  jsawk -n 'out(this.title)' | awk ' {print \$1;}')
echo
echo "Current Report Count: \${current_report_count}"
new_report_count=\$(expr \${current_report_count} + \${report_count})
echo
echo "New Report Count: \${new_report_count}"

echo
echo ---------------
echo PUBLICATION TIME AND TWITTER RESPONSE
echo
echo \${human_readable_publication_datetime}
echo
echo Thx,incident rprtd for cleanup.Also set for publish on dublinlitter.com,Em,FB\& Tw @ \${twitter_friendly_publication_datetime}
echo


update_counters=y
echo
#read -p "Update Counters? [y] " update_counters
echo ---------------

if [ "\${update_counters}" == "y" ] || [ "\${update_counters}" == "" ]
then
curl -H 'Authorization: Bearer ${wordpress_oauth_token}' '${wordpress_rest_endpoint}/posts/2788' -F "title=\${new_image_count} Photos" > /dev/null 2>&1
curl -H 'Authorization: Bearer ${wordpress_oauth_token}' '${wordpress_rest_endpoint}/posts/2797' -F "title=\${new_post_count} Incidents" > /dev/null 2>&1
curl -H 'Authorization: Bearer ${wordpress_oauth_token}' '${wordpress_rest_endpoint}/posts/2799' -F "title=\${new_report_count} Clean-up Reports" > /dev/null 2>&1
fi

echo
echo ---------------
echo PUBLICATION TIME AND TWITTER RESPONSE
echo
echo \${human_readable_publication_datetime}
echo
echo Thx,incident rprtd for cleanup.Also set for publish on dublinlitter.com,Em,FB\& Tw @ \${twitter_friendly_publication_datetime}
echo

echo
echo -------
echo CleanUp
echo -------
echo
deletepostprocessedfile=y
read -p "Delete Postprocessed Files ? [y] " deletepostprocessedfile
if [ "${deletepostprocessedfile}" == "y" ] || [ "${deletepostprocessedfile}" == "" ]
then
rm *${randifier}*
echo deleting BetterFilenames \${better_filenames}
rm \${better_filenames}
fi

EOF

chmod 777 ${dlb_script}

${dlb_script}


SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

echo
deleteinputfiles=y
read -p "Delete Original Input Images ? [y] " deleteinputfiles
if [ "${deleteinputfiles}" == "y" ] || [ "${deleteinputfiles}" == "" ]
then
rm $*
fi

IFS=$SAVEIFS
