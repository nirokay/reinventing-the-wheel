#!/usr/bin/env bash
# This script renames the executables and installs them.

EXEC_PREFIX="k"
INSTALL_DIR=~/.local/bin
BIN_DIR=./bin

nimble release

function installFile() {
    PATH="$*"
    NAME=$(/usr/bin/basename "$PATH")
    NEW_NAME="$EXEC_PREFIX$NAME"

    /usr/bin/cp "$PATH" "$INSTALL_DIR/$NEW_NAME" && echo "Installed '$NAME' as '$NEW_NAME' to '$INSTALL_DIR'."
}

for FILE in ./bin/*; do
    if [ "$FILE" != ".gitkeep" ]; then
        installFile "$FILE"
    fi
done
