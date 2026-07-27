# nsite

A small bash CLI that manages local nginx dev sites on Debian-style systems
(Ubuntu, Pop!_OS, Debian). One command replaces the usual four manual steps:
write a vhost, symlink it into `sites-enabled/`, add a `/etc/hosts` line, and
`nginx -t && reload`. It also switches the PHP-FPM version per site.

## Design philosophy

- **Additive, not invasive.** nsite only writes files it created (marked with a
  `# managed by nsite` header). It never touches `nginx.conf`, hand-written
  vhosts, or anything else. Uninstalling = deleting one script.
- **Transparent.** Generated vhosts are plain, readable nginx configs you could
  have written by hand. Manual edits are respected — nsite prompts before
  overwriting anything.
- **No hidden state.** No database, no JSON. All state lives in the nginx
  configs themselves (e.g. a site's PHP version is read from its
  `fastcgi_pass` line).

## Status

| Command | Status |
|---|---|
| `nsite help`, `--version` | ✅ working |
| `nsite add / rm / list` | 🚧 phase 1 — not implemented yet |
| `nsite php ...` | 🚧 phase 2 — not implemented yet |
| `--proxy`, `--dry-run`, `--force` | 🚧 phase 3 |
| `install.sh`, `.deb` package | 🚧 phase 4 |

## Requirements

- bash 4+, nginx with the Debian layout (`/etc/nginx/sites-available` +
  `sites-enabled`), PHP-FPM for PHP sites.
- A user with sudo rights. **Do not run nsite itself as root** — it refuses,
  and calls `sudo` only for the few commands that need it (writing configs,
  editing `/etc/hosts`, reloading nginx).

## Install (for now)

```sh
git clone <this repo> ~/www/nsite     # or just copy the script
chmod +x ~/www/nsite/nsite
sudo ln -s ~/www/nsite/nsite /usr/local/bin/nsite   # optional, puts it on PATH
```

## Usage

```
nsite add <name> [--php <version>] [--root <subdir>] [--proxy <port>]
                 [--force] [--dry-run]
nsite rm <name>
nsite list
nsite php list
nsite php use <site> <version>
nsite php cli <version>
nsite php current [site]
nsite help
```

### Examples

```sh
nsite add blog                # serves ~/www/blog at http://blog.test
nsite add shop --php 8.3      # same, pinned to PHP-FPM 8.3
nsite add dash --proxy 3000   # reverse-proxy to a Next.js dev server
nsite php use blog 8.4        # move blog.test to PHP 8.4 (browser only)
nsite rm blog                 # remove config + hosts entry, keep ~/www/blog
```

### `nsite add`

Expects your project at `$WWW/<name>` (default `~/www/<name>`). Document root
auto-detection: `public/` subdirectory if it exists, otherwise the project
root; `--root <subdir>` overrides. Creates the vhost, enables it, adds the
hosts entry, runs `nginx -t`, reloads. If the config test fails, everything
just written is rolled back — nginx is never left broken.

### Site PHP vs CLI PHP — the distinction that matters

- **Site version** (`nsite php use <site> <version>`): which PHP-FPM socket
  nginx forwards to. Affects only what the browser gets for that one site.
- **CLI version** (`nsite php cli <version>`): what `php -v` and composer use
  in your terminal, via `update-alternatives`. Changes **nothing** about what
  any website serves.

They are completely independent. `blog.test` can run 8.3 while your terminal
runs 8.4.

## Configuration

Optional, plain bash, sourced from `${XDG_CONFIG_HOME:-~/.config}/nsite/config`:

```sh
WWW="$HOME/www"   # where projects live
TLD="test"        # sites become <name>.test
PHP_SOCK=""       # empty = auto-detect newest running PHP-FPM socket
```

No config file is needed if the defaults suit you.

## Development

The whole tool is one script: [`nsite`](nsite). Ground rules for changes:

- Must pass `shellcheck` with no warnings (`shellcheck nsite`).
- `set -euo pipefail` stays; quote everything — paths with spaces must work.
- Target is ~300 lines total. If a feature needs more, it belongs elsewhere.
- Never modify configs nsite didn't create; never store state outside the
  nginx configs; every sudo call is per-command, never a blanket escalation.

Quick smoke test:

```sh
bash -n nsite && ./nsite help && ./nsite bogus; echo "exit=$?"   # expect exit=1
```
