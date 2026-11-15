# School Hub

School Hub supports 40 games, including Harpoon a Fish, Net a Fish, Voxel Wars, Ant Evolution and +1 Sukuna Evolution, with one shared Auth, Loading and Hub design. Appearance and language preferences carry across games; gameplay settings stay specific to each game.

Power Lifters 0.4.0 adds Sled Push automation, timed stamina recovery, sprinting and maximum liftable weight selection. It also updates the Bars/Sled icons, keeps the hub visible during the event and removes expired Halloween quest claims. The latest in-game retest is pending.

Net a Fish 0.1.0 adds net fishing controls, showcase cash collection with Teleport or Walk, next-net purchases, cash-upgrade and rebirth controls, earned rewards, index claims, best fish setup and owned pet equipment. Cash, income, catches, net tier and rebirths update with Auto Fish off and while paused. New Net feature descriptions currently use English fallback.

Harpoon a Fish 0.1.4 adds harpoon aiming and normal fish reeling, automatic Fat training, aquarium feeding, best fish equipment, growth, cash upgrades, earned rewards and loaded-fish ESP. Live stats update with farming off and while paused. The accepted build was tested by the user in Delta on LDPlayer. This release fills localization gaps in the recent seven games, including Harpoon, Net a Fish and Power Lifters Sled controls.

Run the hub using the existing command:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/suzukir987/School-Hub/main/loader.lua"))()
```

The launcher checks your key through [scriptrblx.com](https://scriptrblx.com/key/school-hub) and downloads the current game's module from private storage. A valid saved key opens Loading directly. New releases keep the same launch command.

### Credits

Based on Prometheus by Elias Oelschner, https://github.com/prometheus-lua/Prometheus

Prometheus Vmify protects the protocol client. UI and gameplay callbacks use native Lua code with separate obfuscation. See [School Hub credits](https://scriptrblx.com/about).
