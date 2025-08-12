#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

docker run \
  --rm \
  -it \
  --net=host \
  --cap-add=NET_ADMIN \
  -v /etc/localtime:/etc/localtime:ro \
  -v `pwd`/conf/dialplan/public/:/usr/local/freeswitch/conf/dialplan/public \
  -v `pwd`/scripts:/usr/local/freeswitch/scripts \
  -v `pwd`/..:/root/src/git \
  -w /root/src/git/learning-freeswitch \
  freeswitch-with-sngrep2


