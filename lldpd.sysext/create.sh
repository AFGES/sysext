#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# lldpd system extension.
#

RELOAD_SERVICES_ON_MERGE="true"

# Also match packaging-revision releases such as lldpd-1.0.22-2.
EXTENSION_VERSION_MATCH_PATTERN='[.0-9]+(-[0-9]+)?'

function list_available_versions() {
  list_github_tags "lldpd" "lldpd" | grep -E '^[0-9]+(\.[0-9]+)+$'
}
# --

function populate_sysext_root() {
  local sysextroot="$1"
  local arch="$2"
  local version="$3"

  # "<upstream>-<n>" is a rebuild of an upstream release (packaging revision).
  local upstream_version="${version%%-*}"

  local img_arch="$(arch_transform 'x86-64' 'amd64' "$arch")"
  img_arch="$(arch_transform 'arm64' 'arm64/v8' "$img_arch")"

  local image="docker.io/alpine:3.21"

  announce "Building lldpd $version for $arch"

  local user_group="$(id -u):$(id -g)"

  cp "${scriptroot}/lldpd.sysext/build.sh" .
  docker run --rm \
              -i \
              -v "$(pwd)":/install_root \
              --platform "linux/${img_arch}" \
              --pull always \
              ${image} \
                  /install_root/build.sh "${upstream_version}" "$user_group"

  # /usr/sbin is a symlink to /usr/bin on Flatcar.
  mkdir -p usr/bin
  mv usr/sbin/* usr/bin/
  rmdir usr/sbin
  cp -aR usr "${sysextroot}"/
}
# --
