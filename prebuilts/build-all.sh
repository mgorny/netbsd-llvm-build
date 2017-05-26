#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

"$SCRIPT_DIR/build-libedit.sh" "$@"
"$SCRIPT_DIR/build-ninja.sh" "$@"
"$SCRIPT_DIR/build-python.sh" "$@"
"$SCRIPT_DIR/build-swig.sh" "$@"

"$SCRIPT_DIR/build-libglog.sh" "$@"
"$SCRIPT_DIR/build-protobuf.sh" "$@"
# broken # "$SCRIPT_DIR/build-breakpad.sh" "$@"
