#!/usr/bin/env bash
#

usage() {
  echo "Usage:
  $0 <from-repo> <to-repo> <images_file>

  Example: migrate-from-cfcr-crane.sh r.cfcr.io/ddd gcr.io/ddd
  prerequest: crane
  "
}
FROM_REPO=$1
TO_REPO=$2
IMAGES_FILE=$3
if [[ -z "$TO_REPO" || -z "$FROM_REPO" || -z "${IMAGES_FILE}" ]]; then
  usage 
  exit 1
fi


DIR=$(dirname $0)
DONE_DIR=$DIR/done 
mkdir -p $DONE_DIR 

JOURNAL_DIR=${JOURNAL_DIR:-$DIR/journal/$(date "+%Y-%m-%d_%H%M%S")}
IMAGES_LIST=$JOURNAL_DIR/images-list 
mkdir -p $JOURNAL_DIR

echo "Entering $0 - $(date)
FROM_REPO=$FROM_REPO
TO_REPO=$TO_REPO
IMAGES_FILE=$IMAGES_FILE
JOURNAL_DIR = $JOURNAL_DIR
DONE_DIR = $DONE_DIR
IMAGES_LIST=$IMAGES_LIST
"

if [[ -n "${DRY_RUN}" ]]; then
  echo "DRY_RUN MODE"
  CRANE="echo crane"
else
  CRANE="crane"
fi

cp -v $IMAGES_FILE $IMAGES_LIST
if [[ $? != 0 ]]; then
  echo "Failed to get images list"
  exit 1
fi

echo "Starting at $(date)"
echo "Processing $IMAGES_LIST"
DONE_FILE=${DONE_DIR}/done_list
cat ${IMAGES_LIST} | while read line
do
  IMAGE_DATE=$(echo "$line" | awk '{print $1}' )
  IMAGE=$(echo "$line" | awk '{print $2}' )
  NEW_IMAGE=$(echo "$IMAGE" |  sed "s%${FROM_REPO}%${TO_REPO}%g")

  if grep -q "^${IMAGE}\$" $DONE_FILE ; then
    echo "Skipping Image $IMAGE - it is already done"
    continue
  fi
  COPY_COMMAND="$CRANE copy $IMAGE $NEW_IMAGE"
  echo "---------- Copy $IMAGE to $IMAGE"
  echo "the image from $IMAGE_DATE"
    eval $COPY_COMMAND && echo -e "copy $IMAGE completed - $(date) !!!\n"

    if [[ $? == 0 ]]; then
      echo "$IMAGE" >> $DONE_FILE
    else
      echo "ERROR - $IMAGE to $NEW_IMAGE"
    fi
done



