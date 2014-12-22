#!/bin/bash
# bash front-end to ruby backup script
# give absolute path for cron to ruby script
source /home/ubuntu/.bash_profile
ruby /home/ubuntu/drupal_backup/backup.rb
