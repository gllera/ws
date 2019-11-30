FROM centos:7 AS base

RUN  yum -y install https://centos7.iuscommunity.org/ius-release.rpm \
 &&  yum -y update \
 &&  yum -y groupinstall "Development tools" \
 &&  yum -y remove git rsync \
 &&  yum -y install wget git2u rsync libevent fuse-libs fuse glibc-static ncurses-devel pcre-devel xz-devel zlib-devel libffi-devel libevent-devel bzip2-devel openssl-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel \
 &&  yum clean all \
 &&  rm -rf /var/cache/yum \
 &&  rm -rf /tmp/*

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

FROM builder AS ag
RUN  wget https://geoff.greer.fm/ag/releases/the_silver_searcher-2.2.0.tar.gz
RUN  tar xvf *
RUN  cd */ && ./configure
RUN  cd */ && make -j `nproc`
RUN  cd */ && make install
RUN  tar cvf root.tar /usr/local

FROM builder AS tmux
RUN  wget https://github.com/tmux/tmux/releases/download/3.0/tmux-3.0.tar.gz
RUN  tar xvf *
RUN  cd */ && ./configure
RUN  cd */ && make -j `nproc`
RUN  cd */ && make install
RUN  tar cvf root.tar /usr/local

FROM builder AS zsh
RUN  wget http://www.zsh.org/pub/zsh-5.7.1.tar.xz
RUN  tar xvf *
RUN  cd */ && ./configure --with-tcsetpgrp
RUN  cd */ && make -j `nproc`
RUN  cd */ && make install
RUN  tar cvf root.tar /usr/local

FROM builder AS python3
RUN  wget https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tar.xz
RUN  tar xvf *
RUN  cd */ && ./configure --with-lto --enable-optimizations --with-ensurepip=yes
RUN  cd */ && make -j `nproc`
RUN  cd */ && make install
RUN  tar cvf root.tar /usr/local

FROM base as binaries
WORKDIR /tmp
COPY  --from=tmux    /app/root.tar tmux.tar
COPY  --from=zsh     /app/root.tar zsh.tar
COPY  --from=dckr    /app/root.tar dckr.tar
COPY  --from=nvim    /app/root.tar nvim.tar
COPY  --from=ag      /app/root.tar ag.tar
COPY  --from=python3 /app/root.tar python3.tar
RUN  for i in *; do tar xvfk $i -C /; done

FROM base

RUN  yum -y update \
 &&  yum -y install openssh-server which sudo sshpass btrfs-progs e2fsprogs e2fsprogs-extra iptables xfsprogs xz pigz zfs words \
 &&  yum clean all \
 &&  rm -rf /var/cache/yum \
 &&  rm -rf /tmp/*

COPY  --from=binaries /usr/local /usr/local
COPY  zsh/* entrypoint.sh /etc/
COPY  zshrc               /etc/skel/.zshrc
COPY  dind                /usr/local/bin/

RUN  groupadd -g 498 docker \
 &&  groupadd -g 499 dockremap \
 &&  groupadd -g 1000 one \
 &&  useradd  -g dockremap -u 499 dockremap \
 &&  useradd  -g one -G docker -rmd /home/one -u 1000 one \
 &&  echo "/usr/local/bin/zsh"            >> /etc/shells \
 &&  echo "dockremap:165536:65536"        >> /etc/subuid \
 &&  echo "dockremap:165536:65536"        >> /etc/subgid \
 &&  echo "one ALL=(ALL) NOPASSWD: ALL"   >> /etc/sudoers \
 &&  echo "one:one" | chpasswd \
 &&  ln -s /usr/local/bin/nvim      /usr/local/bin/vim \
 &&  chsh -s /usr/local/bin/zsh one \
 &&  /usr/local/bin/python3 -m pip install --upgrade pip \
 &&  /usr/local/bin/python3 -m pip install pynvim

EXPOSE 2375
EXPOSE 22

CMD ["/etc/entrypoint.sh"]
