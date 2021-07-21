#!/usr/bin/env bash

require_var() {
  if [ -z "$1" ]; then
    >&2 echo "$2"
    return 1
  fi
  return 0
}

require_env() {
  require_var "$2" "Missing env var '$1'"
}

setup_pip() {
  if [ "$ARTIFACTORY_SETUP_PIP" == "false" ]; then
    echo "Skipping pip setup because ARTIFACTORY_SETUP_PIP=$ARTIFACTORY_SETUP_PIP"
    return 0
  fi

  pipCmd=""
  if command -v pip3 &> /dev/null; then
    pipCmd="pip3"
  elif command -v pip &> /dev/null; then
    pipCmd="pip"
  fi

  require_var "$pipCmd" "Cannot find pip executable, tried pip3 and pip" || return 1

  require_env "ARTIFACTORY_USERNAME" "$ARTIFACTORY_USERNAME" || return 1
  require_env "ARTIFACTORY_TOKEN" "$ARTIFACTORY_TOKEN" || return 1
  require_env "ARTIFACTORY_PYPI_INDEX" "$ARTIFACTORY_PYPI_INDEX" || return 1

  domain=$(echo "$ARTIFACTORY_PYPI_INDEX" | awk -F '[/:]' '{print $4}')
  require_var "$domain" "Failed to extract domain from ARTIFACTORY_PYPI_INDEX env var" || return 1

  cat > "$HOME/.netrc" << EOF
machine $domain
login $ARTIFACTORY_USERNAME
password $ARTIFACTORY_TOKEN

EOF

  "$pipCmd" config set global.index-url "$ARTIFACTORY_PYPI_INDEX"
  "$pipCmd" config set global.extra-index-url https://pypi.org/simple

  return 0
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  if setup_pip "$@"; then
    exit 0
  fi
  exit 1
fi