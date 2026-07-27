#!/usr/bin/env bash
#
# nsite installer — one command instead of clone + chmod + symlink.
#
#   curl -fsSL https://raw.githubusercontent.com/csemazharul/nsite/main/install.sh | bash
#
# Or from a local checkout:   ./install.sh
# Uninstall:                  ./install.sh --uninstall
#
set -euo pipefail

REPO_URL="https://github.com/csemazharul/nsite"
INSTALL_DIR="${NSITE_INSTALL_DIR:-$HOME/.local/share/nsite}"
BIN_DIR="${NSITE_BIN_DIR:-/usr/local/bin}"

say() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# sudo only when the target isn't writable by the current user
as_owner() {
    if [[ -w "$BIN_DIR" ]]; then "$@"; else sudo "$@"; fi
}

uninstall() {
    say "removing $BIN_DIR/nsite"
    as_owner rm -f "$BIN_DIR/nsite"
    say "done. Also remove, if you want:"
    printf '  rm -rf %s                # the code\n' "$INSTALL_DIR"
    printf '  # the "source .../nsite-completion.bash" line in ~/.bashrc\n'
    printf 'sites created with nsite keep working — remove them with: nsite rm <name>\n'
    exit 0
}

if [[ "${1:-}" == "--uninstall" ]]; then uninstall; fi
if [[ "$EUID" -eq 0 ]]; then die "run as a normal user — sudo is used only where needed"; fi

# --- locate or fetch the code ----------------------------------------------

# When run from inside a checkout (./install.sh), install from right here.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)"
if [[ -f "$script_dir/nsite" ]]; then
    INSTALL_DIR="$script_dir"
    say "installing from local checkout: $INSTALL_DIR"
elif [[ -d "$INSTALL_DIR/.git" ]]; then
    say "updating existing install in $INSTALL_DIR"
    git -C "$INSTALL_DIR" pull --ff-only
else
    command -v git >/dev/null || die "git is required (sudo apt install git)"
    say "cloning $REPO_URL to $INSTALL_DIR"
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
fi

# --- install ----------------------------------------------------------------

chmod +x "$INSTALL_DIR/nsite"

say "linking $BIN_DIR/nsite -> $INSTALL_DIR/nsite"
as_owner ln -sfn "$INSTALL_DIR/nsite" "$BIN_DIR/nsite"

# tab completion: offer when interactive, skip silently when piped
completion_line="source $INSTALL_DIR/nsite-completion.bash"
if ! grep -qF "nsite-completion.bash" "$HOME/.bashrc" 2>/dev/null; then
    if [[ -t 0 ]]; then
        read -r -p "enable tab completion in ~/.bashrc? [Y/n] " reply
        if [[ ! "$reply" =~ ^[Nn] ]]; then
            printf '%s\n' "$completion_line" >> "$HOME/.bashrc"
            say "completion enabled (open a new terminal to use it)"
        fi
    else
        printf 'tip: enable tab completion with:\n  echo '\''%s'\'' >> ~/.bashrc\n' "$completion_line"
    fi
fi

# --- verify -----------------------------------------------------------------

"$BIN_DIR/nsite" --version >/dev/null || die "installed, but running nsite failed"
say "installed: $("$BIN_DIR/nsite" --version)"
say "next steps:"
printf '  nsite doctor      # check your nginx/PHP setup\n'
printf '  nsite add <name>  # create your first site\n'
