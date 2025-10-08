#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

check_db_exists() {
	DB_EXISTS=$(docker exec -i "$DB_HOST" psql -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q "1" && echo true || echo false)
}

check_db_host() {
	DB_HOST_EXISTS=$(pg_isready -h "$DB_HOST" || true)
}

check_db_container() {
	DB_CONTAINER_EXISTS="$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DB_HOST'($)')"
}

exec_psql_command() {
	local sql="$1"
	local db="${2:-$DB_NAME}" # Optional DB name (default to $DB_NAME)
	local flags="${3:-}"      # Optional flags (default to '')

	case "$SCRIPT_MODE" in
	"psql")
		PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$db" "$flags" -c "$sql"
		;;
	"docker")
		docker exec -i "$DB_HOST" env PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$db" $flags -c "$sql"
		;;
	esac
}

print_connection_info() {
	EMPTY_LINE
	print_log "ENV_MODE: $ENV_MODE"
	print_log "DB_HOST: $DB_HOST"
	print_log "DB_USER: $DB_USER"
	print_log "DB_NAME: $DB_NAME" "text" "1"
}
