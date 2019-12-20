FROM debian:10 AS base

RUN  export DEBIAN_FRONTEND=noninteractive \
 &&  apt-get update \
 &&  apt-get install -y apt-utils dialog man-db manpages glibc-doc \
 &&  apt-get install -y git rsync silversearcher-ag zsh sshpass python3 python3-pip \
 &&  apt-get install -y sudo iptables apt-transport-https fuse wget curl openssh-server python3-neovim build-essential libevent-dev libncurses5-dev wamerican \
 &&  update-alternatives --set iptables /usr/sbin/iptables-legacy \
 &&  python3 -m pip install pynvim

FROM base as builder
WORKDIR /app
RUN  rm -rf /usr/local
RUN  mkdir -p /usr/local/bin

FROM builder AS dckr
RUN  wget https://download.docker.com/linux/static/stable/x86_64/docker-19.03.5.tgz
RUN  tar xvf * --strip 1 -C /usr/local/bin
RUN  tar cvf root.tar /usr/local

FROM builder AS nvim
RUN  wget https://github.com/neovim/neovim/releases/download/v0.4.3/nvim-linux64.tar.gz -O root.tar
RUN  tar xvf * --strip 1 -C /usr/local
RUN  tar cvf root.tar /usr/local

FROM builder AS tmux
RUN  wget https://github.com/tmux/tmux/releases/download/3.0/tmux-3.0.tar.gz
RUN  tar xvf *
RUN  cd */ && ./configure
RUN  cd */ && make -j `nproc`
RUN  cd */ && make install
RUN  tar cvf root.tar /usr/local

FROM base as binaries
WORKDIR /tmp
COPY  --from=tmux    /app/root.tar tmux.tar
COPY  --from=dckr    /app/root.tar dckr.tar
COPY  --from=nvim    /app/root.tar nvim.tar
RUN  for i in *; do tar xvfk $i -C /; done
RUN  chown -R root:root /usr/local


FROM base
COPY  --from=binaries /usr/local /usr/local
COPY  dind                       /usr/local/bin/
COPY  entrypoint.sh              /etc/

RUN  groupadd -g 498 docker \
 &&  groupadd -g 499 dockremap \
 &&  groupadd -g 1000 one \
 &&  useradd  -g dockremap -u 499 dockremap \
 &&  useradd  -g one -G docker -rmd /home/one -u 1000 one \
 &&  echo "dockremap:165536:65536"        >> /etc/subuid \
 &&  echo "dockremap:165536:65536"        >> /etc/subgid \
 &&  echo "one ALL=(ALL) NOPASSWD: ALL"   >> /etc/sudoers \
 &&  echo "one:one" | chpasswd \
 &&  rm -f /etc/update-motd.d/* /etc/motd \
 &&  ln -s /usr/local/bin/nvim /usr/local/bin/vim \
 &&  chsh -s /usr/bin/zsh one \
 &&  mkdir -p /var/run/sshd \
 &&  sed -i 's/#GatewayPorts.*/GatewayPorts clientspecified/' /etc/ssh/sshd_config \
 &&  mandb


EXPOSE 2375
EXPOSE 22

CMD ["/etc/entrypoint.sh"]
