# CLAUDE.md (中文版)

本文件为 Claude Code (claude.ai/code) 提供在此代码库中工作的指导。

## 项目概览

**《采邑春秋》(Project: Fiefdom)** - 一款以中国春秋时期为背景的历史模拟/角色扮演/策略游戏。使用 Godot 4.6 构建。

### 核心概念
一个"士大夫模拟器"，玩家（没落贵族）通过独特的**井田制**管理封地——3x3 网格布局，中心格为公田（产出归国君），周围8格为私田（产出归玩家）。

## 运行项目

1. 打开 Godot 4.6+
2. 通过选择 `project.godot` 导入项目
3. 按 F5 运行

**分辨率**：640x360，使用 viewport 缩放模式和整数缩放（适合像素艺术）

## 架构概览

### 自动加载单例 (Autoload Singletons)
这些在场景间持久存在：

- **`Global`** (`scripts/Global.gd`)：中央游戏状态管理器
  - 背包、金钱、声望、天数计数器
  - 玩家属性（六艺系统）
  - 门客管理和粮仓
  - 存档/读档系统（JSON 格式到 `user://savegame.json`）
  - 任务系统
  - **爵位系统**：下士 → 中士 → 上士 → 大夫 → 卿（5个等级）
  - **井田制系统**：管理多个井田网格（3x3布局）
  - **学派特质**：应用门客学派能力（儒家、墨家、法家、农家、兵家）

- **`GameEvents`** (`scripts/GameEvents.gd`)：用于解耦通信的信号总线
  - `crop_harvested(is_public: bool)` - 作物收获信号
  - `day_advanced(new_day: int)` - 天数推进信号
  - `stamina_changed`, `money_changed`, `reputation_changed` - 属性变化信号
  - `retainer_assigned`, `visitor_interacted`, `retainer_recruited` - 角色互动信号
  - `game_over()` - 游戏结束信号
  - `rank_promoted(new_rank: Rank)` - 爵位晋升信号
  - `well_field_created(well_field_id: int)` - 井田创建信号
  - `reformation_chosen(choice: String)` - 改革选择信号

- **`EventManager`** (`scripts/EventManager.gd`)：重大历史事件系统
  - 检测并触发历史事件（如"初税亩"改革）
  - 管理事件条件和时机
  - 应用事件后果

- **`ItemManager`** (`scripts/ItemManager.gd`)：集中化的作物/物品数据
  - 存储所有 CropData 资源（黍、稷、稻、麦、菽、桑、麻）
  - 使用 `ItemManager.get_crop(id)` 访问作物数据

- **`AudioManager`** (`scripts/AudioManager.gd`)：音频播放控制
  - 使用 AudioStreamGenerator 程序化生成音效
  - 事件音效（爵位晋升、历史事件、田地开垦）

### 数据驱动设计

项目大量使用 Godot 的**资源(Resource)**系统进行数据管理：

- **`CropData`**：作物属性（名称、生长阶段、售价、特殊标记如 `is_water_crop`、`restores_fertility`、`is_perennial`）
- **`RetainerData`**：带学派系统的 NPC 数据
  - 属性：姓名、职业、忠诚度、效率
  - **学派枚举**：儒家、墨家、法家、农家、兵家
  - **学派能力**：每个学派拥有独特的被动效果
- **`VisitorData`**：访客遭遇数据

所有游戏数据都应定义为 Resource，而非硬编码在脚本中。

### 场景组织

- **`Main.tscn`**：包含 World、UI 层和 WellFieldMarker 的根场景
- **`World`** 场景：处理 TileMap、玩家、作物、访客、敌人和核心游戏逻辑
- **`Player.tscn`**：带有 FSM（IDLE、RUN、TOOL_USE）的角色控制器
- **UI 场景**：`ManagementPanel`、`DialoguePanel`、`SettingsPanel`
- **事件面板**：`EventPanel.tscn` - 历史事件对话框（含选择分支）
- **开垦面板**：`ReclamationPanel.tscn` - 田地开垦界面（3x3可视化选择器）
- **调试面板**：`DebugPanel.tscn` - 开发测试工具（仅在调试模式显示）

### 核心脚本

- **`World.gd`**：主游戏逻辑处理器
  - 瓦片交互（种植、收获、浇水）
  - 作物管理通过 `active_crops: Dictionary`（键：Vector2i，值：作物数据）
  - 生成访客和敌人
  - 天数推进逻辑

- **`Player.gd`**：角色控制器
  - 使用 CharacterBody2D 移动
  - 鼠标与瓦片交互
  - 动画状态机

