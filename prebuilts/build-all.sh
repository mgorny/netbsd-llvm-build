#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

case "$(uname)" in
	Linux|Darwin) "$SCRIPT_DIR/build-libedit.sh" "$@";;
esac

"$SCRIPT_DIR/build-cmake.sh" "$@"
"$SCRIPT_DIR/build-ninja.sh" "$@"
"$SCRIPT_DIR/build-python.sh" "$@"
"$SCRIPT_DIR/build-swig.sh" "$@"
