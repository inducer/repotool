#! /bin/bash

set -e

mkdir -p /tmp/regression-check
cd /tmp/regression-check

RUN_ID="run-`date +%Y-%m-%d-%H%M`"
LOGFILE="$RUN_ID.log"
NOMPI_LOGFILE="$RUN_ID-nompi.log"
MPI_LOGFILE="$RUN_ID-mpi.log"

if ! test "$1" = "--log-ok"; then
  if timelimit -t 24000 $0 --log-ok $RUN_ID > $LOGFILE 2>&1 \
    && tail -n 1 $NOMPI_LOGFILE | egrep '= [0-9]* passed' \
    && tail -n 1 $MPI_LOGFILE | egrep '= [0-9]* passed' \
    ; then
    echo "CHECK OK"

    mutt -s "Regression Check Ok" \
      -a "$NOMPI_LOGFILE" "$MPI_LOGFILE" "$LOGFILE" -- \
      hedge@tiker.net <<EOF
Hi there,

No failures were encountered during the regression check.

- The seven testing dwarves
EOF
    exit 0
  else
    touch $NOMPI_LOGFILE
    touch $MPI_LOGFILE
    touch $LOGFILE
    mutt -s "Regression Check Failed" \
      -a "$NOMPI_LOGFILE" "$MPI_LOGFILE" "$LOGFILE" -- \
      hedge@tiker.net <<EOF
Hi there,

I'm sorry to report that the regression check failed.
Details are attached.

- Your guilty conscience
EOF
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

echo "---------------------------------------------------------"
echo "cloning repotool"
echo "---------------------------------------------------------"
git clone --quiet http://git.tiker.net/trees/repotool.git "$RUN_ID"
cd "$RUN_ID"
./repotool clone http://git.tiker.net/trees/ .git
./repotool setup-env
eval `./repotool env`
easy_install -U py
./repotool install 
./repotool for-all -v git log -1 --pretty=format:%h,%ar,%s%n --no-color

export LD_LIBRARY_PATH=$HOME/pool/lib
export PATH=$PATH:$HOME/pool/cuda/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/pack/nvidia-cl/OpenCL/common/lib/Linux64

echo "---------------------------------------------------------"
echo "NON-MPI TESTS"
echo "---------------------------------------------------------"
python `which py.test` \
  `./repotool list-all` -k -mpi > "../$NOMPI_LOGFILE" 2>&1 || true
echo "---------------------------------------------------------"
echo "MPI TESTS"
echo "---------------------------------------------------------"
python `which py.test` \
  `./repotool list-all` -k mpi > "../$MPI_LOGFILE" 2>&1 || true