- **`UIManager.gd`**：UI 控制器
  - 更新所有 UI 元素
  - 处理对话面板
  - 门客管理面板
  - 集成 EventPanel、ReclamationPanel、DebugPanel

- **`EventManager.gd`**：重大事件系统（autoload 单例）
  - 检测事件触发条件（第3年、爵位阈值、产出比例）
  - 显示 EventPanel 叙事和选择
  - 应用后果（税率变化、忠诚度变化、特殊物品）

- **`EventPanel.gd`**：事件对话框 UI
  - 显示事件标题、说话者、描述
  - 呈现2-3个选项按钮及其后果
  - 触发选择后效果

- **`ReclamationPanel.gd`**：田地开垦 UI
  - 可视化3x3位置选择器（鼠标跟踪）
  - 实时有效性检查（绿色=有效，红色=无效）
  - 成本计算和确认

- **`DebugPanel.gd`**：开发测试面板
  - 快速资源调整（金钱、粮食、声望）
  - 爵位晋升和事件触发
  - 随机门客生成
  - H键切换显示

- **`WellFieldMarker.gd`**：井田视觉标记系统
  - 绘制彩色边界线（Line2D）
  - 显示井田ID标签（#0、#1、#2...）
  - 高亮公田（中央瓦片）为金色标记

### TileMap 系统

使用带有**自定义数据层(Custom Data Layers)**的 **TileMapLayer**：

1. **Layer 0 (Ground)**：泥土、草地
2. **Layer 1 (Crops)**：生长中的作物

**关键自定义数据**：`is_public_field`（布尔值）
- 3x3 网格的中心瓦片设为 `is_public_field = true`
- 收获时检查此标志，将输出路由到 king_storage 或 player_inventory

```gdscript
# 收获逻辑示例
var tile_data = ground_layer.get_cell_tile_data(coords)
var is_public = tile_data.get_custom_data("is_public_field")
if is_public:
    Global.king_storage += 1
    Global.reputation += 10
else:
    Global.player_inventory += 1
    Global.money += 5
```

### 作物系统

作物存储在 `Global.active_crops: Dictionary` 中：
- 键：`Vector2i`（网格位置）
- 值：包含以下键的字典：`id`、`data`、`age`、`watered`

**重要**：不要为每个作物实例化节点。使用字典存储以提高性能。

### 二十四节气

游戏使用传统的二十四节气进行时间追踪：
- `Global.SOLAR_TERMS` 数组（立春、雨水、惊蛰等）
- `Global.get_current_solar_term()` 根据天数返回当前节气

## 开发阶段

项目遵循分阶段开发方法（见 `docs/phase/`）：

- **阶段 1**：核心机制（井田制、耕种、收获）- ✅ 已完成
- **阶段 2**：门客 AI 与经济 - ✅ 已完成
- **阶段 3**：六艺 RPG 系统与访客 - 🚧 进行中
- **阶段 4**：战斗与荒野探索 - 🚧 进行中
- **阶段 5**：生产打磨 - 🚧 进行中

**当前总体进度**：约75%

## 代码规范

1. **强类型 GDScript**：使用静态类型
   ```gdscript
   func harvest(coords: Vector2i) -> void:
   ```

2. **基于信号的通信**：使用 GameEvents 进行跨系统通信
   - 在逻辑脚本中发送信号
   - 在 UI 脚本中连接以更新显示
   - 避免远距离系统间的直接引用

3. **数据驱动**：所有游戏数据使用 Resource 类
   - 将新作物创建为 .tres 资源文件
   - 通过 ItemManager 单例访问

4. **中文语言**：UTF-8 编码。文档使用中文。

## 核心游戏机制

### 井田制
- **基础布局**：3x3网格，公田在中心，8格私田环绕
- **公田**（中心格）→ 国库（声望）
- **私田**（周围8格）→ 玩家背包（金钱）
- **声望**必须维持以避免"削爵"（剥夺爵位）
- **扩展系统**：
  - 爵位决定最大井田数：下士(1) → 中士(2) → 上士(4) → 大夫(9) → 卿(16)
  - 田地开垦消耗：铜钱+粮食+分配门客
  - 3x3完整性验证：9个瓦片必须都可开垦
  - 开垦进度：0-4天（清除植被→翻土→标记→可种植）
- **视觉标记**：彩色边界线、ID标签、金色公田标记

### 每日循环
- 玩家：种植 → 浇水 → 睡觉
- 门客：自动工作（如已分配）
- 夜晚：粮食消耗、作物生长、体力恢复

### 游戏结束条件
- 声望过低（因未能完成公田贡献）
- 饥荒（没有粮食供养门客）

