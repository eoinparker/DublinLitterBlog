# DublinLitterBlog
Scripted tasks for http://dublinlitterblog.com and http://fixyourstreet.ie interaction.

## MacOS only. No plans to port.  

## Installs Required on path:
- curl -- http://macappstore.org/curl/
- exiftool  -- http://www.sno.phy.queensu.ca/~phil/exiftool/
- geocoder  -- https://github.com/alexreisner/geocoder
- sips -- https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/sips.1.html
- paintbrush -- http://macappstore.org/paintbrush/

## Other requirements:
- a valid Oauth2 token from Wordpress, stored in the file <dir>/wordpress_oauth_token.txt
- a valid Oauth2 token from MS Bing, sotred in the file <dir>/bing_oauth_token.txt

## How
Usage: control.sh <littering_image_1> [littering_image_2] [littering_image_3] ...
