# create links to 'module' directory scripts in 'bashrc.d' directory
addm() {
  for module in $@; do
    if [[ -e ${ME_MODULE_DIR}/${module}.sh ]]; then
      ln -sf ${ME_MODULE_DIR}/${module}.sh ${ME_BASHRC_DIR}/${module}.sh
      source ${ME_BASHRC_DIR}/${module}.sh
    else
      echo "${module} doesn't exist in module directory."
    fi
  done
}

# remove module links in 'bashrc.d' directory
delm() {
  for module in $@; do
    if [[ -L ${ME_BASHRC_DIR}/${module}.sh ]]; then
      rm -i ${ME_BASHRC_DIR}/${module}.sh
    else
      echo "${module} doesn't exist or can't be removed (not a symbolic file)."
    fi
  done
}
