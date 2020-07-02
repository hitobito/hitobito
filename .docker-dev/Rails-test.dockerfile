FROM hitobito-dev/rails

RUN yum install -y epel-release
RUN INSTALL_PKGS="chromium xorg-x11-server-Xvfb" && \
  yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
  rpm -V $INSTALL_PKGS && \
  yum -y clean all --enablerepo='*'
