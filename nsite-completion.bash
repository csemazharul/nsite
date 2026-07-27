# shellcheck shell=bash
# bash completion for nsite — add to ~/.bashrc:
#   source /path/to/nsite-completion.bash

_nsite_sites() {
    find /etc/nginx/sites-enabled -maxdepth 1 \( -type l -o -type f \) -printf '%f\n' 2>/dev/null
}

_nsite_php_versions() {
    local dir
    for dir in /etc/php/*/fpm; do
        if [[ -d "$dir" ]]; then
            basename "$(dirname "$dir")"
        fi
    done
}

_nsite() {
    local cur cmd
    cur="${COMP_WORDS[COMP_CWORD]}"
    cmd="${COMP_WORDS[1]:-}"

    if [[ $COMP_CWORD -eq 1 ]]; then
        mapfile -t COMPREPLY < <(compgen -W "add rm list php logs doctor secure unsecure domain help" -- "$cur")
        return
    fi
    case "$cmd" in
        rm|logs|secure|unsecure|domain)
            mapfile -t COMPREPLY < <(compgen -W "$(_nsite_sites)" -- "$cur")
            ;;
        add)
            mapfile -t COMPREPLY < <(compgen -W "--php --root --proxy --tld --force --dry-run" -- "$cur")
            ;;
        php)
            if [[ $COMP_CWORD -eq 2 ]]; then
                mapfile -t COMPREPLY < <(compgen -W "list use cli current" -- "$cur")
            elif [[ "${COMP_WORDS[2]}" == use && $COMP_CWORD -eq 3 ]]; then
                mapfile -t COMPREPLY < <(compgen -W "$(_nsite_sites)" -- "$cur")
            elif [[ "${COMP_WORDS[2]}" == current && $COMP_CWORD -eq 3 ]]; then
                mapfile -t COMPREPLY < <(compgen -W "$(_nsite_sites)" -- "$cur")
            else
                mapfile -t COMPREPLY < <(compgen -W "$(_nsite_php_versions)" -- "$cur")
            fi
            ;;
    esac
}

complete -F _nsite nsite
