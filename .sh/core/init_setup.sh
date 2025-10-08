#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

replace_variables() {
	if [[ -f $ENV_FILE ]]; then
		# ─────────────────────────────────────────────
		# Generate PORTs
		# ─────────────────────────────────────────────
		NGINX_PORT=$(find_free_port 80)
		APP_PORT=$(find_free_port 8055)
		PMA_PORT=$(find_free_port 8090)

		sed -i -e "s/{APP_PORT}/$APP_PORT/g" "$ENV_FILE"
		sed -i -e "s/{PMA_PORT}/$PMA_PORT/g" "$ENV_FILE"
		sed -i -e "s/{NGINX_PORT}/$NGINX_PORT/g" "$ENV_FILE"

		sed -i -e 's/{COMPOSE_PROJECT_NAME}/'$COMPOSE_PROJECT_NAME'/g' "$ENV_FILE"
		sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' "$ENV_FILE"
		sed -i -e 's/{DIRECTUS_VERSION}/'$DIRECTUS_VERSION'/g' "$ENV_FILE"

		sed -i -e 's/{ADMIN_EMAIL}/'$ADMIN_EMAIL'/g' "$ENV_FILE"
		sed -i -e 's/{ADMIN_PASSWORD}/'$ADMIN_PASSWORD'/g' "$ENV_FILE"

		sed -i -e 's/{DB_NAME}/'$DB_NAME'/g' "$ENV_FILE"
		sed -i -e 's/{DB_USER}/'$DB_USER'/g' "$ENV_FILE"
		sed -i -e 's/{DB_PASSWORD}/'$DB_PASSWORD'/g' "$ENV_FILE"

		sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' "nginx/directus.conf"

		# ─────────────────────────────────────────────
		# Generate secure random KEY and SECRET
		# ─────────────────────────────────────────────
		key=$(generate_random_string 32)
		secret=$(generate_random_string 64)

		sed -i -e "s|{changeme_32_chars_minimum_random}|$key|g" "$ENV_FILE"
		sed -i -e "s|{changeme_64_chars_minimum_random}|$secret|g" "$ENV_FILE"

		ECHO_SUCCESS "Updated [$ENV_FILE]"
	else
		ECHO_ATTENTION "[$ENV_FILE] not found"
	fi

	if [ -f docker-compose.yml ]; then
		sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' docker-compose.yml
	fi

	if [ -f docker-compose.override.yml ]; then
		sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' docker-compose.override.yml
	fi

	if [ -f docker-compose-local.yml ]; then
		sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' docker-compose-local.yml
	fi
}

find_free_port() {
	local port=${1:-8055}
	while is_port_in_use "$port"; do
		port=$((port + 1))
	done
	echo "$port"
}

is_port_in_use() {
	local port=$1

	if command -v netstat >/dev/null 2>&1; then
		netstat -tuln | grep -q ":$port"
		return $?
	else
		ECHO_ATTENTION "Cannot check port usage: no lsof, ss, or netstat found"
		return 1
	fi
}
