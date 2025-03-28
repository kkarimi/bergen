#!/bin/bash
# Wrapper that ensures our fix-bundle-script.sh is used
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/fix-bundle-script.sh"
exit $?
