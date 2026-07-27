# nsite command reference

Every state-changing command validates with `sudo nginx -t` before
reloading and **rolls back its own changes** if the test fails.
Commands that delete or overwrite always prompt first (default: No).

---

## `nsite add <name> [options]`

Create a site for the project at `$WWW/<name>` (default `~/www/<name>`),
served at `http://<name>.<TLD>`.

| Option | Meaning |
|---|---|
| `--php <version>` | pin the site to that PHP-FPM socket (e.g. `--php 8.3`) |
| `--root <subdir>` | document root subdirectory (default: `public/` if present, else project root) |
| `--proxy <port>` | proxy mode: no PHP, reverse-proxy to `127.0.0.1:<port>` |
| `--tld <tld>` | use `<name>.<tld>` instead of the configured TLD |
| `--force` | overwrite an existing config without prompting |
| `--dry-run` | print the config and every action; change nothing |

Behavior details:

- Errors if the project directory doesn't exist (except in proxy mode).
- Without `--php`, uses the newest *running* PHP-FPM (or `PHP_SOCK` from config).
- Only appends to `/etc/hosts` if the hostname isn't already resolvable there.
- If the config exists, prompts before overwriting — with an extra warning
  when the existing file is a hand-written (non-nsite) config.
- On `nginx -t` failure: restores the previous config (or removes the new
  one), removes the symlink and hosts entry it added, then reports the error.

```sh
nsite add blog
nsite add shop --php 8.3
nsite add dash --proxy 3000
nsite add blog --tld dev --dry-run
```

---

## `nsite rm <name>`

Remove the site's nginx config, `sites-enabled` symlink, and `/etc/hosts`
line, then test + reload. Prompts for confirmation; warns loudly if the
config is hand-written. **Never deletes anything inside `$WWW`.**

A hosts line shared with other hostnames is left alone (with a warning)
rather than guessed at.

---

## `nsite list`

Read-only table of **all** enabled sites — including hand-written ones:

```
NAME           HOST                     PHP        LINK    BY      ROOT
blog           blog.test                8.4        ok      nsite   /home/you/www/blog
wordpress      wordpress.local          8.3        ok      manual  /home/you/www/wordpress
```

- `PHP` shows the version parsed from `fastcgi_pass`, `proxy:<port>` for
  proxy sites, or `-` when neither is present.
- `LINK` flags broken `sites-enabled` symlinks as `BROKEN`.
- `BY` distinguishes nsite-managed configs from hand-written (`manual`) ones.

All information is parsed live from the configs — nsite stores no state.

---

## `nsite php` — PHP version management

### `nsite php list`

Installed versions (from `/etc/php/*/fpm/`), whether each FPM service is
running, its socket path, and which version is the terminal default.

### `nsite php use <site> <version>`

Point one site at another PHP-FPM socket. Affects **only what the browser
gets** for that site; the terminal `php` is untouched.

- Not installed → error with the exact install commands (ondrej/php PPA).
- Installed but stopped → offers to `systemctl enable --now` it.
- Proxy site → refuses with an explanation.
- `nginx -t` failure → restores the previous config.

### `nsite php cli <version>`

Switch the terminal default (`php -v`, composer) via
`update-alternatives --set php`. Explicitly does **not** change what any
website serves — the command says so every time.

### `nsite php current [site]`

With a site: that site's version. Without: the CLI default plus a one-line
summary of every enabled site's version.

---

## `nsite domain <new-domain>` / `nsite domain <site> <new-domain>`

Rename a site's hostname. The one-argument form infers the site from the
domain's first label (`nsite domain blog.dev` → site `blog`); use the
two-argument form when the config name and hostname differ.

- Rewrites `server_name`, swaps the `/etc/hosts` entry.
- If the site was secured, re-issues the mkcert certificate for the new name.
- Hand-written configs require an extra confirmation.
- Full rollback (config + hosts entries) on `nginx -t` failure.

---

## `nsite secure <site>`

Add locally-trusted HTTPS via [mkcert](https://github.com/FiloSottile/mkcert).

- Generates a certificate for the site's hostname into
  `/etc/nginx/nsite-certs/` and appends `listen 443 ssl` + certificate
  directives to the config.
- Idempotent — already-secured sites are left alone.
- Refuses hand-written configs (their structure can't be safely edited).
- Plain `http://` keeps working alongside `https://`.

Required for `.dev`/`.app` TLDs, which browsers force to HTTPS.

---

## `nsite logs <site> [-f]`

Show the last lines of the site's per-site nginx logs
(`/var/log/nginx/<site>.access.log` + `.error.log`); `-f` follows live.
Hand-written configs without per-site logs get a clear error instead.

---

## `nsite doctor`

Read-only health check. Verifies: nginx running, every installed PHP-FPM
service running, and per site — symlink intact, document root exists,
hostname present in `/etc/hosts`, referenced PHP socket exists. Exits
non-zero if anything failed, so it's scriptable.

---

## `nsite help` / `nsite --version`

Usage text with examples / the version string.

---

## Configuration file

`${XDG_CONFIG_HOME:-~/.config}/nsite/config`, sourced as bash. Defaults:

```sh
WWW="$HOME/www"   # where projects live
TLD="test"        # default TLD for new sites
PHP_SOCK=""       # empty = auto-detect newest running PHP-FPM
```
