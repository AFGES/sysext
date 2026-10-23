#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# doco-cd system extension.
#
# Upstream does not publish release binaries, only a container image.
# The static binary is extracted from ghcr.io/kimdre/doco-cd.
#

RELOAD_SERVICES_ON_MERGE="true"

function list_available_versions() {
  list_github_releases "kimdre" "doco-cd"
}
# --

function populate_sysext_root() {
  local sysextroot="$1"
  local arch="$2"
  local version="$3"

  local img_arch
  img_arch="$(arch_transform 'x86-64' 'amd64' "$arch")"

  # Image tags have no leading "v".
  local image="ghcr.io/kimdre/doco-cd:${version#v}"

  local container
  container="$(docker create --platform "linux/${img_arch}" "${image}")"
  mkdir -p "${sysextroot}/usr/bin"
  docker cp "${container}:/doco-cd" "${sysextroot}/usr/bin/doco-cd" \
    || { docker rm "${container}" >/dev/null; return 1; }
  docker rm "${container}" >/dev/null
  chmod 0755 "${sysextroot}/usr/bin/doco-cd"
}
# --
