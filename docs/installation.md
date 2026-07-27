# Installing nsite

## Requirements

| What | Why | Check |
|---|---|---|
| Ubuntu / Debian / Pop!_OS | nsite assumes the Debian nginx layout | `ls /etc/nginx/sites-available` |
| bash 4+ | the script uses bash features | `bash --version` |
| nginx | the web server being managed | `nginx -v` |
| PHP-FPM (any version) | only for PHP sites | `ls /etc/php/` |
| [mkcert](https://github.com/FiloSottile/mkcert) | only for `nsite secure` (HTTPS) | `mkcert -help` |
| a sudo-capable user | nsite writes to `/etc/nginx` and `/etc/hosts` | — |

nsite itself must **not** be run as root — it refuses, and calls `sudo`
internally only for the specific commands that need it.

## Install

```sh
git clone https://github.com/csemazharul/nsite ~/www/nsite
chmod +x ~/www/nsite/nsite
sudo ln -s ~/www/nsite/nsite /usr/local/bin/nsite
```

The symlink puts `nsite` on your PATH. If you prefer not to touch
`/usr/local/bin`, add an alias instead:

```sh
echo 'alias nsite="$HOME/www/nsite/nsite"' >> ~/.bashrc
```

### Tab completion (optional)

```sh
echo 'source ~/www/nsite/nsite-completion.bash' >> ~/.bashrc
```

Then `nsite <Tab>` completes commands, site names, and PHP versions.

### Optional per-PHP-version packages

For multiple PHP versions side by side (the main reason nsite exists),
use the ondrej/php PPA:

```sh
sudo add-apt-repository ppa:ondrej/php
sudo apt install php8.3-fpm php8.4-fpm
```

## Verify the install

```sh
nsite help        # usage text
nsite doctor      # checks nginx, PHP-FPM services, existing sites
nsite list        # shows every enabled site, including hand-written ones
```

`doctor` and `list` are read-only — safe to run any time.

## Configuration (optional)

nsite works with zero config. To change defaults, create
`~/.config/nsite/config` (plain bash, sourced at startup):

```sh
WWW="$HOME/www"   # where your projects live
TLD="test"        # sites become <name>.test
PHP_SOCK=""       # empty = auto-detect the newest running PHP-FPM
```

## Updating

```sh
cd ~/www/nsite && git pull
```

Nothing else — the script is the whole tool.

## Uninstalling

nsite keeps no hidden state, so removal is just:

```sh
# 1. (optional) remove sites it created — this cleans nginx + hosts entries
nsite rm <site>            # repeat per site

# 2. delete the tool
sudo rm /usr/local/bin/nsite
rm -rf ~/www/nsite
```

Sites you don't `nsite rm` keep working — they're plain nginx configs and
survive nsite's removal untouched.
