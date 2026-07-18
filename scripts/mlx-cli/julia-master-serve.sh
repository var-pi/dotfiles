#!/usr/bin/env zsh
set -e

dir="${0:a:h}"
source "$dir/.venv/bin/activate"

$dir/julia-master-serve.py