### 历史事件
- **重大事件**：在特定里程碑触发（如第3年"初税亩"改革）
- **事件系统**：EventManager检测条件并显示EventPanel
- **玩家选择**：多条路线，不同后果
  - 法家路线：所有田地变私田，20%税率，金钱+300%，周礼评分↓
  - 儒家路线：保持井田制，稀有礼物，忠诚度↑
  - 观望路线：拖延1年，每月100铜钱，最终必须站队
- **后果**：税率计算、门客忠诚度变化、特殊奖励

### 门客学派系统
每个门客属于五大流派之一，提供独特被动能力：

| 学派 | 特质 | 效果 |
|------|------|------|
| **儒家** | 忠诚光环 | 每个儒家门客提升其他门客30%忠诚度/天 |
| **墨家** | 工巧加成 | 工作效率+20%，自动修缮设施（待实现） |
| **法家** | 税收加成 | 公田声望收益+20% |
| **农家** | 耕作专家 | 私田产量+50% |
| **兵家** | 军事纪律 | 工作效率+30%，主动防御（待实现） |

使用 `RetainerData.get_school_name()` 和 `RetainerData.apply_school_ability()` 访问学派机制。

## 文件结构

```
res://
├── scenes/          # .tscn 场景文件
├── scripts/         # .gd 脚本
├── resources/       # .tres 资源文件 (game_tileset.tres, game_theme.tres)
├── assets/          # 美术资源（占位符/未命名）
├── docs/            # 设计文档和阶段计划
└── project.godot    # 项目配置
```

## 常见任务

### 添加新作物
1. 在 `ItemManager._init_crops()` 中创建作物数据
2. 添加生长阶段的图集坐标
3. 配置属性（days_to_grow、sell_price、特殊标记）

### 添加新游戏状态
1. 在 `Global.gd` 中添加变量
2. 在 `GameEvents.gd` 中添加相应信号
3. 更新 `UIManager.gd` 以显示
4. 在 `Global.gd` 中更新存档/读档函数

### 瓦片交互
使用 `World.gd` 中的模式：
```gdscript
var mouse_pos = get_global_mouse_position()
var coords = ground_layer.local_to_map(mouse_pos)
```

### 添加新井田
1. 检查爵位容量：`Global.well_fields.size() < Global.MAX_WELL_FIELDS[Global.rank]`
2. 验证3x3区域：`Global.can_create_well_field_at(center_pos: Vector2i)`
3. 检查玩家资源：`Global.money >= RECLAMATION_COST[0]`
4. 创建井田：`Global.create_well_field(center_pos: Vector2i)`
5. 更新 WellFieldMarker 视觉显示

### 添加新历史事件
1. 在 `EventManager.gd` 中定义事件条件（年份、爵位、产出阈值）
2. 创建事件数据结构（标题、说话者、描述、选项）
3. 添加 EventPanel UI 和选项按钮
4. 在事件处理器中实现后果
5. 添加事件状态的存档/读档支持

### 添加新门客学派
1. 在 `RetainerData.School` 添加枚举值
2. 实现 `get_school_name()` 和 `apply_school_ability()` 方法
3. 在相关游戏系统中添加能力逻辑（收获、工作、声望）
4. 更新 UI 显示学派图标/名称
5. 在调试面板测试能力效果

## 重要设计文档

- `docs/核心设计.md`：综合 GDD（游戏设计文档）
- `docs/游戏玩法.md`：详细游戏机制
- `docs/implementation_summary.md`：井田扩展和税收改革事件实现总结
- `docs/核心算法缺失分析.md`：缺失核心算法分析
- `docs/phase/Phase1.md`：阶段 1 开发计划（已完成）
- `docs/phase/phase2.md`：阶段 2 开发计划（已完成）
- `docs/phase/phase3.md`：阶段 3 开发计划
- `docs/phase/phase4.md`：阶段 4 开发计划
- `docs/phase/phase5.md`：阶段 5 开发计划

## 技术要点

### 井田制实现细节
- 使用 TileSet 的 Custom Data Layer 标记公田/私田
- 收获时根据 `is_public_field` 标志路由产出
- 公田产出增加声望，私田产出增加金钱

### 门客 AI
- 简单状态机：IDLE → MOVE → WORK → REST
- 使用 NavigationAgent2D 进行寻路
- 通过拖拽 UI 分配工作区域

### 存档系统
- JSON 格式存储到 `user://savegame.json`
- 保存：天数、金钱、背包、粮仓、声望、作物状态
- Vector2i 坐标转换为字符串 "x,y" 格式存储
