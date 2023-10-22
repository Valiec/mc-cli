#!/usr/bin/env bash

export SCRIPT_ROOT="$(dirname "$(readlink -f "$0")")"

export MCCLI_PYTHON=/Users/valiec/miniforge3/bin/python

python "$SCRIPT_ROOT"/mccli.py "$@"

