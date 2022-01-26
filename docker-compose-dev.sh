#!/usr/bin/env sh
set -e

INFRACOST_REPO=${INFRACOST_REPO:-"../infracost"}
pwd=$(pwd)

cd $INFRACOST_REPO
make linux
cd $pwd
cp $INFRACOST_REPO/build/infracost-linux-amd64 infracost
cp $INFRACOST_REPO/scripts/ci/atlantis_diff.sh infracost_atlantis_diff.sh

docker-compose up -d

