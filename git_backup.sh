#! /bin/bash

TODAY=$(date +"%Y-%b-%d")
BASE_BKUP_DIR="backups"
BACKUP_DIR="$HOME/backups/$TODAY"
TEAMS='<TEAM1> <TEAM2> ....'
LOGIN='<username>:<password>'
logfile="/var/log/bkup_cron.log"

if [ ! -d  "$BACKUP_DIR"  ]; then
   mkdir $BACKUP_DIR
   cd $BACKUP_DIR

   for team in $TEAMS; do
       curl -u $LOGIN "https://api.bitbucket.org/2.0/repositories/$team?pagelen=20" > /tmp/$team.json

       for repo in `cat /tmp/$team.json | jq -r '.values[] .links .clone[] | select(.name == "ssh") .href'`; do
           {
	        sudo echo "[`date`] cloning $repo into $BACKUP_DIR"
 	   } >> "$logfile"
           git clone $repo
       done
   done
   cd ..
   zip -r "$TODAY.zip" "$TODAY/"
   rm -rf $BACKUP_DIR
   cd
else
   {
     sudo echo "[`date`] $BACKUP_DIR already exists!"
   } >> "$logfile"
fi

STALE_BACKUP_DIR=$(find "$HOME/$BASE_BKUP_DIR" -ctime +10 -exec ls {} \;)
if [ -n "$STALE_BACKUP_DIRS" ]; then
   {
     sudo echo "[`date`] removing $STALE_BACKUP_DIRS"
   } >> "$logfile"

   #find "$HOME/$BASE_BKUP_DIR" -type d -ctime +7 -exec rm -rf {} \;
   find "$HOME/$BASE_BKUP_DIR" -mtime +10 -exec rm -f {} \;
else
   {
      sudo echo "[`date`] No Stale directories present currently!"
   } >> "$logfile"
fi
