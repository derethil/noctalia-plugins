# noctalia-plugins

Personal plugin source for [Noctalia](https://noctalia.dev).

## Plugins

| Plugin                       | Description                                                  |
| ---------------------------- | ------------------------------------------------------------ |
| [cast-window](./cast-window) | Pick a window to screencast using niri's Dynamic Cast Target |

## Usage

Add this repo as a plugin source, then enable the plugin you want:

```sh
noctalia msg plugins source add derethil path ~/development/personal/noctalia-plugins
noctalia msg plugins enable derethil/<plugin-id>
```

Each plugin's own README has widget and config details.

## License

MIT unless a plugin's manifest says otherwise.
