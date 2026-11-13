# School Hub

School Hub supports 36 games, including +1 Sukuna Evolution, with one shared Auth, Loading and Hub design. Appearance and language preferences carry across games; gameplay settings stay specific to each game.

Run the hub using the existing command:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/suzukir987/School-Hub/main/loader.lua"))()
```

The launcher checks your key through [scriptrblx.com](https://scriptrblx.com/key/school-hub) and downloads the current game's module from private storage. A valid saved key opens Loading directly. New releases keep the same launch command.

### Credits

Based on Prometheus by Elias Oelschner, https://github.com/prometheus-lua/Prometheus

Prometheus Vmify protects the protocol client. UI and gameplay callbacks use native Lua code with separate obfuscation. See [School Hub credits](https://scriptrblx.com/about).
