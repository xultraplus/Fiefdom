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
  - **Rank system**: LOWER_SCHOLAR → MIDDLE_SCHOLAR → UPPER_SCHOLAR → GRAND_MASTER → MINISTER (5 levels)
  - **Well-field system**: Manages multiple well-field grids (3x3 layouts)
  - **School traits**: Applies retainer school abilities (Confucian, Mohist, Legalist, Agriculturalist, Militarist)

- **`GameEvents`** (`scripts/GameEvents.gd`): Signal bus for decoupled communication
  - `crop_harvested(is_public: bool)`
  - `day_advanced(new_day: int)`
  - `stamina_changed`, `money_changed`, `reputation_changed`
  - `retainer_assigned`, `visitor_interacted`, `retainer_recruited`
  - `game_over()`
  - `rank_promoted(new_rank: Rank)`
  - `well_field_created(well_field_id: int)`
  - `reformation_chosen(choice: String)`

- **`EventManager`** (`scripts/EventManager.gd`): Major historical event system
  - Detects and triggers historical events (e.g., "初税亩" Tax Reform)
  - Manages event conditions and timing
  - Applies event consequences

- **`ItemManager`** (`scripts/ItemManager.gd`): Centralized crop/item data
  - Stores all CropData resources (millet, sorghum, rice, wheat, beans, mulberry, hemp)
  - Use `ItemManager.get_crop(id)` to access crop data

- **`AudioManager`** (`scripts/AudioManager.gd`): Audio playback control
  - Procedural sound generation using AudioStreamGenerator
  - Event sounds (rank promotion, historical events, land reclamation)

### Data-Driven Design

The project heavily uses Godot's **Resource** system for data:

- **`CropData`**: Crop properties (name, growth stages, sell price, special flags like `is_water_crop`, `restores_fertility`, `is_perennial`)
- **`RetainerData`**: NPC data with school system
  - Properties: name, profession, loyalty, efficiency
  - **School enum**: CONFUCIAN, MOHIST, LEGALIST, AGRICULTURALIST, MILITARIST
  - **School abilities**: Each school has unique passive effects
- **`VisitorData`**: Visitor encounters

All game data should be defined as Resources, not hardcoded in scripts.

### Scene Organization

- **`Main.tscn`**: Root scene containing World, UI layers, and WellFieldMarker
- **`World`** scene: Handles TileMap, player, crops, visitors, enemies, and core game logic
- **`Player.tscn`**: Character controller with FSM (IDLE, RUN, TOOL_USE)
- **UI scenes**: `ManagementPanel`, `DialoguePanel`, `SettingsPanel`
- **Event Panel**: `EventPanel.tscn` - Historical event dialog with choices
- **Reclamation Panel**: `ReclamationPanel.tscn` - Land clearing interface with 3x3 visual selector
- **Debug Panel**: `DebugPanel.tscn` - Testing tools (visible only in debug mode)

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
  - Integration with EventPanel, ReclamationPanel, DebugPanel

- **`EventManager.gd`**: Major event system (autoload singleton)
  - Detects event triggers (year 3, rank threshold, production ratios)
  - Shows EventPanel with narrative and choices
  - Applies consequences (tax changes, loyalty shifts, special items)

- **`EventPanel.gd`**: Event dialog UI
  - Displays event title, speaker, description
  - Presents 2-3 choice buttons with consequences
  - Triggers post-choice effects

- **`ReclamationPanel.gd`**: Land reclamation UI
  - Visual 3x3 position selector with mouse tracking
  - Real-time validity checking (green = valid, red = invalid)
  - Cost calculation and confirmation

- **`DebugPanel.gd`**: Development testing panel
  - Quick resource adjustments (money, food, reputation)
  - Rank promotion and event triggers
  - Random retainer generation
  - Toggle with H key

