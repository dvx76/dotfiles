#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

declare -A FILES=(
    ["gitconfig"]="~/.gitconfig"
    ["tmux.conf"]="~/.tmux.conf"
    ["vimrc"]="~/.vimrc"
    )

for NAME in "${!FILES[@]}"; do
    SOURCE="${FILES[$NAME]}"
    DEST="${SCRIPT_DIR}/${NAME}"
    COMMAND="ln -s ${DEST} ${SOURCE}"
    echo "${COMMAND}"
    eval "${COMMAND}"
done