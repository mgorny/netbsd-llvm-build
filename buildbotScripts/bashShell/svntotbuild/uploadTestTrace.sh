#!/usr/bin/env bash
set -e -x
source setEnv.sh

cd "$rootDir"
logsMb=$(du -cm "$originalDir"/logs-* | tail -n 1 | awk '{print $1}')
if [ "$logsMb" -ge 4000 ]; then
  # The tests generated too much data (probably core files)
  # Let's prune those out and leave just a couple of them for analysis.
  find "$originalDir"/logs-* -name '*core*' -print | tail -n +30 | xargs -t rm
fi
zip -r build-"$1" "$originalDir"/logs-* >/dev/null
gsutil mv build-$1.zip $gstrace/$2/

oldNum=$(( $1-500 ))
echo remove old test trace of build $oldNum
gsutil rm $gstrace/$2/build-$oldNum.zip || true

rm -rf "$originalDir"/logs-*
