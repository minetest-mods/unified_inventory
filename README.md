# Unified Inventory

[![](https://github.com/minetest-mods/unified_inventory/workflows/Check%20&%20Release/badge.svg)](https://github.com/minetest-mods/unified_inventory/actions)
[![ContentDB](https://content.luanti.org/packages/RealBadAngel/unified_inventory/shields/downloads/)](https://content.luanti.org/packages/RealBadAngel/unified_inventory/)

![Screenshot](screenshot.png)

Unified Inventory replaces the default survival and creative inventory.


## Features

 * Node, item and tool browser
 * Crafting guide
    * Can copy the recipe to the crafting grid
    * Recipe search function by ingredients
 * Up to four bags with up to 24 slots each
 * Home function to teleport
 * Trash slot and refill slot for creative
 * Waypoints to keep track of important locations
 * Lite mode: reduces the item browser width
    * `minetest.conf` setting `unified_inventory_lite = true`
    * Alternatively, use the mod `playersettings`.
 * Mod API for modders: see [mod_api.txt](doc/mod_api.txt)
 * Setting-determinated features: see [settingtypes.txt](settingtypes.txt)


## Dependencies

 * Luanti 5.4.0+

### Optional dependencies

 * Mod `default` for category filters (part of Minetest Game)
 * Mod `farming` for craftable bags (part of Minetest Game)
 * To load waypoints of very old worlds: [`datastorage`](https://github.com/minetest-technic/datastorage)
 * Player-specific settings: [`playersettings`](https://cheapiesystems.com/git/playersettings/)


# Licenses

Copyright (C) 2012-2014 Maciej Kasatkin (RealBadAngel)

Copyright (C) 2012-? Various minetest-mods contributors

* Code: LGPL 2.1+
* Textures: CC-BY-SA 4.0 and others
* Sounds: CC 4.0 and others

For details, see [LICENSE.txt](LICENSE.txt)
