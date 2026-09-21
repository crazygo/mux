#!/usr/bin/env sh
# Install mux. Safe to re-run; never overwrites an existing config.
set -eu

BIN_DIR="${MUX_BIN_DIR:-$HOME/.local/bin}"
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"

mkdir -p "$BIN_DIR"
install -m 755 "$SCRIPT_DIR/mux" "$BIN_DIR/mux"

# Seed the config on first install only.
"$BIN_DIR/mux" init >/dev/null 2>&1 || true

printf 'installed %s\n' "$BIN_DIR/mux"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) printf '\n%s is not on PATH. Add to your shell profile:\n  export PATH="%s:$PATH"\n' "$BIN_DIR" "$BIN_DIR" ;;
esac

printf '\n'
"$BIN_DIR/mux"
