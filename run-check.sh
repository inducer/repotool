#! /bin/bash

set -e

MYSELF=$(readlink -f $0)

mkdir -p /tmp/regression-check
cd /tmp/regression-check

RUN_ID="run-`date +%Y-%m-%d-%H%M`"

function setup_log_names()
{
  # assumes $RUN_ID is set

  PLAIN_LOGFILE="$RUN_ID-plain.log"
  MPI_LOGFILE="$RUN_ID-mpi.log"
  CL_LOGFILE="$RUN_ID-cl.log"
  CUDA_LOGFILE="$RUN_ID-cuda.log"
  ALL_PYTEST_LOGFILES="$PLAIN_LOGFILE $MPI_LOGFILE $CL_LOGFILE $CUDA_LOGFILE"
}
setup_log_names

if ! test "$1" = "--log-ok"; then
  LOGFILE="$RUN_ID.log"

  if timelimit -t 36000 $MYSELF --log-ok $RUN_ID > $LOGFILE 2>&1; then
    test_ok=1
    for logfile in $ALL_PYTEST_LOGFILES; do 
      if ! tail -n 1 $logfile | egrep '= [0-9]* passed'; then
        test_ok=0
        break
      fi
    done
  else
    test_ok=0
  fi

  if test "$test_ok" = 1; then
    echo "CHECK OK"

    mutt -s "Regression Check Ok" \
      -a $ALL_PYTEST_LOGFILES "$LOGFILE" -- \
      hedge@tiker.net <<EOF
Hi there,

No failures were encountered during the regression check.

- The seven testing dwarves
EOF
    exit 0
  else
    echo "CHECK FAILED"

    touch $ALL_PYTEST_LOGFILES $LOGFILE
    mutt -s "Regression Check Failed" \
      -a $ALL_PYTEST_LOGFILES "$LOGFILE" -- \
      hedge@tiker.net <<EOF
Hi there,

I'm sorry to report that the regression check failed.
Details are attached.

- Your guilty conscience
EOF
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
setup_log_names

echo "---------------------------------------------------------"
echo "cloning repotool and subrepositories"
echo "---------------------------------------------------------"
git clone --quiet http://git.tiker.net/trees/repotool.git "$RUN_ID"
cd "$RUN_ID"
./repotool clone http://git.tiker.net/trees/ .git
./repotool setup-env
eval `./repotool env`
./repotool for-all -v git log -1 --pretty=format:%h,%ar,%s%n --no-color
echo "---------------------------------------------------------"
echo "installing prerequsistes"
echo "---------------------------------------------------------"
easy_install -U py
easy_install http://tiker.net/hedgestuff/mpi4py-1.1.0patch.tar.gz
echo "---------------------------------------------------------"
echo "building"
echo "---------------------------------------------------------"
./repotool install 

export LD_LIBRARY_PATH=$HOME/pool/lib
export PATH=$PATH:$HOME/pool/cuda/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/pack/nvidia-cl/OpenCL/common/lib/Linux64

function run_tests()
{
  this_logfile="$1"
  shift
  echo "---------------------------------------------------------"
  echo "TESTS FOR $this_logfile"
  echo "---------------------------------------------------------"
  python `which py.test` \
    `./repotool list-all` "$@" > "../$this_logfile" 2>&1 || true

}

run_tests $PLAIN_LOGFILE -k "-mpi -cl -cuda"
run_tests $MPI_LOGFILE -k "mpi -cl -cuda"
run_tests $CUDA_LOGFILE -k "-mpi -cl cuda"
run_tests $CL_LOGFILE -k "-mpi cl -cuda"
echo "---------------------------------------------------------"
echo "Finished at:"
date
echo "---------------------------------------------------------"
