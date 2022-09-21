#!/usr/bin/env bash

# shellcheck disable=SC2120

function pyenv_gitpod_init() {
	if test -e "$GITPOD_REPO_ROOT"; then {
		export PYENV_HOOK_PATH="$HOME/.gp_pyenv.d"
		export GP_PYENV_MIRROR="/workspace/.pyenv_mirror"
		export GP_PYENV_FAKEROOT="$GP_PYENV_MIRROR/fakeroot"
		export PYTHONUSERBASE="$GP_PYENV_MIRROR/user/current"
		export PYTHONUSERBASE_VERSION_FILE="${PYTHONUSERBASE%/*}/.mounted_version"
		export PIP_CACHE_DIR="$GP_PYENV_MIRROR/pip_cache"

		if test ! -v GP_PYENV_INIT; then {

			# Restore installed python versions
			local target version_dir
			(
				shopt -s nullglob
				for version_dir in "$GP_PYENV_FAKEROOT/versions/"*; do {
					target="$PYENV_ROOT/versions/${version_dir##*/}"
					mkdir -p "$target" 2>/dev/null
					if ! mountpoint -q "$target" && ! sudo mount --bind "$version_dir" "$target" 2>/dev/null; then {
						rm -rf "$target"
						ln -s "$version_dir" "$target"
					}; fi
				}; done
			)

			# Persistent `pyenv global` version
			local p_version_file="$GP_PYENV_FAKEROOT/version"
			local o_version_file="$PYENV_ROOT/version"
			if test ! -e "$p_version_file"; then {
				mkdir -p "${p_version_file%/*}"
				if test -e "$o_version_file"; then {
					printf '%s\n' "$(<"$o_version_file")" >"$p_version_file" || :
				}; fi
			}; fi
			touch "$p_version_file"
			rm -f "$o_version_file"
			ln -sf "$p_version_file" "$o_version_file"

			# Init userbase hook
			pyenv global 1>/dev/null

		}; fi && export GP_PYENV_INIT=true

		# Poetry customizations
		export POETRY_CACHE_DIR="$GP_PYENV_MIRROR/poetry"
	}; fi
}

pyenv_gitpod_init
unset -f pyenv_gitpod_init vscode::add_settings

# Do not init when sourced internally from `pyenv`
if test ! -v PYENV_DIR; then {
	eval "$(pyenv init -)"
	eval "$(pyenv virtualenv-init -)"
}; fi
