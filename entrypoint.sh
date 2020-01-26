#!/bin/bash

set_proxy() {
   local i PROXY=http://127.0.0.1:3128
   local VARS="http_proxy https_proxy HTTP_PROXY HTTPS_PROXY"

   for i in $VARS; do
      VAL="$i=$PROXY"

      eval "export $VAL"
      grep -qF -- "$VAL" "/etc/environment" || echo "$VAL" >> "/etc/environment"
   done

   VAL="proxy=$PROXY"
   grep -qF -- "$VAL" "/etc/yum.conf" || echo "$VAL" >> "/etc/yum.conf"
}

[[ -v WS_USE_PROXY ]] && set_proxy
[[ -v WS_SHELL     ]] && chsh -s $(which $WS_SHELL) one
[[ -f /etc/ssh/ssh_host_rsa_key ]] || ssh-keygen -q -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key

find /run /var/run -iname 'docker*.pid' -delete
/usr/sbin/sshd
exec /usr/local/bin/dind dockerd --storage-driver=overlay2 --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375
