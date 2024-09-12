# ROS image, ros-humble-ros-core package installed
# on Ubuntu Jammy
# https://hub.docker.com/_/ros/
FROM ros:humble-ros-core-jammy

# change shell to bash
SHELL ["/bin/bash", "-c"]

######################
# WORK FILES
######################

WORKDIR $HOME
COPY ./ ./

######################
# ROS2 Humble Install
######################

# Using the ROS docker image
# It is no longer necessary to install ROS2
# or source.
# The ROS2 image makes use of an entrypoint script

# See the dockerfile here:
# https://github.com/osrf/docker_images/tree/20e3ba685bb353a3c00be9ba01c1b7a6823c9472/ros/humble/ubuntu/jammy 

#####################
# Packages install
#####################

# Update packages repositories
RUN apt update
# Add standard packages
RUN apt install -y software-properties-common
RUN add-apt-repository -y universe
# Update the repositories again
RUN apt update

#####################
# Install packages
#####################

# Add standard packages
RUN add-apt-repository -y universe
# Update packages repositories
RUN apt update
# Repository keys & certificates
RUN apt install -y ca-certificates gnupg
RUN mkdir -p /etc/apt/keyrings
# common software properties, curl, make, build-essentials, cmake
RUN apt install -y \
    software-properties-common \
    curl \
    make \
    build-essential \
    cmake

# Add colcon repository
# https://colcon.readthedocs.io/en/released/user/installation.html
RUN echo "deb [arch=amd64,arm64] http://repo.ros2.org/ubuntu/main `lsb_release -cs` main" > /etc/apt/sources.list.d/ros2-latest.list
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

# Add nodejs repository
# Specifically the node_18.x repo, for the supported rclnodejs version
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
# Add nodejs repo key
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

########################
# Update repositories
########################

RUN apt update

# install runtimes
RUN apt install -y \
    python3-colcon-common-extensions \
    nodejs

# Enable yarn
RUN npm install -g corepack
RUN corepack enable

# Install python and pip
# we need python-is-python3 because poetry invokes python3 with `python`
# we also need python's development headers to build wheels
RUN apt install -y \
    python3 \
    python3-pip \
    python-is-python3 \
    python3-dev \
    python3-poetry

# Install extra required python packages that pip can't install
# dotenv is required for our flask config
RUN apt install -y \
    python3-dotenv \
    ros-humble-cv-bridge
