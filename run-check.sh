#! /bin/bash

set -e

mkdir -p /tmp/regression-check
cd /tmp/regression-check

RUN_ID="run-`date +%Y-%m-%d-%H%M`"
LOGFILE="$RUN_ID.log"
NOMPI_LOGFILE="$RUN_ID-nompi.log"
MPI_LOGFILE="$RUN_ID-mpi.log"

if ! test "$1" = "--log-ok"; then
  if timelimit $0 --log-ok $RUN_ID > $LOGFILE 2>&1 \
    && tail -n 1 $NOMPI_LOGFILE | egrep '= [0-9]* passed' \
    && tail -n 1 $MPI_LOGFILE | egrep '= [0-9]* passed' \
    ; then
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

NOMPI_LOGFILE="$RUN_ID-nompi.log"
MPI_LOGFILE="$RUN_ID-mpi.log"

git clone http://git.tiker.net/trees/repotool.git "$RUN_ID"
cd "$RUN_ID"
./repotool clone http://git.tiker.net/trees/ .git
./repotool setup-env
eval `./repotool env`
./repotool install

export LD_LIBRARY_PATH=$HOME/pool/lib
export PATH=$PATH:$HOME/pool/cuda/bin

python `which py.test` -k -mpi | tee "../$NOMPI_LOGFILE"
python `which py.test` -k mpi | tee "../$MPI_LOGFILE"
