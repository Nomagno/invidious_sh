#!/bin/sh
instance="iteroni.com"
option="$1"
videolist="UNUSED"
channel_name="UNUSED"
version="invidious.sh 1.0"
usage="Usage:\n invidious.sh [OPTIONS] [ARGUMENTS]\n
Options:\n -c --channel | invidious.sh -c [CHANNEL ID] | Fetches videos from channel\n \
Options:\n -l --link | invidious.sh -c [VIDEO ID] | Composes full url ready to paste into a browser \n \
Options:\n -v --version | invidious.sh -v | Prints version information\n \
Options:\n -h --help | invidious.sh -h | Displays this help message\n \
Options:\n -f --fetch | invidious.sh -f [STDIN] [CHANNEL NUMBER or CHANNEL NAME] | Fetches channel video feed using a list provided in the format [N] [CHANNEL NAME] (CHANNEL ID)\n \
Options:\n -d --download | invidious.sh -d [VIDEO ID] [OUTPUT FILE NAME]| Directly downloads video file\n \
"

get_feed () {
	tmp1="$(mktemp)"
	tmp2="$(mktemp)"
	channel_id="$1"
	channel_name=$(curl -s "$instance/api/v1/channels/$channel_id/videos?fields=author&pretty=1" | sed '3,3!d'  | grep -oP "(?<=\"author\"\:).*(?=)")
	channel_info=$(curl -s "$instance/api/v1/channels/$channel_id/videos?fields=videoId,title&pretty=1")
	names=$(echo "$channel_info" | grep -oP "(?<=\"title\"\:).*(?=)")
	ids=$(echo "$channel_info" | grep -oP "(?<=\"videoId\"\:).*(?=)")
	echo "$names" | sed 's/^/Title: /; s/$//' >"$tmp1"
	echo "$ids" | sed 's/^/ID\^\^\^: /; s/$//' >"$tmp2"
	videolist=$(paste -d "\n" "$tmp1" "$tmp2")
}

#Invidious URL download format: INSTANCE_URL/latest_version?download_widget={"id":"VIDEO_ID","itag":"18","title":"URL_ENCODED_NAME.mp4"
#   OBLIGATORY: MUST REPLACE THESE SYMBOLS EVERYWHERE IN THE LINK 
#   TO GET THE URL ENCODING TO BE ACCEPTED, PLUS ANY OTHER ONES LIKE
#   PARENTHESES THAT POP UP IN THE TITLE NAME, WITH THEIR URL ENCODING
#   { ---- %7B
#   } ---- %7D
#   " ---- %22
#   , ---- %2C
#   : ---- %3A
#   (SPACE) ---- +

if [ "$option" = "-h" ] || [ "$option" = "--help" ]; then
	echo "$usage"

elif [ "$option" = "-v" ] || [ "$option" = "--version" ]; then
	echo "$version"

elif [ "$option" = "-c" ] || [ "$option" = "--channel" ]; then
  get_feed "$2"
  printf "Latest content by $channel_name:\n\n%s\n(Please make sure your input is correct if the list is empty) \n" "$videolist\n"


elif [ "$option" = "-l" ] || [ "$option" = "--link" ]; then
  video_id="$2"
	echo "$instance/watch?v=$video_id"

elif [ "$option" = "-f" ] || [ "$option" = "--fetch" ]; then
    if [ "$2" = "" ]; then
      printf " -f | Wrong usage.\nSee the manpage or --help for more information\n"
    else
      tmp_red=$(mktemp)
      number="$2"
      while read line; do
        echo "$line" | grep -P "(?<=\[$number).*(?=\])" | grep -oP "(?<=\().*(?=\))" >> "$tmp_red"
      done 
      while read line2; do get_feed "$line2"; done
	    printf "Latest content by $channel_name:\n\n%s\n(Please make sure your input is correct if the list is empty) \n" "$videolist"

    fi

elif [ "$option" = "-d" ] || [ "$option" = "--download" ]; then
  video_id="$2"
  video_title="$3"	
  video_title_compose="$video_title.mp4"
  curl -s -L $instance/latest_version?download_widget=%7B%22id%22%3A%22$video_id%22%2C%22itag%22%3A%2218%22%2C%22title%22%3A%22+%22%7D --output "$video_title_compose"
  echo "Video saved to file $video_title_compose"
  
else
      printf "Unknown option.\nSee the manpage or --help for more information\n"

fi
