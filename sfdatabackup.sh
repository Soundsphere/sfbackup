#!/bin/bash
# backup SF Data
# Written by benedikt.rumpf@caroobi.com
# System Administrator and bitch for everything electronical
# downloads salesforce data from specified objects for the last 14 days
# for backup purposes. Setup cronjob for added fun.

#####################################################################
# TODO:                                                             #
#####################################################################
#                 REQUIRES zip, jq and force                        #
# run 'sudo apt-get isntall jq' or 'pacman -S jq' if not installed  #
# run 'sudo apt-get instal zip' or 'pacman -S zip' if not installed #
# force can be found here: https://github.com/ForceCLI/force        #
#####################################################################

## check if folders exists and if not, create them
if [ ! -d "$HOME/SFBackup" ]; then
  mkdir $HOME/SFBackup
  mkdir $HOME/SFBackup/Backup_Folders
  mkdir $HOME/SFBackup/Backup_Files
fi

## set variables to be used later
PASSWORD='password'
NOW=$(date +"%d_%m_%Y")

## login to salesforce. Here we use the system user as the PW never changes
$HOME/bin/force login -i=login.salesforce.com -u=username@salesforce.com -p=$PASSWORD

## specify how the fields are retrieved. This function queries all fields from
## the specified object. The object is specified within the query
function getfields()
{
  FIELDS=$($HOME/bin/force field list $1 | sed 's/\:.*/,/' )
  LIST=${FIELDS::-1}
  echo $LIST
}

## create folder with todays date for plain files
mkdir $HOME/SFBackup/Backup_Folders/$NOW-data

## iterate over all objects in salesforce to get the fields for the query
## exclude objects by listing them in the file excludeobjects.txt
## should an object be queried all time, enter it in the queryalltime.txt file
array=$($HOME/bin/force sobject list)
for i in ${array[@]}; do
    if grep -Fxq "$i" $HOME/SFScripts/excludedobjects.txt; then
      :
    elif [ $(echo $($HOME/bin/force describe -t=sobject -n=$i) | jq '.queryable') == false ]; then
      :
    elif grep -Fxq "$i" $HOME/SFScripts/queryalltime.txt; then
      $HOME/bin/force query "SELECT $(getfields $i) from $i" > $HOME/SFBackup/Backup_Folders/$NOW-data/$i.csv
    else
      $HOME/bin/force query "SELECT $(getfields $i) from $i WHERE CreatedDate = LAST_N_DAYS:14" > $HOME/SFBackup/Backup_Folders/$NOW-data/$i.csv
    fi
done

## cleanup objects that cannot be queried or don't hold data
find $HOME/SFBackup/Backup_Folders/$NOW-data -size  0 -print0 |xargs -0 rm --

## zip the files and move them to the backup files folders
cd $HOME/SFBackup/Backup_Folders
zip -r $NOW-data.zip $NOW-data
mv $NOW-data.zip $HOME/SFBackup/Backup_Files
