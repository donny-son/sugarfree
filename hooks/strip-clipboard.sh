#!/usr/bin/env bash
#
# strip-clipboard.sh — clean formatting sugar off the system clipboard in place.
#
# A thin wrapper around `sugarfree --clipboard`. Bind it to a global keyboard
# shortcut, run it from a cron/launchd job, or call it from an AI-harness hook
# (see hooks/README.md). Strips every sugar by default; pass flags to narrow it.
#
# Usage:
#   hooks/strip-clipboard.sh                  # strip all sugars
#   hooks/strip-clipboard.sh --no-headers     # all except headers
#   SUGARFREE=/path/to/sugarfree hooks/strip-clipboard.sh
set -euo pipefail

SUGARFREE="${SUGARFREE:-sugarfree}"

if ! command -v "$SUGARFREE" >/dev/null 2>&1; then
    echo "strip-clipboard: '$SUGARFREE' not found on PATH." >&2
    echo "Build it with 'swift build -c release' or download a release binary." >&2
    exit 127
fi

# Default to stripping everything; forward any extra flags the caller passes.
if [ "$#" -eq 0 ]; then
    exec "$SUGARFREE" --clipboard --all
else
    exec "$SUGARFREE" --clipboard "$@"
fi
