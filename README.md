# redream-launcher

Bash script to install the update to the latest version of redream.

A shortcut will be created for *nix users; on macOS a local .app launcher will
be created so that redream can be started via spotlight. A .desktop file should
be created for Linux users as long as `~/.local/share/applications` exists.

> **Steam Deck Note** `MESA_LOADER_DRIVER_OVERRIDE=zink` is added to the
> application shortcut to workaround AMD driver glitches. Steam Deck users
> should set `Vertical sync` to `off` and `Polygon sort accuracy` to `per-strip`
> from within redream to prevent other glitches. `redream.desktop` can then
> manually be added within Steam to support launching in Gaming Mode.
> 

## Usage

Install the latest build of redream to `~/Applications/redream`:

```sh
curl -sSL https://raw.githubusercontent.com/andrewmackrodt/redream-launcher/main/redream | bash
```

Supported arguments:

| Argument         | Description                                                  |
|------------------|--------------------------------------------------------------|
| `-u`, `--update` | Update to latest version of redream                          |
| `-N`, `--no-run` | Do not run redream at the end of script exection             |
| `--system-mesa`  | Raspberry Pi users only, don't use the redream provided mesa |
