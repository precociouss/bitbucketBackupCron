#! /bin/bash

TODAY=$(date +"%Y-%b-%d")
BASE_BKUP_DIR="backups"
[ -d $HOME/$BASE_BKUP_DIR ] || mkdir $HOME/$BASE_BKUP_DIR
BACKUP_DIR="$HOME/backups/$TODAY"
[ -d $BACKUP_DIR ] || mkdir $BACKUP_DIR
TEAMS='<team1> <team2>....'
LOGIN='<username>:<password>'
logfile="/var/log/bkup_cron.log"

# if [ ! -d  "$BACKUP_DIR"  ]; then
   # mkdir $BACKUP_DIR

   for team in $TEAMS; do
       curl -u $LOGIN "https://api.bitbucket.org/2.0/repositories/$team?pagelen=20" > /tmp/$team.json
       REPOS=$(cat /tmp/$team.json | jq -r '.values[] .links .clone[] | select(.name == "https") .href')
       for repo in $REPOS; do
            gitreponame=$(echo -e "$repo" | rev|cut -d'/' -f1 |rev|cut -d'.' -f1)
            BRANCHLINK="https://api.bitbucket.org/2.0/repositories/$team/$gitreponame/refs/branches"
            BRANCHES=$(curl -u $LOGIN "$BRANCHLINK"| jq -r '.values[] .name')

            count=$(echo "$BRANCHES" | wc -w)
            postfix=$(echo -e "$repo" | cut -d'@' -f2)
            link="https://$LOGIN@$postfix"
            if [ $count -gt 1 ]; then
                for branch in $BRANCHES; do
                    cloneDir="$gitreponame-$branch"
                    [ -d $BACKUP_DIR/$cloneDir ] || mkdir $BACKUP_DIR/$cloneDir
                    git clone -b $branch $link $$BACKUP_DIR/$cloneDir
                done
            else
              [ -d $BACKUP_DIR/$gitreponame ] || mkdir $BACKUP_DIR/$gitreponame
              git clone $link $BACKUP_DIR/$gitreponame
            fi
      done
  done
