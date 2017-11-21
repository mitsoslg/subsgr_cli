#!/bin/bash
#-------------------------------------------------------------------------------
# Name : This script downloads subtitles for video (movie/series) files.
# 
#
# Authors : Dimitris Michalopoulos <dmixalo@gmail.com> Created : 
#2 October 2017 Licence : GPL v3 
#
# updated:
# 21 November 2017
#-------------------------------------------------------------------------------

if [ $# -eq 0 ]; then
    echo $0: usage: script path using as optional the parameters [debug] - [translate] 
    exit 1
fi

SUBLANG_VAL="ell"

command -v subdownloader >/dev/null 2>&1 || { echo >&2 "This script requires subdownloader but it's not installed. Try apt-get install subdownloader  Aborting."; exit 1; }


if [ -z "$1" ]
  then cwd=$(pwd)
  else cwd=$1
fi

#Initilization
debug="0"
translate="0"
output="> /dev/null 2> /dev/null"
subfiles=0

#Get the parameters
for i in "$@" ; do
	if [[ $i == "debug" ]] ; then
        debug="1"
    fi
	if [[ $i == "translate" ]] ; then
        translate="1"
		command -v trans >/dev/null 2>&1 || { echo >&2 "This script requires trans but it's not installed. Try: git clone https://github.com/soimort/translate-shell && cd translate-shell/ && make && [sudo] make install  Aborting."; exit 1; }
    fi
done

#functions
download_subs(){
	wd=$1
	lang=$2
	for vid in "$wd"/*.mkv "$wd"/*.mp4 "$wd"/*.avi;
	do
		[ -e "$vid" ] || continue
		if [[ "$debug" == "1" ]]; then
			subdownloader -c -l $lang --rename-subs --video="$vid"
			else
			subdownloader -c -l $lang --rename-subs --video="$vid"  > /dev/null 2> /dev/null
		fi
	done
}

name_fix(){
	wd=$1
	
	# REMOVE SPACES
	find $wd -name "* *" -type d | rename 's/ /_/g'    # do the directories first
	find $wd -name "* *" -type f | rename 's/ /_/g'

	FILES=`find $wd -type f -regex '.*\.\(mkv\|srt\|avi\|mp4\|wmv\|flv\|webm\|m4v\|mov\)'`

     for f in $FILES
        do
		#remove potential dots in file names
		extension="${f##*.}"
		f1=${f%.*}
		f2=${f##$f1}
		fx=`echo $f1 | tr \. _`
		mv $f $fx.$extension 2>/dev/null
	done
}

UTF8_encoding(){
wd=$1
for sub in "$wd"/*.srt "$wd"/*.sub;
do
  [ -e "$sub" ] || continue
  subenc=$(enca -L none -i "$sub")
  (( subfiles++ ))
  if [ "$subenc" != "UTF-8" ]
  then
    echo "Subtitle has been found, Changing encoding of subtitle"
    iconv -f CP1253 -t utf-8 -o tempsub "$sub"
    mv tempsub "$sub"
  else
    echo "Subtitle has been found and properly encoded"
  fi
done
}

translate(){
	wd=$1
for sub in "$wd"/*.srt  #"$wd"/*.sub;
do	
	if [[ "$debug" == "1" ]]; then
		echo "Translating..."
		 /usr/local/bin/trans -i "$sub" :el -brief -o tempsub
		else
		echo "Translating..."
		 /usr/local/bin/trans -i "$sub" :el -brief -o tempsub  > /dev/null 2> /dev/null
	fi
	mv tempsub "$sub" 2>/dev/null
	sed -i 's/->/-->/g' "$sub"
done
}

if [[ "$debug" == "1" ]]; then
	echo "Language is set to $SUBLANG_VAL"
fi

#Download Subtitles
download_subs $cwd $SUBLANG_VAL

#Fix Names
name_fix $cwd

## Properly ecnoding subtitles (UTF-8)
UTF8_encoding $cwd

##Check if no subtitles have been found
if [ $subfiles -eq 0 ]; then
   echo "No subtitles have been found!";
	if [ $translate -ne 0 ] ; then
	echo "Trying English subtitles and auto-translation..."
	download_subs $cwd en
	UTF8_encoding $cwd
		if [ $subfiles -eq 0 ]; then
			echo "No subtitles have been found, even in English"
			exit;
		else translate $cwd
		echo "Subtitles have been translated from English";
		fi
	else	exit;
   fi
fi
