#!/bin/bash

###############################################################################
# This script installs rustup
###############################################################################

set -e

###############################################################################
# Define Environment Variables
###############################################################################
SCRIPT_NAME=$(basename "$0")
RUSTUP="${CARGO_HOME:-"$HOME/.cargo"}/bin/rustup"
ARM_PACKAGE=
BUILD_REPOSITORY_LOCALPATH=${BUILD_REPOSITORY_LOCALPATH:-$DIR/../../..}
PROJECT_ROOT=${BUILD_REPOSITORY_LOCALPATH}

###############################################################################
# Print usage information pertaining to this script and exit
###############################################################################
function usage()
{
    echo "$SCRIPT_NAME [options]"
    echo ""
    echo "options"
    echo " -h,  --help                   Print this help and exit."
    echo " -p,  --package-arm            Add additional dependencies for armhf packaging"
    echo " --project-root                The project root of the desired build"
    exit 1;
}

###############################################################################
# Install Rust
###############################################################################
function install_rust()
{
    if ! command -v "$RUSTUP" >/dev/null; then
        echo "Installing rustup"
        curl https://sh.rustup.rs -sSf | sh -s -- -y
    fi

    # Forcibly install the toolchain specified in the rust-toolchain file.
    #
    # rustup automatically installs a missing toolchain, so it would seem we don't have to do this.
    # However, Azure Devops VMs have stable pre-installed, and it's not necessarily latest stable.
    # If we let rustup auto-install the toolchain, it would continue to use the old pre-installed stable.
    #
    # We could check if the toolchain file contains "stable" and conditionally issue a `rustup update stable`,
    # but it's simpler to just always `update` whatever toolchain it is. `update` installs the toolchain
    # if it hasn't already been installed, so this also works for pinned versions.
    source $HOME/.cargo/env
    rustup update "$(rustup show active-toolchain | sed 's/ .*//')"
}

###############################################################################
# Obtain and validate the options supported by this script
###############################################################################
function process_args()
{
    save_next_arg=0
    for arg in "$@"
    do
        if [ ${save_next_arg} -eq 1 ]; then
            PROJECT_ROOT=${PROJECT_ROOT}/$arg
            save_next_arg=0
        else
            case "$arg" in
                "-h" | "--help" ) usage;;
                "-p" | "--package-arm" ) ARM_PACKAGE=1;;
                "--project-root" ) save_next_arg=1;;
                * ) usage;;
            esac
        fi
    done
}

process_args "$@"

install_rust

# Install OpenSSL, curl and uuid and valgrind
sudo apt-get update || :
sudo apt-get install -y \
    pkg-config \
    uuid-dev curl \
    libcurl4-openssl-dev \
    libssl-dev \
    debhelper \
    valgrind
