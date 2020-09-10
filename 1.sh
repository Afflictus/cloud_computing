#!/bin/bash
#export FILENAME_PATTERN=$1
#export CONTENT_PATTERN=$2
if [ -n "$1" ] && [ -n "$2" ]
then 
export FILENAME_PATTERN=$1
export CONTENT_PATTERN=$2
echo "Success"
else 
export FILENAME_PATTERN=test?.*
export CONTENT_PATTERN=?62*
echo "Not success"
fi
content_p=${CONTENT_PATTERN//\?/.}
content_p=${content_p//\*/.*}
grep -l $content_p ./* --include=$FILENAME_PATTERN
