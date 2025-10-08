#!/bin/bash

docker_compose_runner() {
	local COMMAND=$1

	env_file_load

	if [[ $ENV_MODE == "local" ]]; then
		DOCKER_COMPOSE_FILE="docker-compose-local.yml"
	else
		DOCKER_COMPOSE_FILE="docker-compose.yml"
	fi

	docker compose --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE $COMMAND
}

get_docker_ip() {
	local container_name=$1

	env_file_load

	if [ -z "$container_name" ]; then
		return 1
	fi

	DOCKER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null)

	if [ -z "$DOCKER_IP" ]; then
		return 1
	fi

	export DOCKER_IP
	return 0
}
