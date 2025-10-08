#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

psql_install() {
    # Install the needed packages to build the client libraries from source
    sudo yum install -y gcc readline-devel libicu-devel zlib-devel openssl-devel

    # Download the source, you can browse the source code for other PostgreSQL versions (e.g. 16.2)
    wget https://ftp.postgresql.org/pub/source/v16.1/postgresql-16.1.tar.gz # PostgreSQL 16.1
    tar -xvzf postgresql-16.1.tar.gz

    cd postgresql-16.1

    # Set bin dir so that executables are put in /usr/bin where psql and the others are installed by RPM
    ./configure --bindir=/usr/bin --with-openssl

    sudo make -C src/bin install
    sudo make -C src/include install
    sudo make -C src/interfaces install
}
