# nsite

A small bash CLI that manages local nginx dev sites on Debian-style systems
(Ubuntu, Pop!_OS, Debian). One command replaces the usual four manual steps:
write a vhost, symlink it into `sites-enabled/`, add a `/etc/hosts` line, and
`nginx -t && reload`. It also switches the PHP-FPM version per site and can
add locally-trusted HTTPS via mkcert.

## Documentation

- **[Installation](docs/installation.md)** — requirements, install, completion, uninstall
- **[Getting started](docs/getting-started.md)** — first site, PHP switching, HTTPS, proxy mode, debugging
- **[Command reference](docs/commands.md)** — every command, option, and behavior in detail

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
| `nsite add / rm / list` (incl. `--proxy`, `--dry-run`, `--force`) | ✅ working |
| `nsite php list / use / cli / current` | ✅ working |
| `nsite logs / doctor / secure` | ✅ working |
| Bash completion | ✅ `nsite-completion.bash` |
| `install.sh`, `.deb` package | 🚧 planned |

## Requirements

- bash 4+, nginx with the Debian layout (`/etc/nginx/sites-available` +
  `sites-enabled`), PHP-FPM for PHP sites.
- [mkcert](https://github.com/FiloSottile/mkcert) — only for `nsite secure`.
- A user with sudo rights. **Do not run nsite itself as root** — it refuses,
  and calls `sudo` only for the few commands that need it (writing configs,
  editing `/etc/hosts`, reloading nginx).

## Install

One command:

```sh
curl -fsSL https://raw.githubusercontent.com/csemazharul/nsite/main/install.sh | bash
```

It clones the repo to `~/.local/share/nsite`, links `nsite` onto your PATH
(the only step that may ask for sudo), and offers tab completion. Re-running
it updates to the latest version. To uninstall:

```sh
~/.local/share/nsite/install.sh --uninstall
```

<details>
<summary>Manual install instead</summary>

```sh
git clone https://github.com/csemazharul/nsite ~/www/nsite
chmod +x ~/www/nsite/nsite
sudo ln -s ~/www/nsite/nsite /usr/local/bin/nsite
echo "source ~/www/nsite/nsite-completion.bash" >> ~/.bashrc   # optional
```
</details>

## Usage

```
nsite add <name> [--php <version>] [--root <subdir>] [--proxy <port>]
                 [--tld <tld>] [--force] [--dry-run]
nsite rm <name>
nsite list
nsite php list
nsite php use <site> <version>
nsite php cli <version>
nsite php current [site]
nsite logs <site> [-f]
nsite doctor
nsite secure <site>
nsite unsecure <site>
nsite domain <new-domain>            # site inferred from first label
nsite domain <site> <new-domain>     # explicit, when name ≠ hostname
nsite help
```

### Examples

```sh
nsite add blog                # serves ~/www/blog at http://blog.test
nsite add shop --php 8.3      # same, pinned to PHP-FPM 8.3
nsite add dash --proxy 3000   # reverse-proxy to a Next.js dev server
nsite php use blog 8.4        # move blog.test to PHP 8.4 (browser only)
nsite secure blog             # https://blog.test via mkcert
nsite logs blog -f            # follow blog's access + error logs
nsite doctor                  # check services, sockets, symlinks, hosts entries
nsite rm blog                 # remove config + hosts entry, keep ~/www/blog
nsite add blog --tld dev      # blog.dev instead of blog.test (see TLD note!)
nsite domain blog.dev         # rename site 'blog' to blog.dev
```

### Choosing a TLD

The default `.test` is IETF-reserved and always safe. Anything else has
side effects nsite will warn you about:

- **`.dev`, `.app`** — real Google TLDs on the browser HSTS-preload list:
  plain `http://` will never load; run `nsite secure <site>` for https.
- **`.site`, `.shop`, …** — real public TLDs; your hosts entry shadows any
  real site with the same name.
- **`.local`** — collides with mDNS/Avahi on Linux; resolution can be flaky.

`nsite domain <new-domain>` renames an existing site (the site is inferred
from the domain's first label; pass `<site> <new-domain>` explicitly when
the config name and hostname differ): it rewrites
`server_name`, swaps the hosts entry, and re-issues the mkcert certificate
if the site was secured. Rolls back on `nginx -t` failure like everything
else.

### `nsite add`

Expects your project at `$WWW/<name>` (default `~/www/<name>`). Document root
auto-detection: `public/` subdirectory if it exists, otherwise the project
root; `--root <subdir>` overrides. Creates the vhost, enables it, adds the
hosts entry, runs `nginx -t`, reloads. If the config test fails, everything
just written is rolled back — nginx is never left broken. `--dry-run` prints
the exact config and actions without touching anything.

Proxy mode (`--proxy <port>`) generates a reverse-proxy vhost (with websocket
headers) instead of a PHP one — for Next.js, Vite, FastAPI and friends.

### Site PHP vs CLI PHP — the distinction that matters

- **Site version** (`nsite php use <site> <version>`): which PHP-FPM socket
  nginx forwards to. Affects only what the browser gets for that one site.
- **CLI version** (`nsite php cli <version>`): what `php -v` and composer use
  in your terminal, via `update-alternatives`. Changes **nothing** about what
  any website serves.

They are completely independent. `blog.test` can run 8.3 while your terminal
runs 8.4.

### `nsite secure`

Runs mkcert for the site's hostname, installs the cert under
`/etc/nginx/nsite-certs/`, and adds the `listen 443 ssl` + certificate lines
to the site's config. Only works on nsite-managed configs — it refuses to
edit hand-written ones. Idempotent: already-secured sites are left alone.

## Configuration

Optional, plain bash, sourced from `${XDG_CONFIG_HOME:-~/.config}/nsite/config`:

```sh
WWW="$HOME/www"   # where projects live
TLD="test"        # sites become <name>.test
PHP_SOCK=""       # empty = auto-detect newest running PHP-FPM socket
```

No config file is needed if the defaults suit you.

## Non-goals

- No dnsmasq / wildcard DNS — hosts entries are explicit lines in `/etc/hosts`.
- No database provisioning, PHP installation, or project scaffolding.
- No daemon, no background anything. It's a script.

## Development

The whole tool is one script: [`nsite`](nsite). Ground rules for changes:

- Must pass `shellcheck` with no warnings (`shellcheck nsite nsite-completion.bash`).
- `set -euo pipefail` stays; quote everything — paths with spaces must work.
- Never modify configs nsite didn't create; never store state outside the
  nginx configs; every sudo call is per-command, never a blanket escalation.

Quick smoke test (read-only, safe to run anywhere):

```sh
bash -n nsite && ./nsite help >/dev/null && ./nsite list && ./nsite php list && ./nsite doctor
```
