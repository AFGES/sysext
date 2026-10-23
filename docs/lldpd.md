# lldpd sysext

This sysext ships [lldpd](https://github.com/lldpd/lldpd), a daemon for the Link Layer Discovery Protocol (LLDP, plus CDP, EDP and SONMP), and its `lldpcli` client.
The binaries are statically compiled, without SNMP support.

The sysext includes a service unit file to start `lldpd` at boot.
The daemon drops privileges to the `_lldpd` user, which the sysext creates via sysusers.

# Usage

Download and merge the sysext at provisioning time using the below butane snippet.
The snippet also sets the system description lldpd advertises, as an example of a configuration file.

lldpd reads `lldpcli` commands from `/etc/lldpd.conf` and `/etc/lldpd.d/*.conf` at start.
Daemon options (for example `-c` to enable CDP) go into `LLDPD_OPTIONS` in `/etc/sysconfig/lldpd`.

The snippet includes automated updates via systemd-sysupdate.
After an update, the extensions are refreshed and lldpd is restarted; no reboot is required.
You can deactivate updates by changing `enabled: true` to `enabled: false` in `systemd-sysupdate.timer`.

Note that the snippet is for the x86-64 version of lldpd 1.0.22.
For arm64, replace `x86-64` with `arm64`.

Check out the metadata release at https://github.com/flatcar/sysext-bakery/releases/tag/lldpd for a list of all versions available in the bakery.

```yaml
variant: flatcar
version: 1.0.0

storage:
  files:
    - path: /opt/extensions/lldpd/lldpd-1.0.22-x86-64.raw
      mode: 0644
      contents:
        source: https://extensions.flatcar.org/extensions/lldpd-1.0.22-x86-64.raw
    - path: /etc/sysupdate.lldpd.d/lldpd.conf
      contents:
        source: https://extensions.flatcar.org/extensions/lldpd.conf
    - path: /etc/lldpd.d/system.conf
      contents:
        inline: |
          configure system description 'Flatcar Container Linux'
  links:
    - target: /opt/extensions/lldpd/lldpd-1.0.22-x86-64.raw
      path: /etc/extensions/lldpd.raw
      hard: false
systemd:
  units:
    - name: systemd-sysupdate.timer
      enabled: true
    - name: systemd-sysupdate.service
      dropins:
        - name: lldpd.conf
          contents: |
            [Service]
            ExecStartPre=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/lldpd.raw > /tmp/lldpd"
            ExecStartPre=/usr/lib/systemd/systemd-sysupdate -C lldpd update
            ExecStartPost=/usr/bin/sh -c "readlink --canonicalize /etc/extensions/lldpd.raw > /tmp/lldpd-new"
            ExecStartPost=/usr/bin/sh -c "if ! cmp --silent /tmp/lldpd /tmp/lldpd-new; then systemd-sysext refresh && systemctl restart lldpd.service; fi"
```

Check the neighbours the host sees:

```bash
sudo lldpcli show neighbors
```
