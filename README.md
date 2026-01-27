# 采邑春秋 (Project: Fiefdom) - Phase 1 Prototype

## Overview
This project is a Godot 4.x prototype implementing the core "Well-Field System" (井田制) mechanics.

## Project Structure
- `res://scenes/`: Contains the main scenes (`Main.tscn`, `Player.tscn`).
- `res://scripts/`: Contains GDScript logic.
  - `World.gd`: Core game logic (farming, harvesting, well-field rules).
  - `Player.gd`: Character movement and input.
  - `UIManager.gd`: Handles UI updates.
  - `GameEvents.gd`: Global signal bus.
  - `Global.gd`: Global state (inventory, day, etc.).
- `res://resources/`: Custom Resources.
  - `game_tileset.tres`: TileSet with Custom Data Layer ("is_public_field").

## How to Run
1. Open Godot 4.6 (or later).
2. Import this project by selecting the `project.godot` file.
3. Run the project (F5).

## Controls
- **WASD / Arrows**: Move Player.
- **Mouse Click**: Interact with tiles (Plant / Harvest).
- **Sleep Button**: Advance to the next day (grow crops).

## Mechanics Implemented
- **Public vs Private Fields**: 
  - Center tile (Public) output goes to King's Treasury (Reputation).
  - Surrounding tiles (Private) output goes to Player Inventory (Money).
- **Farming Loop**: Plant -> Sleep -> Harvest.
