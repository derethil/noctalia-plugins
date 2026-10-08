# noctalia-plugins

Personal plugin source for [Noctalia](https://noctalia.dev).

## Plugins

| Plugin                       | Description                                                  |
| ---------------------------- | ------------------------------------------------------------ |
| [cast-window](./cast-window) | Pick a window to screencast using niri's Dynamic Cast Target |
| [hue-manager](./hue-manager) | Control your Philips Hue lights, rooms, and scenes |

## Usage

Add this repo as a plugin source, then enable the plugin you want:

```sh
noctalia msg plugins source add derethil git https://github.com/derethil/noctalia-plugins.git
noctalia msg plugins enable derethil/<plugin-id>
```

Each plugin's own README has widget and config details.

## License

MIT unless a plugin's manifest says otherwise.
