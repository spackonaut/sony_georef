#!/bin/bash

#dependencies:
#dateutils: http://www.fresse.org/dateutils/
#ffmpeg
#exiftool
#gpsbabel
#imagemagick

#offset in seconds
offset=3


#go through all gps nmea .LOG files
log_folder="../../PRIVATE/SONY/GPS/"
for file in $(ls "$log_folder/" |grep -i ".LOG$"); do
	gpx="${file%.*}.gpx"
	gpx11="${gpx%.*}_v11.gpx"
	gpx_s="${gpx%.*}_nospeed.gpx"
	#check if gpx file already exists and if file has more then 1 line
	echo "$log_folder""$file"
	if [ ! -s "$gpx" -a `wc -l < "$log_folder/""$file"` -gt 1 ]
	then
		echo converting "$log_folder/""$file"
		gpsbabel -i nmea -f "$log_folder/""$file" -o gpx,gpxver=1.0 -F "$gpx"
		#clean:
		gpsbabel -i nmea -f "$log_folder/""$file" -o gpx,gpxver=1.1 -F "$gpx11"
		grep -iv 'nan\|<speed>\|<geoidheight>\|<course>\|<fix>' "$gpx11" > "$gpx_s"
		rm "$gpx11"

	fi

	if [ -s "$gpx" ]
	then
		gps_create_date=`awk '/<trkpt/{i++}i==1' $gpx |grep -m1 \<time\> |sed -e 's/<time>//g' -e 's/<\/time>//g'`

		for video_file in $(ls ./ |grep -i ".MP4$" |grep -v "overlay"); do
			if [[ `file $video_file |head -n1` == *"empty"* ]]
			then
			   echo "$video_file is corrupt"
			else
				video_create_date=`exiftool -d %Y-%m-%dT%H:%M:%S%Z -p '$CreateDate' $video_file 2>/dev/null`
				#video_create_date_offset=`dateadd "$video_create_date" "+$offset_video" |xargs date "+%s" --date` 
				#let date_diff=$video_create_date_offset-$gps_create_date
				echo "gps date" $gps_create_date
				echo $video_file
				echo "video date" $video_create_date
				date_diff=`datediff $video_create_date $gps_create_date -f '%S'`
				echo $date_diff
				if [ $date_diff -le 3 ] && [ $date_diff -ge -3 ]
				then
					echo match
					mv "$gpx" "${video_file%.*}.gpx"
					mv "$gpx_s" "${video_file%.*}_nospeed.gpx"

					gps_date_corrected=`dateadd $gps_create_date "$offset"rS -f "%Y%m%d"`
					gps_time_corrected=`dateadd $gps_create_date "$offset"rS -f "%H%M%S"`
					echo $gps_create_date
					echo $gps_date_corrected
					echo $gps_time_corrected

					gpsbabel -i gpx -f "${video_file%.*}.gpx" -o subrip,gps_time=$gps_time_corrected,gps_date=$gps_date_corrected,format='%s km/h' -F "${video_file%.*}".srt

					fps=`exiftool -p '$videoframerate' $video_file`
					image_size=`exiftool -p '$imagesize' $video_file`

					convert -size $image_size canvas:blue blanc.png
					#create empty video with speed rendering
					ffmpeg -loop 1 -i blanc.png -i $video_file -shortest -map 0:0 -map 1:1 -filter:v subtitles="${video_file%.*}.srt":force_style='FontSize=45' -c:a copy -c:v libx264 -qp 0 -preset slow -r $fps "${video_file%.*}_overlay_tmp.mp4"
					
					#remove audio
					ffmpeg -i "${video_file%.*}_overlay_tmp.mp4" -an -c:v copy "${video_file%.*}_overlay.mp4"

					rm blanc.png
					rm "${video_file%.*}_overlay_tmp.mp4"
					break
				else
					echo no match
				fi
			fi	
		done
	else
		echo no gpx file
	fi
done

