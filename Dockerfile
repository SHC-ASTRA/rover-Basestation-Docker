# using image with ros humble already installed
# https://hub.docker.com/_/ros/
FROM ros:humble-ros-core-jammy

# change shell to bash
SHELL ["/bin/bash", "-c"]


###########################
# INSTALL SYSTEM PACKAGES #
###########################

# add standard packages
RUN yes | unminimize
RUN apt-get update && apt-get -y upgrade
RUN apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y universe

# add development tools (this is a dev container)
RUN apt-get update \
    && apt-get install -y curl make build-essential \
    cmake git vim sudo g++ man-db bash-completion \
    jq unzip gnupg2 ca-certificates

# install docker
RUN apt-get update \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && groupadd docker

# add colcon
# see: <https://colcon.readthedocs.io/en/released/user/installation.html>
RUN echo "deb [arch=amd64,arm64] http://repo.ros2.org/ubuntu/main `lsb_release -cs` main" > /etc/apt/sources.list.d/ros2-latest.list \
    && curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - \
    && apt-get update \
    && apt-get install -y python3-colcon-common-extensions

# add ros-dev-tools for development toolchain
RUN apt-get update \
    && apt-get install -y ros-dev-tools ros-humble-demo-nodes-cpp ros-humble-rmw-cyclonedds-cpp

# install python build requirements for pyenv
# see: <https://github.com/pyenv/pyenv/wiki#suggested-build-environment>
RUN apt-get update \
    && apt-get install -y \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev \
    libxmlsec1-dev libffi-dev liblzma-dev \
    debian-keyring debian-archive-keyring apt-transport-https

# install starship (better bash prompt)
RUN curl -sS https://starship.rs/install.sh | sudo sh -s -- -y

# set up astra user
RUN useradd -m -U astra \
    && usermod -a -G sudo astra \
    && usermod -a -G docker astra \
    && chsh -s /usr/bin/bash astra \
    && passwd -d astra


###########################
# SWITCH TO NON-ROOT USER #
###########################

USER astra

# python stuff first for better caching (it takes eons)
# install pyenv
ENV PYENV_ROOT="/home/astra/.pyenv"
RUN curl https://pyenv.run | bash

# install python
ENV PY_VERSION=3.10
RUN $PYENV_ROOT/bin/pyenv install $PY_VERSION -v \
    && $PYENV_ROOT/bin/pyenv global $PY_VERSION

# install poetry
RUN $PYENV_ROOT/bin/pyenv exec pip install -U pipx \
    && $PYENV_ROOT/bin/pyenv exec python -m pipx install poetry

# install required packages for colcon builds
RUN $PYENV_ROOT/bin/pyenv exec pip install -U \
    'empy>=3.3.4,<3.4.0' \
    'catkin-pkg>=1.0.0,<1.1.0' \
    'lark>=1.2.2,<1.3.0' \
    'numpy>=2.2.4,<2.3.0'

# install nvm
# node version manager
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# install specific node version and npm
ENV NODE_VERSION=20
RUN source ~/.nvm/nvm.sh \
    && nvm install $NODE_VERSION --latest-npm \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# set up bashrc
# link the repository .bashrc over the default Ubuntu
RUN rm ~/.bashrc && ln -s /release/.devcontainer/.bashrc ~/.bashrc

