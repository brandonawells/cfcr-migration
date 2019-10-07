#!/usr/bin/env bash
#
# Running migrate-fro-cfcr.sh in background
#

DIR=$(dirname $0)
JOURNAL_DIR=$DIR/journal/$(date "+%Y-%m-%d_%H%M%S")
IMAGES_LIST=$JOURNAL_DIR/images-list 
LOG_FILE=$JOURNAL_DIR/migration.log 
codefresh get images >/dev/null
if [[ $? != 0 ]]; then
  echo "Failed to get codefresh images list"
  exit 1
fi

mkdir -p $JOURNAL_DIR

export JOURNAL_DIR
echo "Starting migrtate-from-cfcr.sh in background. output to $LOG_FILE"
$DIR/migrate-from-cfcr.sh $@ &>$LOG_FILE  <&- &
MIGRATE_PID=$!
echo "Migrate script is running with PID $MIGRATE_PID 
see the log output in $JOURNAL_DIR 
"

wait $MIGRATE_PID
