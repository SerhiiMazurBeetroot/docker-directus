#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_install() {
	# Update the system
	yum update -y

	# Install Docker
	yum install -y docker
	service docker start
	usermod -a -G docker ec2-user

	# Enable Docker to start on boot
	systemctl enable docker

	# Define variables for Docker Compose installation
	DOCKER_COMPOSE_VERSION="2.23.3"
	DOCKER_CONFIG=${DOCKER_CONFIG:-/usr/local/lib/docker/cli-plugins}

	# Install Docker Compose v2
	mkdir -p $DOCKER_CONFIG
	curl -SL "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o $DOCKER_CONFIG/docker-compose
	chmod +x $DOCKER_CONFIG/docker-compose
}

git_install() {
	# Install Git and Make
	yum install -y git make
}
