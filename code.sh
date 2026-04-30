#!/usr/bin/env sh

VSCODE_PATH="/usr/share/code"
ELECTRON="$VSCODE_PATH/code"
CLI="$VSCODE_PATH/resources/app/out/cli.js"

ELECTRON_RUN_AS_NODE=1 "$ELECTRON" "$CLI" "$@" --no-sandbox
