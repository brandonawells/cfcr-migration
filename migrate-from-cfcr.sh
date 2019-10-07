#!/usr/bin/env bash
#

usage() {
  echo "Usage:
  $0 <to-registry repo prefix> [ codefresh get images agruments ]

  Example: migrate-from-cfcr.sh gcr.io/codefresh-inc --image-name codefresh/cf-api --limit 10000
  prerequest: docker + docker login to dest registry
  "
}

## Cleaner settings
DOCKER_ROOT=${DOCKER_ROOT:-/var/lib/docker}
DU_THRESHOLD=95
IMAGES_PRUNE_FILTER="until=20m"
get_volume_space_usage(){
   df -P ${DOCKER_ROOT} | awk 'NR==2 {printf "%d", $3 / $2 * 100}'
}

get_volume_inode_usage(){
   df -iP ${DOCKER_ROOT} | awk 'NR==2 {printf "%d", $3 / $2 * 100}'
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
mkdir -p $JOURNAL_DIR

echo "Entering $0 - $(date)
JOURNAL_DIR = $JOURNAL_DIR
DONE_DIR = $DONE_DIR
IMAGES_LIST=$IMAGES_LIST
"

if [[ -n "${DRY_RUN}" ]]; then
  echo "DRY_RUN MODE"
  DOCKER="echo docker"
else
  DOCKER="docker"
fi

codefresh get images $@ --sc name,tag,pull > $IMAGES_LIST
if [[ $? != 0 ]]; then
  echo "Failed to get images list"
  exit 1
fi

echo "Starting at $(date)"
echo "Processing $IMAGES_LIST"

cat ${IMAGES_LIST} | while read line
do

  IMAGE=$(echo "$line" | awk '{print $1}' )
  TAG=$(echo "$line" |  awk '{print $2}' )
  PULL=$(echo "$line" |  awk '{print $3}' )
  # echo "IMAGE=$IMAGE TAG=$TAG PULL=$PULL"
  if [[ "$IMAGE" == "NAME" ]] || \
     [[ ! "$PULL" =~ r.cfcr.io ]] || \
     [[ "$TAG" == '<none>' ]] || \
     [[ "$TAG" =~ ^[0-9a-f]{40}$ ]]; then
     echo "$line - SKIP" 
     continue
  fi

  IMAGE_TAGS_FILE=${JOURNAL_DIR}/${IMAGE/\//__}.tags
  echo $IMAGE_TAGS_FILE
  echo "$PULL ${TO_REPO}/${IMAGE}:${TAG}" >> $IMAGE_TAGS_FILE

done

echo "
--- $(date)
Processing tag files"
for ii in $(ls ${JOURNAL_DIR}/*.tags)
do
  echo "
  ****************
  $(date) - $ii"
  DONE_FILE=${DONE_DIR}/$(basename $ii)
  cat ${ii} | while read line
  do
    PULL=$(echo "$line" | awk '{print $1}' )
    PUSH=$(echo "$line" |  awk '{print $2}' )


    PULL_COMMAND="$DOCKER pull $PULL"
    TAG_COMMAND="$DOCKER tag $PULL $PUSH"
    PUSH_COMMAND="$DOCKER push $PUSH"

    if grep -q "^${PUSH}\$" $DONE_FILE ; then
      echo "Skipping Image $PUSH - it is already done"
      continue
    fi 
    echo "---------- Migrate $PULL to $PUSH"
    eval $PULL_COMMAND && echo -e "Pull $PULL completed - $(date) !!!\n" && \
    eval $TAG_COMMAND && echo -e "Tag $PUSH completed - $(date) !!!\n" && \
    eval $PUSH_COMMAND && echo -e "Push $PUSH completed - $(date) !!!\n"

    if [[ $? == 0 ]]; then
      echo "$PUSH" >> $DONE_FILE
    else
      echo "ERROR - $PULL to $PUSH"
    fi
    SPACE_USAGE=$(get_volume_space_usage)
    if (( SPACE_USAGE > DU_THRESHOLD )); then
      echo "WARNING: SPACE_USAGE = $SPACE_USAGE - prunig images $IMAGES_PRUNE_FILTER"
      docker image prune -a --force --filter $IMAGES_PRUNE_FILTER
    fi

    INODES_USAGE=$(get_volume_inode_usage)
    if (( INODES_USAGE > DU_THRESHOLD )); then
      echo "WARNING: INODES_USAGE = $INODES_USAGE - prunig images $IMAGES_PRUNE_FILTER"
      docker image prune -a --force --filter $IMAGES_PRUNE_FILTER
    fi
  done

done



