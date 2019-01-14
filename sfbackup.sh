#!/bin/bash
# backup SF Data
# Written by benedikt.rumpf@caroobi.com
# System Administrator and bitch for everything electronical
# downloads salesforce metadata via the org.xml file.
# Setup cronjob for added fun.

#####################################################################
# TODO:                                                             #
#####################################################################
#                         REQUIRES force                            #
# force can be found here: https://github.com/ForceCLI/force        #
#####################################################################

## check if folders exists and if not, create them
if [ ! -d "$HOME/SFBackup" ]; then
  mkdir $HOME/SFBackup
  mkdir $HOME/SFBackup/Backup_Folders
  mkdir $HOME/SFBackup/Backup_Files
fi

# set variables to be used later
PASSWORD='password'
NOW=$(date +"%d_%m_%Y")

#login to salesforce. Here we use the system user as the PW never changes
/home/bene/bin/force login -i=login.salesforce.com -u=username@salesforce.com -p=$PASSWORD

## get the actual metadata backup. Control what you want to backup with the org.xml file
cd $HOME/SFBackup/Backup_Folders
mkdir $NOW-metadata
cd $NOW-metadata
$HOME/bin/force fetch -x $HOME/SFScripts/org.xml
cd ..
zip -r $NOW-metadata.zip $NOW-metadata
mv $NOW-metadata.zip $HOME/SFBackup/Backup_Files

## remove files older than 30 days from the Backup_Files folder
find $HOME/SFBackup/Backup_Files -type f -mtime +30 -name '*.zip' -execdir rm -- '{}' \;

## remove folders that are older than 14 days
find $HOME/SFBackup/Backup_Folders/ -mindepth 0 -mtime +14 -execdir rm -r {} \;
