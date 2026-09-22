# Cast Window

A bar widget for [niri](https://github.com/YaLTeR/niri) that sets the
[Dynamic Cast Target](https://niri-wm.github.io/niri/Screencasting.html#dynamic-screencast-target)
to a window you pick with the mouse.

Clicking it runs `niri msg pick-window` and feeds the picked window id to
`niri msg action set-dynamic-cast-window`.

The widget tracks whether any live screencast is following the dynamic target,
via the compositor's `CastsChanged` event. When nothing is using it, the widget
either dims to the `outline` palette role or hides itself, per the **inactive
mode** widget setting.

## Requirements

- `niri` on `PATH`

## Install

Add this repo as a plugin source and enable the plugin:

```sh
noctalia msg plugins source add derethil path ~/development/personal/noctalia-plugins
noctalia msg plugins enable derethil/cast-window
```

Then add the widget to a bar:

```toml
[widget.cast_window]
type = "derethil/cast-window:cast"
inactive_mode = "dim"   # or "hide"
```
