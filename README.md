# AwesomePlates-WotLK
**AwesomePlates** is a nameplates addon for WoW 3.3.5a, based on [_VirtualPlates](https://www.wowinterface.com/downloads/info14964-_VirtualPlates.html).  
It may not be compatible with other nameplate addons.

## Features
- Modified nameplate appearance (configurable in `AwesomePlates_Customize.lua`).
- Improved nameplate scanning and handling.
- Optional nameplate scaling and fading based on distance.
- Optional distance text displayed on nameplates.
- Custom glow for the target, focus and mouseover nameplates.
- TotemPlates-style functionality for totems and specific NPCs (editable list in the Totems folder).
- Optional class icons on friendly players in PvP instances.
- Optional player-only nameplate filter.
- Optional minimum nameplate level filter.

## Chat Commands  
- **`/ap scaling`** &nbsp; &nbsp; → Enables/disables dynamic scaling.
- **`/ap icons`** &nbsp; &nbsp; &nbsp;&nbsp; → Enables/disables class icons on PvP allies.
- **`/ap distance`** &nbsp; → Enables/disables distance text.
- **`/ap players`** &nbsp; &nbsp; → Enables/disables player-only filter.
- **`/ap level <#>`** → Sets minimum nameplate level filter.
- **`/console nameplateDistance <#>`** → Changes the nameplate visibility range.  
It's recommended to `/reload` after changing the `nameplateDistance` CVar

## Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/KhalGH/AwesomePlates-WotLK/refs/heads/assets/assets/AP_img1.jpg" 
       alt="AwesomePlates_img1" width="95%">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/KhalGH/AwesomePlates-WotLK/refs/heads/assets/assets/AP_img2.jpg" 
       alt="AwesomePlates_img2" width="95%">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/KhalGH/AwesomePlates-WotLK/refs/heads/assets/assets/AP_img3.jpg" 
       alt="AwesomePlates_img3" width="95%">
</p>

## Dependency
This addon requires the **C_NamePlate** `API` and **NAME_PLATE_UNIT** `Events` from Retail, which are not available in WoW 3.3.5a by default.
Support for these APIs and Events is provided through the custom library **AwesomeWotlk**, created by [FrostAtom](https://github.com/FrostAtom).  
To enable the addon you need [AwesomeWotlk v0.1.4-f3](https://github.com/KhalGH/awesome_wotlk/releases/tag/0.1.4-f3) or any newer version from [this fork](https://github.com/KhalGH/awesome_wotlk)

## Disclaimer
Private servers may have specific rules regarding the use of client modifications like the **AwesomeWotlk** library.  
Please verify your server’s policy to ensure the library is allowed before using it.  

## Installation
1. Download the [addon](https://github.com/KhalGH/AwesomePlates-WotLK/releases/download/v1.0/AwesomePlates-v1.0.zip) and the [AwesomeWotlk](https://github.com/KhalGH/AwesomePlates-WotLK/releases/download/v1.0/AwesomeWotlk.7z) library.  
2. Extract the `!!AwesomePlates` folder into `World of Warcraft/Interface/AddOns/`.  
3. Extract `AwesomeWotlk.7z` and follow the `Instructions.txt` file to implement it.  
4. Restart the game and enable the addon.

## Recommendations
AwesomePlates performs numerous visual update operations for scaling and fading each visible nameplate every 0.05 seconds.
This can lead to a significant processing load, especially when increasing the nameplate visibility range, which considerably raises the number of elements on screen.

To improve performance, consider the following recommendations:
- You can modify the `UpdateRate` variable at `line 59` in `AwesomePlates.lua` to reduce the visual update workload. Increasing it from 0.05 to around 0.10 may help, depending on what works best for your system.
- If performance issues persist but you still want to use the addon, you may consider disabling the dynamic scaling feature using the `/ap scaling` command. Doing so will considerably reduce the processing required on each update cycle.

## Information  
- **Addon Version:** 1.0  
- **Game Version:** 3.3.5a (WotLK)  
- **Author:** Khal
