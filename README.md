# sony_georef
Extract Gps information and generate speed subtitles for Sony action cameras (HDR-AZ1, HDR-AS100 and others)

## Dependencies
- dateutils: http://www.fresse.org/dateutils/
- ffmpeg
- exiftool
- gpsbabel
- imagemagick
- bash

## Usage
- Copy Folders MP_ROOT and PRIVATE to your computer
- cd into directory MP_ROOT/100ANV01 (or similar, it is the folder with the .MP4 files)
- Run the script

## Output
- The script will try to match the GPS data files with the corresponding video files accoriding to the start date/times
- It converts the files to gpx files with the same name prefix as the corresponding video files
- It creates a subtitle file with the velocity
- It creates a video file with the same resolution and frame rate as the original, but with blue background and the speed in km/h in white

## Problems
- If the gps starts later, it will not properly match the video/gpx file

Use with care!
