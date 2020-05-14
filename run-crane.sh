#!/usr/bin/env bash
#
# Running migrate-from-cfcr-crane.sh in background
#

DIR=$(dirname $0)
JOURNAL_DIR=$DIR/journal/$(date "+%Y-%m-%d_%H%M%S")
IMAGES_LIST=$JOURNAL_DIR/images-list 
LOG_FILE=$JOURNAL_DIR/migration.log 

mkdir -p $JOURNAL_DIR

export JOURNAL_DIR
echo "Starting migrtate-from-cfcr.sh in background. output to $LOG_FILE"
nohup $DIR/migrate-from-cfcr-crane.sh $@ &>$LOG_FILE  <&- &
MIGRATE_PID=$!
echo "Migrate script is running with PID $MIGRATE_PID 
see the log output in $JOURNAL_DIR 
"
sleep 3
tail -f $JOURNAL_DIR/migration.log
