#!/bin/bash
d=$(date '+%Y-%m-%d-%H-%M-%S')
source ~/settings.conf
path=/tmp/backup-$(whoami)-$d.tgz
tar -cvf $path $dir
# f - to update link
ln -fs $path $link_name
