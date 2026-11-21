# School Hub

School Hub supports 46 games, including CRAZY 8 Ball, Flat the Mountain, Blade Ball, Jump for Cases, Run a Christmas Tree Lot, Harpoon a Fish, Net a Fish, Voxel Wars, Ant Evolution and +1 Sukuna Evolution, with one shared Auth, Loading and Hub design. Appearance and language preferences carry across games; gameplay settings stay specific to each game.

Power Lifters 0.4.0 adds Sled Push automation, timed stamina recovery, sprinting and maximum liftable weight selection. It also updates the Bars/Sled icons, keeps the hub visible during the event and removes expired Halloween quest claims. The latest in-game retest is pending.

Net a Fish 0.1.0 adds net fishing controls, showcase cash collection with Teleport or Walk, next-net purchases, cash-upgrade and rebirth controls, earned rewards, index claims, best fish setup and owned pet equipment. Cash, income, catches, net tier and rebirths update with Auto Fish off and while paused. New Net feature descriptions currently use English fallback.

Harpoon a Fish 0.1.4 adds harpoon aiming and normal fish reeling, automatic Fat training, aquarium feeding, best fish equipment, growth, cash upgrades, earned rewards and loaded-fish ESP. Live stats update with farming off and while paused. The accepted build was tested by the user in Delta on LDPlayer. This release fills localization gaps in the recent seven games, including Harpoon, Net a Fish and Power Lifters Sled controls.

Power Lifters 0.4.1 addresses Energy Drink auto consumption, Sled sprint detection and recovery-circle timing. Local source/protected and startup checks pass; a fresh in-game retest is pending.

Run a Christmas Tree Lot 0.1.0 adds a full lot workflow with teleport movement, stock ordering and placement, checkout, cash upgrades, employees and earned rewards. Full in-game verification is pending.

Power Lifters 0.4.2 reduces delayed Sled control activation with early preparation, faster source-validated discovery and a fresh scan on race entry. Native timing and movement guards are retained; a new in-game retest is pending.

School Hub 4.49.0 adds Throw a Seed 0.1.1 with training, x2 pop-ups, throws, plant placement, upgrades and Auto Sell. Harpoon a Fish 0.1.7 improves Wave camera/barrel alignment, loaded-spear synchronization and teleport movement. Christmas Tree Lot 0.1.1 recovers stalled data reads while customer service continues. The new Harpoon and Tree Lot fixes still await an in-game retest.

School Hub 4.50.0 adds Jump for Cases 0.1.4. Full Auto Farm combines training circles and x2 bonuses, Perfect jumps, normal-speed running with carried cases, complete case opening, best animal placement and income collection. Opening and placement also work independently. The main cycle was confirmed in game on Delta in LDPlayer. Weight, speed, base and animal upgrades, rebirth and available reward claims have separate controls.

School Hub 4.50.1 corrects the Jump for Cases game caption in the shared menu.

School Hub 4.51.0 adds Blade Ball 0.2.0 with 100 switches across 10 sections: Auto Parry, spam and ability controls, curves and targeting, ball and player visuals, movement, cosmetics, world settings and retained reward/vote helpers. Auto Parry was confirmed in the accepted Delta/LDPlayer test without a kick; the report recorded 28 successful parries. Additional features and executor compatibility remain subject to individual in-game checks. Gameplay activities start disabled. Imported feature descriptions may use English fallback.

School Hub 4.51.1 adds all 26 current Sniper Arena places, including Arcade, ranked, mobile and trading rooms.

School Hub 4.52.0 adds Flat the Mountain 0.1.5 for Wave, with separate Lobby and Game menus. Full Auto Farm combines mining, owned-tool selection, vacuum collection and safe teleports. Purchases, upgrades and special tools have independent controls and currency limits. Lobby controls cover rooms, hosting, queueing, saved runs and teleport destinations. The latest Wave test was approved by the user; exhaustive feature and device coverage is not claimed.

This release also reviews ten-language presentation in Flat the Mountain, Jump for Cases, Blade Ball, Sniper Arena, Throw a Seed, Harpoon a Fish and Run a Christmas Tree Lot. Missing feature, help, dropdown and navigation text is filled, German Jump terminology is corrected, and Throw a Seed plant wording is corrected. Existing game algorithms and the accepted shared design are retained.

School Hub 4.53.0 adds CRAZY 8 Ball 0.1.0, with routes for both 8 Ball and 9 Ball. It includes trajectory prediction, configurable Auto Play and one-shot planning, ball/table overlays, a match HUD and manual table actions. All 21 gameplay switches and six scalar settings from the reviewed KingHub source are retained in the shared School Hub interface. Five billiards-specific navigation SVGs have single-line labels, and the new controls, help and status text are translated into ten languages. Existing 45 game factories and the accepted design baseline are preserved. Local source/protected startup checks cover both places; the observed Wave test confirms native module discovery and a calculated shot plan, without claiming exhaustive gameplay or device coverage.

CRAZY 8 Ball gameplay attribution: **KINGHUB | CRAZY 8 BALL**, from [David566734's public source](https://gist.github.com/David566734/f57e7529de918c262a94ed814d51242e). The transferred build retains the original attribution and 23 algorithm function bodies; School Hub supplies the common interface, lifecycle and scoped native bindings.

Run the hub using the existing command:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/suzukir987/School-Hub/main/loader.lua"))()
```

The launcher checks your key through [scriptrblx.com](https://scriptrblx.com/key/school-hub) and downloads the current game's module from private storage. A valid saved key opens Loading directly. New releases keep the same launch command.

### Credits

Based on Prometheus by Elias Oelschner, https://github.com/prometheus-lua/Prometheus

Prometheus Vmify protects the protocol client. UI and gameplay callbacks use native Lua code with separate obfuscation. See [School Hub credits](https://scriptrblx.com/about).

Blade Ball gameplay is adapted from Tokyo X / Rise v2.1.9 ([pinned source](https://github.com/hyuxalt/tokyoX/blob/3a9b8feb90dc2f2841ac385a1c2829b8d5bece0d/Loader.lua), original reference [joshhhie/rise](https://github.com/joshhhie/rise)). The reviewed gameplay core is bundled with the School Hub interface and lifecycle. The original outer loader and its extra branch are excluded.
