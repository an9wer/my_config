#!/usr/bin/env bash

_read_cmdlines() {
  # $1: file to read cmdlines
  cmdlines=()
  cmdlines_old=()
  local pass=""
  while IFS='' read -r line || [[ -n "${line}" ]]; do
    cmdlines_old+=("$line")
    [[ "${line}" =~ "werice start" ]] && { pass="y"; continue; }
    [[ "${line}" =~ "werice end" ]] && { pass=""; continue; }
    [[ -n "$pass" ]] && continue
    cmdlines+=("$line")
  done < "${1}"
}

_write_cmdlines() {
  # $1: file to write cmdlines

  for line in "${cmdlines[@]}"; do
    echo "${line}"
  done > ${1}
}

unconfig() {
  for file in ${@}; do
    [[ -e "${file}" ]] || continue
    [[ -h "${file}" ]] || continue
    rm -vf "${file}"

    local dotbak=
    local suffix=0
    for dotbak in $(ls ${file}.bak.[0-9] ${file}.bak.[1-9][0-9]* 2>/dev/null); do
      (( suffix < ${dotbak##*.} )) && suffix=${dotbak##*.}
    done
    [[ -n $dotbak ]] && mv -vf "${file}.bak.${suffix}" "${file}"
  done
}

unconfig_bashrc() {
  unconfig ~/.me
  _read_cmdlines ~/.bashrc
  [[ "${cmdlines[*]}" != "${cmdlines_old[*]}" ]] &&
    _write_cmdlines ~/.bashrc
}

unconfig_bash_profile() {
  _read_cmdlines ~/.bash_profile
  [[ "${cmdlines[*]}" != "${cmdlines_old[*]}" ]] &&
    _write_cmdlines ~/.bash_profile
}

unconfig_pam_environment() {
  _read_cmdlines ~/.pam_environment
  [[ "${cmdlines[*]}" != "${cmdlines_old[*]}" ]] &&
    _write_cmdlines ~/.pam_environment
}

UNCONFIG_FUNC=(
  [1]="unconfig_bashrc"
  [2]="unconfig_bash_profile"
  [3]="unconfig ~/.vimrc ~/.vim"
  [4]="unconfig ~/.tmux.conf"
  [5]="unconfig ~/.gitconfig ~/.git-extensions"
  [6]="unconfig ~/.Xmodmap"
  [7]="unconfig ~/.gnupg/gpg.conf ~/.gnupg/dirmngr.conf ~/.gnupg/sks-keyserver.netCA.pem"
  [8]="unconfig ~/.w3m/keymap"
  [9]="unconfig_pam_environment"
)

declare -A CONFIG_CB=(
  [1]=""
  [2]=""
  [3]=""
  [4]=""
  [5]=""
  [6]=""
  [7]=""
  [8]=""
  [9]=""
)

# main
cat <<EOF
                       === rice uninstallation ===
This script is intend to uninstall configuration files for the following programs.
  0. all
  1. bashrc
  2. bash_profile
  3. vim
  4. tmux
  5. git
  6. xmodmap
  7. gpg
  8. w3m
  9. pam_environment
EOF
read -p "Which configuration file do you want to uninstall? (0/1/.../${#UNCONFIG_FUNC[@]}): " choice
echo ""

case ${choice} in
  0)
    for (( i = 1; i <= ${#UNCONFIG_FUNC[@]}; i++ )); do
      eval "${UNCONFIG_FUNC[${i}]}"
      eval "${UNCONFIG_CB[${i}]}"
    done ;;
  *)
    if [[ -n ${UNCONFIG_FUNC[${choice}]} ]]; then
      eval "${UNCONFIG_FUNC[${choice}]}"
      eval "${UNCONFIG_CB[${choice}]}"
    else
      echo "Unknown choice of configuration files :("
      exit 1
    fi ;;
esac
