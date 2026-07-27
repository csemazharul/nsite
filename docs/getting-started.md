# Getting started with nsite

This walks through the everyday workflows. Every command that changes
anything runs `nginx -t` first and **rolls back automatically** if the new
config is invalid — nginx is never left broken.

## Your first site

```sh
mkdir -p ~/www/blog
echo '<?php phpinfo();' > ~/www/blog/index.php
nsite add blog
```

That one command:

1. writes a plain, readable vhost to `/etc/nginx/sites-available/blog`
2. symlinks it into `sites-enabled/`
3. adds `127.0.0.1  blog.test` to `/etc/hosts`
4. runs `sudo nginx -t` and reloads nginx

Open **http://blog.test** — done. The generated config is marked
`# managed by nsite`; edit it freely, nsite always asks before overwriting.

### Laravel-style projects

If `~/www/<name>/public` exists, it's used as the document root
automatically. Use `--root` for anything else:

```sh
nsite add shop                 # docroot = ~/www/shop/public (auto-detected)
nsite add legacy --root web    # docroot = ~/www/legacy/web
```

### Preview before touching anything

```sh
nsite add blog --dry-run
```

Prints the exact config and every action it would take. Changes nothing.

## Switching PHP versions — the key concept

There are **two independent PHP versions** and mixing them up is the most
common source of confusion:

| | What it affects | Command |
|---|---|---|
| **Site version** | what the *browser* gets for one site | `nsite php use blog 8.4` |
| **CLI version** | what `php -v` / composer run in your *terminal* | `nsite php cli 8.4` |

```sh
nsite php list             # installed versions, FPM status, CLI default
nsite php use blog 8.3     # blog.test now runs 8.3 — terminal unchanged
nsite php cli 8.4          # terminal now runs 8.4 — no website changed
nsite php current          # overview: CLI default + every site's version
nsite php current blog     # just blog's version
```

`blog.test` on 8.3 while your terminal runs 8.4 is perfectly normal.

If the requested version's FPM service isn't running, nsite offers to
start and enable it. If it isn't installed, nsite prints the exact
`apt` commands to install it.

## Node / Python apps (proxy mode)

For anything that runs its own dev server (Next.js, Vite, FastAPI, …):

```sh
nsite add dash --proxy 3000    # http://dash.test → 127.0.0.1:3000
```

The generated vhost includes websocket headers, so hot-reload works.
Proxy sites have no PHP — `nsite php use` refuses them with an explanation.

## HTTPS

```sh
nsite secure blog              # https://blog.test, locally trusted
```

Uses mkcert, stores certs in `/etc/nginx/nsite-certs/`, and appends the
`listen 443 ssl` lines to the site's config. Plain http keeps working.
Refuses hand-written configs (it won't guess at their structure).

## Changing a site's domain

```sh
nsite add blog --tld dev       # create as blog.dev instead of blog.test
nsite domain blog.dev          # or rename an existing site to blog.dev
```

**TLD warning:** `.test` is reserved and always safe. `.dev`/`.app` are
HSTS-preloaded — browsers force HTTPS, so run `nsite secure` on those.
Real TLDs like `.site` get shadowed locally. nsite warns you in each case.

## Debugging a site

```sh
nsite doctor          # services up? sockets present? hosts entries? symlinks?
nsite logs blog       # last 30 lines of blog's access + error logs
nsite logs blog -f    # follow live
nsite list            # every enabled site at a glance, incl. hand-written ones
```

## Removing a site

```sh
nsite rm blog
```

Removes the nginx config, the symlink, and the hosts entry — after a
confirmation prompt. **Your project in `~/www/blog` is never touched.**
