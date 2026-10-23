# doco-cd sysext

This sysext ships [doco-cd](https://github.com/kimdre/doco-cd), a GitOps tool that deploys Docker Compose projects from Git repositories.

Upstream publishes no release binaries, only a container image.
The sysext carries the static `doco-cd` binary taken from `ghcr.io/kimdre/doco-cd`, and runs it as a systemd service instead of a container.

The sysext ships `doco-cd.service`, which starts at boot when `/etc/doco-cd/doco-cd.env` is not empty.
The service runs as root and needs the Docker daemon (`docker.service`).
Its data directory is `/var/lib/doco-cd`.
Build jobs in your Compose files need the `docker-buildx` sysext.

# Usage

Put the doco-cd settings into `/etc/doco-cd/doco-cd.env`.
See [App Settings](https://doco.cd/latest/App-Settings/) for all variables.
The env file cannot hold multiline values, so pass the poll configuration with `POLL_CONFIG_FILE`.
An example env file is shipped in `/usr/share/doco-cd/doco-cd.env`.

The snippet includes automated updates via systemd-sysupdate.
After an update, the extensions are refreshed and doco-cd is restarted; no reboot is required.
You can deactivate updates by changing `enabled: true` to `enabled: false` in `systemd-sysupdate.timer`.

Note that the snippet is for the x86-64 version of doco-cd v0.129.1.
For arm64, replace `x86-64` with `arm64`.

Check out the metadata release at https://github.com/flatcar/sysext-bakery/releases/tag/doco-cd for a list of all versions available in the bakery.

```yaml
variant: flatcar
version: 1.0.0

storage:
  files:
    - path: /opt/extensions/doco-cd/doco-cd-v0.129.1-x86-64.raw
      mode: 0644
      contents:
        source: https://extensions.flatcar.org/extensions/doco-cd-v0.129.1-x86-64.raw
    - path: /etc/sysupdate.doco-cd.d/doco-cd.conf
      contents:
        source: https://extensions.flatcar.org/extensions/doco-cd.conf
    - path: /etc/doco-cd/poll-config.yaml
      mode: 0600
      contents:
        inline: |
          - url: https://github.com/example/infra.git
            reference: main
    - path: /etc/doco-cd/doco-cd.env
      mode: 0600
      contents:
        inline: |
          HTTP_PORT=8080
          POLL_CONFIG_FILE=/etc/doco-cd/poll-config.yaml
          GIT_ACCESS_TOKEN=changeme
  links:
    - path: /etc/systemd/system/multi-user.target.wants/doco-cd.service
      target: /usr/local/lib/systemd/system/doco-cd.service
      overwrite: true
    - target: /opt/extensions/doco-cd/doco-cd-v0.129.1-x86-64.raw
      path: /etc/extensions/doco-cd.raw
      hard: false
systemd:
  units:
    - name: systemd-sysupdate.timer
      enabled: true
    - name: systemd-sysupdate.service
      dropins:
        - name: doco-cd.conf
          contents: |
            [Service]
            ExecStartPre=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/doco-cd.raw > /tmp/doco-cd"
            ExecStartPre=/usr/lib/systemd/systemd-sysupdate -C doco-cd update
            ExecStartPost=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/doco-cd.raw > /tmp/doco-cd-new"
            ExecStartPost=/usr/bin/sh -c "if ! cmp --silent /tmp/doco-cd /tmp/doco-cd-new; then systemd-sysext refresh && systemctl restart doco-cd.service; fi"
```

After changing `/etc/doco-cd/doco-cd.env`, restart the service:

```bash
sudo systemctl restart doco-cd.service
sudo journalctl -u doco-cd.service
```
