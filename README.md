# Unified Inventory

[![](https://github.com/minetest-mods/unified_inventory/workflows/Check%20&%20Release/badge.svg)](https://github.com/minetest-mods/unified_inventory/actions)

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
 * Mod API for modders: see [mod_api.txt](doc/mod_api.txt)
 * Setting-determinated features: see [settingtypes.txt](settingtypes.txt)


## Requirements

 * Minetest 5.4.0+
 * Mod `default` for category filters (contained in Minetest Game)
 * Mod `farming` for craftable bags (contained in Minetest Game)
 * For waypoint migration: `datastorage`


# Licenses

Copyright (C) 2012-2014 Maciej Kasatkin (RealBadAngel)

Copyright (C) 2012-? Various minetest-mods contributors


## Code

GNU LGPLv2+, see [license notice](LICENSE.txt)


## Textures

VanessaE: (CC-BY-4.0)

  * `ui_group.png`

Tango Project: (Public Domain, CC-BY-4.0)

  * [`ui_reset_icon.png`](https://commons.wikimedia.org/wiki/File:Edit-clear.svg)
  * [`ui_doubleleft_icon.png`](http://commons.wikimedia.org/wiki/File:Media-seek-backward.svg)
  * [`ui_doubleright_icon.png`](http://commons.wikimedia.org/wiki/File:Media-seek-forward.svg)
  * [`ui_left_icon.png` / `ui_right_icon.png`](http://commons.wikimedia.org/wiki/File:Media-playback-start.svg)
  * [`ui_skip_backward_icon.png`](http://commons.wikimedia.org/wiki/File:Media-skip-backward.svg)
  * [`ui_skip_forward_icon.png`](http://commons.wikimedia.org/wiki/File:Media-skip-forward.svg)

From http://www.clker.com (Public Domain, CC-BY-4.0):

  * [`bags_small.png`](http://www.clker.com/clipart-moneybag-empty.html)
  * [`bags_medium.png`](http://www.clker.com/clipart-backpack-1.html)
  * [`bags_large.png` / `ui_bags_icon.png`](http://www.clker.com/clipart-backpack-green-brown.html)
  * `ui_trash_icon.png`: <http://www.clker.com/clipart-29090.html> and <http://www.clker.com/clipart-trash.html>
  * [`ui_search_icon.png`](http://www.clker.com/clipart-24887.html)
  * [`ui_off_icon.png` / `ui_on_icon.png`](http://www.clker.com/clipart-on-off-switches.html)
  * [`ui_waypoints_icon.png`](http://www.clker.com/clipart-map-pin-red.html)
  * [`ui_circular_arrows_icon.png`](http://www.clker.com/clipart-circular-arrow-pattern.html)
  * [`ui_pencil_icon.pnc`](http://www.clker.com/clipart-2256.html)
  * [`ui_waypoint_set_icon.png`](http://www.clker.com/clipart-larger-flag.html)

Everaldo Coelho (YellowIcon) (LGPL v2.1+):

  * [`ui_craftguide_icon.png` / `ui_craft_icon.png`](http://commons.wikimedia.org/wiki/File:Advancedsettings.png)

Gregory H. Revera: (CC-BY-SA 3.0)

  * [`ui_moon_icon.png`](http://commons.wikimedia.org/wiki/File:FullMoon2010.jpg)

Thomas Bresson: (CC-BY 3.0)

  * [`ui_sun_icon.png`](http://commons.wikimedia.org/wiki/File:2012-10-13_15-29-35-sun.jpg)

Fibonacci: (Public domain, CC-BY 4.0)

  * [`ui_xyz_off_icon.png`](http://commons.wikimedia.org/wiki/File:No_sign.svg)

Gregory Maxwell: (Public domain, CC-BY 4.0)

  * [`ui_ok_icon.png`](http://commons.wikimedia.org/wiki/File:Yes_check.svg)

Adrien Facélina: (LGPL v2.1+)

  * [`inventory_plus_worldedit_gui.png`](http://commons.wikimedia.org/wiki/File:Erioll_world_2.svg)

Other files from Wikimedia Commons:

  * [`ui_gohome_icon.png` / `ui_home_icon.png` / `ui_sethome_icon.png`](http://commons.wikimedia.org/wiki/File:Home_256x256.png) (GPL v2+)

RealBadAngel: (CC-BY-4.0)

  * Everything else.
