#!/bin/bash
# must run as root

OUTFILE=myhome_dir_$(date +%Y%m%d).tar.bz2

tar -cvpjf $OUTFILE --exclude=/proc --exclude=/lost+found --exclude=/$OUTFILE.tar.bz2 --exclude=/mnt --exclude=/sys /
