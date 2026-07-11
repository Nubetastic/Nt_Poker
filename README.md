# Nt_Poker

Short RedM poker resource for Texas Hold 'Em tables with player betting, NPC opponents, props, and a custom NUI card interface.

## Requirements

- RedM
- RSG Core or VORP
- ox_lib
- oxmysql

## Features

- Configurable poker tables, seats, keys, animations, props, and house cut
- Texas Hold 'Em hand evaluation with tie breakers
- Ante, raise limits, betting turns, fold/check/call/raise, and auto next hand
- Players can join active tables between hands
- Server-controlled NPC players with configurable names, models, profiles, and cash
- Supports table props and updated UI assets

## Setup

1. Place this folder in your RedM resources.
2. Configure `Config.Framework` in `config.lua` as `RSG` or `Vorp`.
3. Edit table locations in `config.lua`.
    - Many default tables are already setup.
4. Edit NPC behavior in `configNPC.lua`.
    - Configure when they are enabled.
5. Add `ensure Nt_Poker` to your server config.

## Notes

Card face textures on held player cards are not changed by this resource.
PropTest is included but not active, this is a tool for this script for adding props to the config.
Audio does not work, I do not have the audio files the script was originally designed with.
