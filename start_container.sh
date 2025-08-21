#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

set +o errexit
git_user_name=`git config --global --get user.name`
set -o errexit


if [[ "$git_user_name" == "" ]]
then
    echo "I could not resolve your git global user.name. Please input it now:"
    read git_user_name
fi

docker run \
  --rm \
  -it \
  --net=host \
  -v /etc/localtime:/etc/localtime:ro \
  -v `pwd`/conf/dialplan/default/:/usr/local/freeswitch/conf/dialplan/default \
  -v `pwd`/conf/dialplan/public/:/usr/local/freeswitch/conf/dialplan/public \
  -v `pwd`/scripts:/usr/local/freeswitch/scripts \
  -v `pwd`/..:/home/$git_user_name/src/git \
  -w /home/$git_user_name/src/git/learning-freeswitch \
  freeswitch-with-sngrep2


