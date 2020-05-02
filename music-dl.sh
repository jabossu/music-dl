#! /bin/bash

# Parameters
	baseURL="https://www.youtube.com/results?search_query="
	videoURL='https://www.youtube.com/watch?v='
	separator="@"
	configfile="dl_settings.cfg"
	number_of_choices=3

#=====================================
#	Setting up parameters
#=====================================

if [[ -f "$configfile" ]]; then
	# READ Settings
	artist="$(grep artist $configfile| cut -d ':' -f 2)"
	album="$(grep album $configfile | cut -d ':' -f 2)"
	
	echo "Settings found :"
	echo -e "\t - Artist : $artist"
	echo -e "\t - Album : $album"
else
	echo "No settings found. Lets define tags."
	
	artist=""
	album=""
	
	while [ "$artist" == "" ]; do
		echo -ne "\tArtist name ? "
		read artist
	done
	
	while [ "$album" == "" ]; do
		echo -ne "\tAlbum name ? "
		read album
	done
	
	echo -e "\tsaving settings..."
	echo "artist:$artist" > dl_settings.cfg
	echo "album:$album" >> dl_settings.cfg
fi

if [[ -f thumb.jpg ]]; then
	echo -e "\t ☑ Thumbnail found"
	existpicture=true
else
	echo -e "\t ☒ No thumbnail found !"
	existpicture=false
fi

#=====================================
#	Getting into business
#=====================================

URL=0
while [ "$URL" != 'exit' ] ; do

	while [ "$URL" == 0 ] ; do
		echo -e "\n------------------------------------------"
		read -p "Search : " search
		
		if [[ $search == 'exit' ]]; then
			URL='exit'
			break;
		elif [[ $search == 0 ]]; then
			URL=0
			continue
		fi
		
		if [[ "$search" =~ ^http.*watch\?v=.{11}$ ]] ; then
			#the user asked for a specific URL
			URL="$search"
			echo "Specific URL asked..."
			break;
		elif [[ "$search" =~ ^http.soundcloud.com*$ ]] ; then
		    URL="$search"
		    echo "Soundloud URL parsed..."
		    break;
		fi
		
		searchchain="$(echo $search | sed 's/ /+/g')"
		searchURL=$baseURL$searchchain
		echo -ne "\nSearching on youtube..."

		for i in {1..3..1}
		do
			j="$(youtube-dl --playlist-start $i --playlist-end $i --get-filename -o [$i]$separator%\(title\)s$separator%\(uploader\)s$separator%\(id\)s $searchURL)"
			videolist[$i]=$j
			
			number="$(echo $j | cut -d "$separator" -f 1)"
			title="$(echo $j | cut -d "$separator" -f 2)"
			creator="$(echo $j | cut -d "$separator" -f 3)"
			id="$(echo $j | cut -d "$separator" -f 4)"
			
			echo -ne "\n\t$number $title (by $creator)\n\t    $videoURL$id"
			
		done
		echo -e ""

		echo -e "\nWhich one do you want to download ?"

		read -p "[1-5] / 0 to cancel / exit : " target

		if [[ $target -ge 1 && $target -le 5 ]]; then
			targetID="$(echo ${videolist[$target]} | cut -d "$separator" -f 4)"
			URL="$videoURL$targetID"
		elif [[ $target == '' ]]; then
			targetID="$(echo ${videolist[1]} | cut -d "$separator" -f 4)"
			URL="$videoURL$targetID"
		elif [[ $target == 'exit' ]]; then
			URL='exit'
		else
			URL=0
		fi
	done
	
	if [[ $URL == 'exit' ]]; then
		break;
	elif [[ $URL == 0 ]]; then
		continue
	fi
	
	echo -ne "\t* Gathering data..."
	songname="$(youtube-dl --get-filename -o '%(title)s' $URL)" &&\
	filename="$songname.mp3" &&\
	echo -e "   \t[ Done ]"	&&\
	echo -e "\t* Found $filename" &&\
	
	echo -en "\t* Downloading. Please wait..."	&&\
	youtube-dl --quiet -f bestaudio -x --audio-format mp3 -o "%(title)s.%(ext)s" "$URL"	&&\
	echo -e "\t[ Done ]"	&&\
	
	echo -ne "\t* Writting metadatas..."	&&\
	mid3v2 --artist "$artist" --album "$album" --song "$songname" "$filename"	&&\
	echo -e "   \t[ Done ]" && \
	
	noerror=true || noerror=false
	
	if [ "$existpicture" == "true" ] && [ "$noerror" == true ]
	then
		echo -ne "\t* Adding thumbnail..."
		mid3v2 --picture thumb.jpg "$filename"
		echo -e "   [ Done ]"
	fi
	
	if [[ $"URL" != 'exit' ]]; then
		URL=0
	fi	
done

echo "Goodbye"
