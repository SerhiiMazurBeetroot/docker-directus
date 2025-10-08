#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

database_import_menu() {
	EMPTY_LINE
	ECHO_CYAN "======== Import DB ======="
	ECHO_RED "This action will replace you ["$ENV_MODE"] DB"

	ECHO_YELLOW "Are you sure?"
	ECHO_GREEN "1 - Yes"
	ECHO_GREEN "2 - No"

	local choice_import=$(GET_USER_INPUT "select_one_of")

	if [[ "$choice_import" = "1" ]]; then
		database_import "$@"

		# docker_compose_runner "restart"
	fi
}

database_import() {
	EMPTY_LINE
	ECHO_TEXT "Running fn [database_import] for [$ENV_MODE]"

	local database_dir=${1:-$DATABASE_BACKUP_DIR}

	if [[ -d "$database_dir" ]]; then
		ECHO_YELLOW "DB DIR ['$database_dir'] exists"

		# get_db_file
		DB_FILES=("$database_dir"/*.dump)

		if [ ${#DB_FILES[@]} -gt 1 ]; then
			ECHO_ERROR "More than one .dump file found. Delete old one"

			database_menu
		fi

		for file in "${DB_FILES[@]}"; do
			DB_FILE="$(basename "$file")"
		done

		if [[ -f "$database_dir/$DB_FILE" ]]; then
			env_file_load

			ECHO_YELLOW "Getting DB from ['$database_dir'] and updating local"
			ECHO_CYAN "Using DB_FILE: [$DB_FILE]"
			EMPTY_LINE

			create_role_if_not_exists "$DB_USER"

			case "$ENV_MODE" in
			"local")
				database_import_docker
				;;
			"prod")
				database_import_psql
				;;
			esac

		else
			ECHO_ERROR "DB file not found"
		fi
	else
		ECHO_ERROR "DB directory not found"
	fi

}

database_import_docker() {
	check_db_container

	if [ "$DB_CONTAINER_EXISTS" ]; then
		ECHO_TEXT "Running fn [database_import_docker] for [$ENV_MODE]"

		ECHO_GREEN "Docker DB container exists"
		EMPTY_LINE
		ECHO_TEXT "DB collected, inserting it to the SQL container"
		docker cp "$database_dir/$DB_FILE" "$DB_HOST":/docker-entrypoint-initdb.d/$DB_NAME.dump

		# Full
		docker exec -i "$DB_HOST" bash -c "$(declare -f database_import_postgres); database_import_postgres $DB_NAME $DB_USER"

		EMPTY_LINE
		ECHO_SUCCESS "DB [$DB_NAME] was imported from: [$database_dir/$DB_FILE]"

		docker_compose_runner "restart"
	else
		ECHO_ERROR "DB container is not running"
	fi
}

database_import_psql() {
	print_log "Running fn [database_import_psql]"

	ENV_MODE=prod

	get_timestamp
	env_file_load

	TEMP_DB="temp_db_$DB_NAME"
	DB_NAME_BACKUP=${DB_NAME}_backup

	import_prepare

	PGPASSWORD="$DB_PASSWORD" pg_restore \
		-h "$DB_HOST" \
		-U "$DB_USER" -F c -d "$TEMP_DB" \
		<$database_dir/$DB_FILE

	if [ $? -eq 0 ]; then
		print_log "Successfully imported: [$TEMP_DB]"

		# Terminate connections
		terminate_connections "$DB_NAME"
		terminate_connections "$TEMP_DB"
		terminate_connections "$DB_NAME_BACKUP"

		# Drop temporary database if it exists
		print_log "Drop previous database backup if it exists [$DB_NAME_BACKUP]"
		local drop_table_sql="DROP DATABASE IF EXISTS $DB_NAME_BACKUP;"
		exec_psql_command "$drop_table_sql" "$DB_NAME"

		# Rename DB
		local rename_main_sql="ALTER DATABASE $DB_NAME RENAME TO ${DB_NAME_BACKUP};"
		exec_psql_command "$rename_main_sql" "postgres"

		local rename_temp_sql="ALTER DATABASE $TEMP_DB RENAME TO $DB_NAME;"
		exec_psql_command "$rename_temp_sql" "postgres"

		print_log "Successfully DB [$DB_NAME] RENAME TO ${DB_NAME_BACKUP}"
		print_log "Successfully DB [$TEMP_DB] RENAME TO ${DB_NAME}"
	else
		print_log "Failed to import: [$TEMP_DB]" "error"
	fi
}
