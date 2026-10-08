# Hue Manager

Control your Philips Hue lights, rooms, and scenes from a Noctalia bar widget.

This is the Noctalia rewrite of
[dms-hue-manager](https://github.com/derethil/dms-hue-manager). It communicates
directly with the bridge over the Hue CLIP v2 API.

## Features

- Control whole rooms or individual lights: power, brightness, colour, colour
  temperature
- Scene recall per room, with the active scene shown
- Live updates from the bridge's event stream — changes made in the Hue app
  appear instantly
- Hue room and light icons matched to the bridge archetype
- Accent sync: follow the Noctalia accent colour on theme change, for all rooms
  or a chosen subset
- Guided pairing, including a one-time import of existing `openhue` credentials
- Master power control for rooms and unassigned lights; controls lock while
  bridge updates are pending

## Requirements

A Philips Hue bridge on your network is required.

For local bridge discovery, the plugin uses `avahi-browse` when it is available
on `PATH`; otherwise it falls back to Hue's public discovery service. You do not
need to install Avahi when that fallback works, but `avahi-browse` is the more
reliable option on networks where public discovery is unavailable.

## Install

```sh
noctalia msg plugins source add derethil git https://github.com/derethil/noctalia-plugins.git
noctalia msg plugins enable derethil/hue-manager
```

Then add the widget to a bar:

```toml
[widget.hue]
type = "derethil/hue-manager:hue"
```

## Pairing

If you use `openhue`, the plugin imports the bridge address and application key
from `~/.config/openhue/config.yaml` on first run.

Otherwise open the panel and click **Pair with a bridge**, then press the link
button on the bridge within two minutes. Credentials are saved in the plugin's
data directory. The application key is not logged, shown in notifications, or
exposed through shared plugin state.

## Settings

Edited in **Settings → Plugins → Hue Manager**:

| Setting                 | Default | Description                                                     |
| ----------------------- | ------- | --------------------------------------------------------------- |
| Use device icons        | on      | Icon per Hue archetype instead of a generic door or bulb        |
| Auto-sync accent colour | off     | Apply the shell accent to the synced rooms on theme change      |
| Rooms to sync           | empty   | Room names that follow the accent colour; empty means all rooms |
| Bridge IP override      | empty   | Skip discovery and use a fixed address                          |

**Rooms to sync** matches trimmed room names without regard to case. Since the
setting cannot be populated from bridge data, renaming a room removes it from
the selection. The plugin logs names that match no room.

The sync button in the panel header applies the current accent immediately,
whether or not auto-sync is on.

### Enabling accent sync

Auto-sync uses Noctalia's `colors_changed` hook; the plugin does not install the
hook or poll for palette changes. Add this to `~/.config/noctalia/config.toml`:

```toml
[hooks]
colors_changed = "noctalia msg plugin derethil/hue-manager:bridge all sync-accent"
```

Then enable **Auto-sync accent colour**. The panel's sync button applies the
current accent on demand, with or without the hook.

The same IPC surface is useful for scripting:

```sh
noctalia msg plugin derethil/hue-manager:bridge all sync-accent
noctalia msg plugin derethil/hue-manager:bridge all refresh
```

## Layout

```
hue-manager/
  lib/       pure resource, colour, icon, policy, and view-model logic
  service/   bridge transport/SSE, pairing, commands, queue, state, and types
  ui/        panel header, status, room/light views, entity rows, and actions
  tests/     standalone Luau checks for the pure library modules
  *.luau     the service, panel, and widget entrypoints
```

## Development

```sh
nix-shell -p luau --run 'cd hue-manager && for f in tests/*_test.luau; do luau "$f" || exit 1; done'
```

`lib/` modules do not `require` one another because Noctalia and the Luau CLI
resolve module paths differently. The `ui/` modules are not loaded by the CLI,
so they can require each other and `lib/` modules. `service.luau` wires together
the transport, pairing, command, and state modules.

## Icon attribution

The bundled Hue icons are derived from
[hass-hue-icons](https://github.com/arallsopp/hass-hue-icons) by Andrew Allsopp
and are licensed under [CC BY-NC-SA 4.0](assets/hue-icons/LICENSE).
