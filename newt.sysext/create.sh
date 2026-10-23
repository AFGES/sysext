#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# newt system extension.
#

RELOAD_SERVICES_ON_MERGE="true"

function list_available_versions() {
  list_github_releases "fosrl" "newt"
}
# --

function populate_sysext_root() {
  local sysextroot="$1"
  local arch="$2"
  local version="$3"

  arch="$(arch_transform 'x86-64' 'amd64' "${arch}")"

  mkdir -p "${sysextroot}/usr/bin"

  local binary_url="https://github.com/fosrl/newt/releases/download/${version}/newt_linux_${arch}"
  echo "Downloading ${binary_url}"
  curl --fail --silent --show-error --location \
    --output "${sysextroot}/usr/bin/newt" "${binary_url}"

  chmod 0755 "${sysextroot}/usr/bin/newt"
}
# --
