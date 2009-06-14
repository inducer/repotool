#! /bin/bash

set -e

mkdir -p /tmp/regression-check
cd /tmp/regression-check

RUN_ID="run-`date +%Y-%m-%d-%H%M`"
LOGFILE="$RUN_ID.log"

if ! test "$1" = "--log-ok"; then
  if $0 --log-ok $RUN_ID > $LOGFILE 2>&1; then
    echo "CHECK OK"
    exit 0
  else
    cat "$LOGFILE" | mail -s "Regression Check Failed" hedge@tiker.net
    echo "CHECK FAILED"
    exit 1
  fi
fi

echo "------------------------------------------------------------------"
echo "Regression check run"
date
echo -n "Host "
hostname
echo "------------------------------------------------------------------"

RUN_ID="$2"
git clone http://git.tiker.net/trees/repotool.git "$RUN_ID"
cd "$RUN_ID"
./repotool clone http://git.tiker.net/trees/ .git
./repotool setup-env
eval `./repotool env`
./repotool install
python `which py.test` -k -mpi -n 4
python `which py.test` -k mpi
