#!/bin/bash

# One-time script to fix image rendering problems within posts when Wordpress changed the rules
# New rule: every post must have a Featured Image explicitly set.

if [ ! -r wordpress_oauth_token.txt || ! -r wordpress_rest_endpoint.txt ]
then
echo The 2 files wordpress_oauth_token.txt and wordpress_rest_endpoint.txt must both exist and be readable.
echo wordpress_oauth_token.txt must contain the Wordpress issued OAuth2 token,  typically a 64 char ASCII string.
echo wordpress_rest_endpoint.txt should contain a URL like https://public-api.wordpress.com/rest/v1/sites/dublinlitterblog.wordpress.com
exit 1
fi

wordpress_oauth_token=$(cat wordpress_oauth_token.txt)
wordpress_rest_endpoint=$(cat wordpress_rest_endpoint.txt)


if [ $# -lt 1 ]
then
echo Usage: $0 <offset_value> 
exit 1
fi

offset=$1
echo OFFSET : $offset

function rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}


post_id=$(curl -H 'Authorization: Bearer ${wordpress_oauth_token}' "${wordpress_rest_endpoint}/posts?pretty=true&number=1&order=ASC&offset=${offset}"  | jsawk 'return this.posts[0]["ID"]')

post_title=$(curl -H 'Authorization: Bearer ${wordpress_oauth_token}' "${wordpress_rest_endpoint}/posts?pretty=true&number=1&order=ASC&offset=${offset}"  | jsawk 'return this.posts[0]["title"]')

featured_image=$(curl -H 'Authorization: Bearer ${wordpress_oauth_token}' "${wordpress_rest_endpoint}/posts?pretty=true&number=1&order=ASC&offset=${offset}"  | jsawk 'return this.posts[0].featured_image')

attachment_zero_url=$(curl -H 'Authorization: Bearer ${wordpress_oauth_token}' "${wordpress_rest_endpoint}/posts?pretty=true&number=1&order=ASC&offset=${offset}"  | jsawk 'var atts = this.posts[0].attachments ; min_prop=100000000 ; for (var prop in atts) if (prop < min_prop) min_prop=prop; return atts[min_prop]["URL"]')

attachment_zero_ID=$(curl -H 'Authorization: Bearer ${wordpress_oauth_token}' "${wordpress_rest_endpoint}/posts?pretty=true&number=1&order=ASC&offset=${offset}"  | jsawk 'var atts = this.posts[0].attachments ; min_prop=100000000 ; for (var prop in atts) if (prop < min_prop) min_prop=prop; return atts[min_prop]["ID"]')

echo POST ID : $post_id
echo POST TITLE : $post_title
echo F IM : $featured_image
echo a0_url : $attachment_zero_url
echo a0_ID : $attachment_zero_ID

a0_url_enc=$(rawurlencode $attachment_zero_url)
echo a0_url_enc : $a0_url_enc

if [ "" == "${featured_image}" ]
then
echo PROCESSING $post_id : $post_title
echo curl -X POST -v   -H 'Authorization: Bearer ${wordpress_oauth_token}' --data-urlencode featured_image=$attachment_zero_ID ${wordpress_rest_endpoint}/posts/${post_id}
curl -X POST -v   -H 'Authorization: Bearer ${wordpress_oauth_token}' --data-urlencode featured_image=$attachment_zero_ID ${wordpress_rest_endpoint}/posts/${post_id}
new_featured_image=$(curl -H 'Authorization: Bearer ${wordpress_oauth_token}' "${wordpress_rest_endpoint}/posts?pretty=true&number=1&order=ASC&offset=${offset}"  | jsawk 'return this.posts[0].featured_image')
echo NEW FEAT. IMG : $new_featured_image

fi


