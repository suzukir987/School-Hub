# School Hub

School Hub supports 41 games, including Run a Christmas Tree Lot, Harpoon a Fish, Net a Fish, Voxel Wars, Ant Evolution and +1 Sukuna Evolution, with one shared Auth, Loading and Hub design. Appearance and language preferences carry across games; gameplay settings stay specific to each game.

Power Lifters 0.4.0 adds Sled Push automation, timed stamina recovery, sprinting and maximum liftable weight selection. It also updates the Bars/Sled icons, keeps the hub visible during the event and removes expired Halloween quest claims. The latest in-game retest is pending.

Net a Fish 0.1.0 adds net fishing controls, showcase cash collection with Teleport or Walk, next-net purchases, cash-upgrade and rebirth controls, earned rewards, index claims, best fish setup and owned pet equipment. Cash, income, catches, net tier and rebirths update with Auto Fish off and while paused. New Net feature descriptions currently use English fallback.

Harpoon a Fish 0.1.4 adds harpoon aiming and normal fish reeling, automatic Fat training, aquarium feeding, best fish equipment, growth, cash upgrades, earned rewards and loaded-fish ESP. Live stats update with farming off and while paused. The accepted build was tested by the user in Delta on LDPlayer. This release fills localization gaps in the recent seven games, including Harpoon, Net a Fish and Power Lifters Sled controls.

Power Lifters 0.4.1 addresses Energy Drink auto consumption, Sled sprint detection and recovery-circle timing. Local source/protected and startup checks pass; a fresh in-game retest is pending.

Run a Christmas Tree Lot 0.1.0 adds a full lot workflow with teleport movement, stock ordering and placement, checkout, cash upgrades, employees and earned rewards. Full in-game verification is pending.

Power Lifters 0.4.2 reduces delayed Sled control activation with early preparation, faster source-validated discovery and a fresh scan on race entry. Native timing and movement guards are retained; a new in-game retest is pending.

School Hub 4.49.0 adds Throw a Seed 0.1.1 with training, x2 pop-ups, throws, plant placement, upgrades and Auto Sell. Harpoon a Fish 0.1.7 improves Wave camera/barrel alignment, loaded-spear synchronization and teleport movement. Christmas Tree Lot 0.1.1 recovers stalled data reads while customer service continues. The new Harpoon and Tree Lot fixes still await an in-game retest.

Run the hub using the existing command:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/suzukir987/School-Hub/main/loader.lua"))()
```

The launcher checks your key through [scriptrblx.com](https://scriptrblx.com/key/school-hub) and downloads the current game's module from private storage. A valid saved key opens Loading directly. New releases keep the same launch command.

### Credits

Based on Prometheus by Elias Oelschner, https://github.com/prometheus-lua/Prometheus

Prometheus Vmify protects the protocol client. UI and gameplay callbacks use native Lua code with separate obfuscation. See [School Hub credits](https://scriptrblx.com/about).
