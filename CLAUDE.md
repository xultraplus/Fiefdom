# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**《采邑春秋》(Project: Fiefdom)** - A historical simulation/RPG/strategy game set in the Spring and Autumn period of ancient China. Built with Godot 4.6.

### Core Concept
A "scholar-official simulator" where the player (a fallen noble) manages a fiefdom using the unique **Well-Field System (井田制)** - a 3x3 grid layout where the center tile is public field (产出归国君) and surrounding 8 tiles are private fields (产出归玩家).

## Running the Project

1. Open Godot 4.6+
2. Import project by selecting `project.godot`
3. Press F5 to run

**Resolution**: 640x360 with viewport scaling and integer scale mode (pixel art friendly)

## Architecture Overview

### Autoload Singletons
These are loaded once and persist across scenes:

- **`Global`** (`scripts/Global.gd`): Central game state manager
  - Inventory, money, reputation, day counter
  - Player stats (Six Arts system)
  - Retainer management and food storage
  - Save/Load system (JSON format to `user://savegame.json`)
  - Quest system
  - Rank system (LOWER_SCHOLAR, MIDDLE_SCHOLAR, UPPER_SCHOLAR)

- **`GameEvents`** (`scripts/GameEvents.gd`): Signal bus for decoupled communication
  - `crop_harvested(is_public: bool)`
  - `day_advanced(new_day: int)`
  - `stamina_changed`, `money_changed`, `reputation_changed`
  - `retainer_assigned`, `visitor_interacted`, `retainer_recruited`
  - `game_over()`

- **`ItemManager`** (`scripts/ItemManager.gd`): Centralized crop/item data
  - Stores all CropData resources (millet, sorghum, rice, wheat, beans, mulberry, hemp)
  - Use `ItemManager.get_crop(id)` to access crop data

- **`AudioManager`** (`scripts/AudioManager.gd`): Audio playback control

### Data-Driven Design

The project heavily uses Godot's **Resource** system for data:

- **`CropData`**: Crop properties (name, growth stages, sell price, special flags like `is_water_crop`, `restores_fertility`, `is_perennial`)
- **`RetainerData`**: NPC data (name, profession, loyalty, efficiency)
- **`VisitorData`**: Visitor encounters

All game data should be defined as Resources, not hardcoded in scripts.

### Scene Organization

- **`Main.tscn`**: Root scene containing World and UI layers
- **`World`** scene: Handles TileMap, player, crops, visitors, enemies, and core game logic
- **`Player.tscn`**: Character controller with FSM (IDLE, RUN, TOOL_USE)
- **UI scenes**: `ManagementPanel`, `DialoguePanel`, `SettingsPanel`

### Key Scripts

- **`World.gd`**: Main game logic handler
  - Tile interactions (plant, harvest, water)
  - Crop management via `active_crops: Dictionary` (Key: Vector2i, Value: crop data)
  - Spawning visitors and enemies
  - Day advancement logic

- **`Player.gd`**: Character controller
  - Movement with CharacterBody2D
  - Mouse interaction with tiles
  - State machine for animations

- **`UIManager.gd`**: UI controller
  - Updates all UI elements
  - Handles dialogue panels
  - Management panel for retainers

### TileMap System

Uses **TileMapLayer** with **Custom Data Layers**:

1. **Layer 0 (Ground)**: Soil, grass
2. **Layer 1 (Crops)**: Growing crops

**Critical Custom Data**: `is_public_field` (boolean)
- Center tiles of 3x3 grids have `is_public_field = true`
- Harvest checks this flag to route output to king_storage vs player_inventory

```gdscript
# Example harvest logic pattern
var tile_data = ground_layer.get_cell_tile_data(coords)
var is_public = tile_data.get_custom_data("is_public_field")
if is_public:
    Global.king_storage += 1
    Global.reputation += 10
else:
    Global.player_inventory += 1
    Global.money += 5
```

### Crop System

Crops are stored in `Global.active_crops: Dictionary`:
- Key: `Vector2i` (grid position)
- Value: Dictionary with keys: `id`, `data`, `age`, `watered`

**Important**: Do NOT instantiate a node for each crop. Use dictionary storage for performance.

### Solar Terms (节气)

The game uses traditional 24 solar terms for time tracking:
- `Global.SOLAR_TERMS` array (立春, 雨水, 惊蛰, etc.)
- `Global.get_current_solar_term()` returns current term based on day

## Development Phases

The project follows a phased development approach (see `docs/phase/`):

- **Phase 1** (Current): Core mechanics (Well-Field system, farming, harvesting)
- **Phase 2**: Retainer AI & economy (completed in codebase)
- **Phase 3**: Six Arts RPG system & visitors
- **Phase 4**: Combat & wilderness exploration
- **Phase 5**: Production polish

## Code Conventions

1. **Strongly Typed GDScript**: Use static typing
   ```gdscript
   func harvest(coords: Vector2i) -> void:
   ```

2. **Signal-Based Communication**: Use GameEvents for cross-system communication
   - Emit signals in logic scripts
   - Connect in UI scripts for updates
   - Avoid direct references between distant systems

3. **Data-Driven**: Use Resource classes for all game data
   - Create new crops as .tres resource files
   - Access via ItemManager singleton

4. **Chinese Language**: UTF-8 encoding. Documentation in Chinese.

## Key Gameplay Mechanics

### Well-Field System (井田制)
- Public field (center tile) → King's Treasury (Reputation)
- Private fields (8 surrounding) → Player Inventory (Money)
- Reputation must be maintained to avoid "削爵" (stripping of rank)

### Daily Loop
- Player: Plant → Water → Sleep
- Retainers: Auto-work (if assigned)
- Night: Food consumption, crop growth, stamina restoration

### Game Over Conditions
- Reputation drops too low (from failing public field contributions)
- Starvation (no food for retainers)

## File Structure

```
res://
├── scenes/          # .tscn scene files
├── scripts/         # .gd scripts
├── resources/       # .tres resource files (game_tileset.tres, game_theme.tres)
├── assets/          # Art assets (placeholder/untitled)
├── docs/            # Design documents and phase plans
└── project.godot    # Project configuration
```

## Common Tasks

### Adding a New Crop
1. Create crop data in `ItemManager._init_crops()`
2. Add atlas coords for growth stages
3. Configure properties (days_to_grow, sell_price, special flags)

### Adding New Game State
1. Add variable to `Global.gd`
2. Add corresponding signal to `GameEvents.gd`
3. Update `UIManager.gd` to display
4. Update save/load functions in `Global.gd`

### Tile Interaction
Use the pattern from `World.gd`:
```gdscript
var mouse_pos = get_global_mouse_position()
var coords = ground_layer.local_to_map(mouse_pos)
```

## Important Design Documents

- `docs/核心设计.md`: Comprehensive GDD (Game Design Document)
- `docs/游戏玩法.md`: Detailed gameplay mechanics
- `docs/phase/Phase1.md`: Phase 1 development plan (completed)
- `docs/phase/phase2.md`: Phase 2 development plan (completed)
- `docs/phase/phase3.md`: Phase 3 development plan
