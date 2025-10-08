#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

export FILE_SETTINGS="./.sh/settings.log"
export DATABASE_BACKUP_DIR="./database/backup"
export FILE_LOGS="./logs/docker/actions.log"