- **`WellFieldMarker.gd`**: Visual marking system for well-fields
  - Draws colored boundary lines (Line2D)
  - Shows well-field ID labels (#0, #1, #2...)
  - Highlights public field (center tile) with golden marker

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

- **Phase 1**: Core mechanics (Well-Field system, farming, harvesting) - ✅ Completed
- **Phase 2**: Retainer AI & economy - ✅ Completed
- **Phase 3**: Six Arts RPG system & visitors - 🚧 In Progress
- **Phase 4**: Combat & wilderness exploration - 🚧 In Progress
- **Phase 5**: Production polish - 🚧 In Progress

**Current Overall Progress**: ~75%

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
- **Basic Layout**: 3x3 grid with public field (center) and 8 private fields
- **Public field** (center tile) → King's Treasury (Reputation)
- **Private fields** (8 surrounding) → Player Inventory (Money)
- **Reputation** must be maintained to avoid "削爵" (stripping of rank)
- **Expansion System**:
  - Rank determines max well-fields: Lower Scholar (1) → Middle Scholar (2) → Upper Scholar (4) → Grand Master (9) → Minister (16)
  - Land reclamation costs: copper + food + assigned retainers
  - 3x3 completeness validation: all 9 tiles must be reclaimable
  - Reclamation progress: 0-4 days (clearing → tilling → marking → plantable)
- **Visual Markers**: Colored boundaries, ID labels, golden public field indicator

### Daily Loop
- Player: Plant → Water → Sleep
- Retainers: Auto-work (if assigned)
- Night: Food consumption, crop growth, stamina restoration

### Game Over Conditions
- Reputation drops too low (from failing public field contributions)
- Starvation (no food for retainers)

### Historical Events
- **Major Events**: Triggered at specific milestones (e.g., "初税亩" Tax Reform in Year 3)
- **Event System**: EventManager detects conditions and shows EventPanel
- **Player Choices**: Multiple paths with different consequences
  - Legalist path: All fields become private, 20% tax rate, money +300%, rites score ↓
  - Confucian path: Maintain well-field system, rare gifts, loyalty ↑
  - Wait-and-see: Delay 1 year, monthly 100 copper, must choose eventually
- **Consequences**: Tax rate calculations, retainer loyalty shifts, special rewards

### Retainer School System
Each retainer belongs to one of five schools, providing unique passive abilities:

| School | Trait | Effect |
|--------|-------|--------|
| **Confucian** | Loyalty Aura | +30% loyalty/day for all other retainers per Confucian |
| **Mohist** | Craftsmanship | +20% work efficiency, auto-repair facilities (TODO) |
| **Legalist** | Tax Bonus | +20% reputation gain from public fields |
| **Agriculturalist** | Farming Expert | +50% yield from private fields |
| **Militarist** | Military Discipline | +30% work efficiency, active defense (TODO) |

Use `RetainerData.get_school_name()` and `RetainerData.apply_school_ability()` to access school mechanics.

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

### Adding a New Well-Field
1. Check rank capacity: `Global.well_fields.size() < Global.MAX_WELL_FIELDS[Global.rank]`
2. Validate 3x3 area using `Global.can_create_well_field_at(center_pos: Vector2i)`
3. Check player resources: `Global.money >= RECLAMATION_COST[0]`
4. Create well-field: `Global.create_well_field(center_pos: Vector2i)`
5. Update WellFieldMarker visual display

### Adding a New Historical Event
1. Define event conditions in `EventManager.gd` (year, rank, production thresholds)
2. Create event data structure (title, speaker, description, choices)
3. Add EventPanel UI with choice buttons
4. Implement consequences in event handler
5. Add save/load support for event state

### Adding a New Retainer School
1. Add enum value to `RetainerData.School`
2. Implement `get_school_name()` and `apply_school_ability()` methods
3. Add ability logic to relevant game systems (harvest, work, reputation)
4. Update UI to display school icon/name
5. Test ability effects in Debug Panel

## Important Design Documents

- `docs/核心设计.md`: Comprehensive GDD (Game Design Document)
- `docs/游戏玩法.md`: Detailed gameplay mechanics
- `docs/implementation_summary.md`: Implementation summary for well-field expansion and tax reform event
- `docs/核心算法缺失分析.md`: Analysis of missing core algorithms
- `docs/phase/Phase1.md`: Phase 1 development plan (completed)
- `docs/phase/phase2.md`: Phase 2 development plan (completed)
- `docs/phase/phase3.md`: Phase 3 development plan
- `docs/phase/phase4.md`: Phase 4 development plan
- `docs/phase/phase5.md`: Phase 5 development plan
