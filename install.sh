#!/usr/bin/env bash

set -e

MAIN_SCRIPT="$(dirname "$(readlink -f "$0")")/mccli.sh"

INSTALL_PATH=${INSTALL_PATH:-"/opt"}

LINK_PATH=${LINK_PATH:-"/usr/local/bin"}

DO_SYMLINK="false"

read -r -p "mccli: enter install path (blank for default: $INSTALL_PATH) " custom_path

if [ ! -z "$custom_path" ]; then
  INSTALL_PATH="$custom_path"
fi

while getopts ':lL:' option; do
	case "$option" in
		l)
			DO_SYMLINK="true"
			;;
		L)
			DO_SYMLINK="true"
			LINK_PATH="$OPTARG"
			;;
		*)
			;;
	esac
done

if [ "$DO_SYMLINK" = "true" ]; then
	INSTALL_PATH="$(dirname "$(readlink -f "$0")")";
fi

if [ -v "$1" ]; then
	INSTALL_PATH="$1"
fi

if [ ! -e "$INSTALL_PATH" ]; then
	mkdir -p "$INSTALL_PATH"
fi

if [ -e "$INSTALL_PATH/mccli" ]; then
	echo "mccli: $INSTALL_PATH/mccli already exists, exiting"
	exit 1;
fi

if [ ! -v MCCLI_PYTHON ]; then
	if which python3 > /dev/null; then
		MCCLI_PYTHON="$(which python3)";
	elif which python > /dev/null; then
		MCCLI_PYTHON="$(which python)";
	else
		echo "mccli: python not found as 'python' or 'python3'"
		read -r -p "Enter path to Python interpreter: " MCCLI_PYTHON
	fi
fi

echo "mccli: using python at $MCCLI_PYTHON"

skip_venv_creation="no"
valid_venv_path="no"
venv_path="$INSTALL_PATH/venv"

while [ "$skip_venv_creation" != "yes" ] && [ "$valid_venv_path" != "yes" ]; do

  if [ -d "$venv_path" ] && [ -e "$venv_path/bin/activate" ]; then
      read -r -p "mccli: venv directory exists at $venv_path, use as venv? [Y/n] " answer
      if [ "$answer" == "Y" ]; then
        skip_venv_creation="yes"
        break;
      fi
  elif [ -d "$venv_path" ]; then
    read -r -p "mccli: directory exists at $venv_path, delete to create venv? [Y/n] " answer
    if [ "$answer" == "Y" ]; then
        rm -rf "$venv_path";
        valid_venv_path="yes"
        break;
    fi
  else
    valid_venv_path="yes"
    break;
  fi
  read -r -p "Enter path to create or use venv: " venv_path
done

if [ "$valid_venv_path" == "yes" ] && [ "$skip_venv_creation" != "yes" ]; then
  if ! python -m venv "$venv_path"; then
    echo "mccli: error: cannot create venv, exiting" >&2
  fi
  source "$venv_path/bin/activate"
  pip3 -qq install mctools requests
  deactivate
fi

sed "s!##VENV##!$venv_path!" "$(dirname "$(readlink -f "$0")")/mccli.sh.template" > "$(dirname "$(readlink -f "$0")")/mccli.sh"
chmod 755 "$(dirname "$(readlink -f "$0")")/mccli.sh"

read -r -p "mccli: enter symlink path (blank for default: $LINK_PATH) " symlink_path
if [ -n "$symlink_path" ]; then
  LINK_PATH="$symlink_path"
fi

if [ "$DO_SYMLINK" = "true" ]; then
	set +e
	echo "a"
	ln -s "$MAIN_SCRIPT" "$LINK_PATH/mccli";
	install_success="$?"
	set -e
else
	if [ -d "$INSTALL_PATH/mccli" ]; then
		echo "mccli: $INSTALL_PATH/mccli_install directory already exists, exiting"
		exit 1;
	fi
	mkdir "$INSTALL_PATH/mccli";
	set +e
	cp -r "$(dirname "$(readlink -f "$0")")/"* "$INSTALL_PATH/mccli";
	install_success="$?"
	touch "$INSTALL_PATH/mccli/.copy_install";
	if [ ! "$LINK_PATH" = "none" ]; then
	  echo "b"
		ln -s "$INSTALL_PATH/mccli/mccli.sh" "$LINK_PATH/mccli";
	fi
	set -e
fi

if [ "$install_success" -eq 0 ]; then
	echo "mccli: installed to $INSTALL_PATH/mccli"
else
	echo "mccli: install failed (attempted to install to $INSTALL_PATH/mccli)"
fi