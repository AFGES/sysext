# newt sysext

This sysext ships [newt](https://github.com/fosrl/newt), the tunnel client of [Pangolin](https://pangolin.net/).
Newt creates a persistent connection from the host to a Pangolin server and exposes local resources through it.

The sysext installs the upstream release binary as `/usr/bin/newt`.
It ships `newt.service`, which starts at boot when `/etc/newt/newt.env` is not empty.

# Usage

Create a site in Pangolin and copy its endpoint, ID and secret into `/etc/newt/newt.env`.
Newt reads `PANGOLIN_ENDPOINT`, `NEWT_ID` and `NEWT_SECRET` from the environment.
An example env file is shipped in `/usr/share/newt/newt.env`.
See the [newt documentation](https://docs.pangolin.net/manage/sites/install-site) for more options.

The snippet includes automated updates via systemd-sysupdate.
After an update, the extensions are refreshed and newt is restarted; no reboot is required.
You can deactivate updates by changing `enabled: true` to `enabled: false` in `systemd-sysupdate.timer`.

Note that the snippet is for the x86-64 version of newt 1.19.0.
For arm64, replace `x86-64` with `arm64`.

Check out the metadata release at https://github.com/flatcar/sysext-bakery/releases/tag/newt for a list of all versions available in the bakery.

```yaml
variant: flatcar
version: 1.0.0

storage:
  files:
    - path: /opt/extensions/newt/newt-1.19.0-x86-64.raw
      mode: 0644
      contents:
        source: https://extensions.flatcar.org/extensions/newt-1.19.0-x86-64.raw
    - path: /etc/sysupdate.newt.d/newt.conf
      contents:
        source: https://extensions.flatcar.org/extensions/newt.conf
    - path: /etc/newt/newt.env
      mode: 0600
      contents:
        inline: |
          PANGOLIN_ENDPOINT=https://pangolin.example.com
          NEWT_ID=changeme
          NEWT_SECRET=changeme
  links:
    - target: /opt/extensions/newt/newt-1.19.0-x86-64.raw
      path: /etc/extensions/newt.raw
      hard: false
systemd:
  units:
    - name: systemd-sysupdate.timer
      enabled: true
    - name: systemd-sysupdate.service
      dropins:
        - name: newt.conf
          contents: |
            [Service]
            ExecStartPre=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/newt.raw > /tmp/newt"
            ExecStartPre=/usr/lib/systemd/systemd-sysupdate -C newt update
            ExecStartPost=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/newt.raw > /tmp/newt-new"
            ExecStartPost=/usr/bin/sh -c "if ! cmp --silent /tmp/newt /tmp/newt-new; then systemd-sysext refresh && systemctl restart newt.service; fi"
```

After changing `/etc/newt/newt.env`, restart the service:

```bash
sudo systemctl restart newt.service
sudo journalctl -u newt.service
```
