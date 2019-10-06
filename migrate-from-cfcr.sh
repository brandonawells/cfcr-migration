#!/usr/bin/env bash
#

usage() {
  echo "Usage:
  $0 <to-registry repo prefix> [ codefresh get images agruments ]

  Example: migrate-from-cfcr.sh gcr.io/codefresh-inc --image-name codefresh/cf-api --limit 10000
  prerequest: docker + docker login to dest registry
  "
}

TO_REPO=$1
if [[ -z "$TO_REPO" ]]; then
  usage 
  exit 1
fi
shift

DIR=$(dirname $0)
DONE_DIR=$DIR/done 
mkdir -p $DONE_DIR 

JOURNAL_DIR=${JOURNAL_DIR:-$DIR/journal/$(date "+%Y-%m-%d_%H%M%S")}
IMAGES_LIST=$JOURNAL_DIR/images-list 

codefresh get images $@ --sc name,tag,pull > $IMAGES_LIST

cat ${IMAGES_LIST} | while read line
do
  echo $line
  IMAGE=$(echo "$line" | cut -f1 )
  TAG=$(echo "$line" | cut -f2 )
  PULL=$(echo "$line" | cut -f3 )
  
  [[ "$IMAGE" == "NAME" ]] && continue
  [[ ! "$IMAGE" =~ r.cfcr.io ]] && continue
  [[ "$TAG" == '<none>' ]] && continue
  [[ "$TAG" =~ ^[0-9a-f]{40}$ ]] && continue

  PULL_COMMAND="docker pull $PULL"
  TAG_COMMAND="docker tag $PULL "


done



