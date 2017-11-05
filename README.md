# DublinLitterBlog
Helper scripts for http://dublinlitterblog.com and http://fixyourstreet.ie interaction.

## MacOS only. No plans to port.  

## Installs Required on path:
- curl -- http://macappstore.org/curl/
- exiftool  -- http://www.sno.phy.queensu.ca/~phil/exiftool/
- geocoder  -- https://github.com/alexreisner/geocoder
- sips -- https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/sips.1.html
- GIMP - https://www.gimp.org/downloads

## Other requirements:
- a valid Oauth2 token from Wordpress, stored in the file install_dir/wordpress_oauth_token.txt
- a valid Oauth2 token from MS Bing, stored in the file install_dir/bing_oauth_token.txt

## How
Usage: install_dir/control.sh <littering_image_1> [littering_image_2] [littering_image_3] ...
