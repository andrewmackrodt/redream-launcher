# redream-launcher

Bash script to install the latest redream before each application start. The script
can be run on demand to update to the latest version and will preserve existing
configurations, saves etc.

A shortcut will be created (where possible); on macOS a local .app launcher will
be created so that redream can be started via spotlight. A .desktop file should
be created for Linux users as long as `~/.local/share/applications` exists.

## Usage
```sh
curl -sSL https://raw.githubusercontent.com/andrewmackrodt/redream-launcher/master/redream | bash
```
