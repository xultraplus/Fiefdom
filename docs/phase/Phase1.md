针对《采邑春秋》（Project: Fiefdom）在 **Godot 4.6**（基于Godot 4.x系列的最新特性）下的开发，**第一阶段（Phase 1）**的目标必须非常明确：**核心机制原型验证（Core Mechanic Prototyping）**。

这一阶段**不追求美术精美**（使用色块或免费素材），**不追求内容量**（只有一种作物），**只追求代码架构的稳健性**和**核心玩法循环的闭环**。

我们把时间设定为 **4周（1个月）**，分为4个冲刺（Sprint）。

---

### 第一阶段开发目标： "井田制下的第一天"
**完成定义 (Definition of Done)**：
玩家可以控制角色移动，在“井”字形田地上进行开垦、播种、浇水；经过“过夜”操作后作物生长；收获时系统能自动识别是“公田”还是“私田”，并将产出分别放入“国库”和“背包”。

---

### 详细开发计划表

#### 第一周：项目基建与角色控制 (Project Setup & Player)
**重点**：确立 Godot 4.x 的架构，利用 `CharacterBody2D`。

1.  **项目设置**：
    *   **分辨率**：像素风推荐设置 `Viewport Width/Height` 为 `640x360` (或 `480x270`)，`Stretch Mode` 设为 `viewport`，`Scale Mode` 设为 `integer`（整数缩放防模糊）。
    *   **文件结构**：
        *   `res://scenes/` (存放 .tscn)
        *   `res://scripts/` (存放 .gd)
        *   `res://resources/` (存放自定义 Resource 数据)
        *   `res://assets/` (美术/音效)
2.  **角色控制器 (Player Controller)**：
    *   节点：`CharacterBody2D` + `CollisionShape2D` + `Sprite2D`。
    *   脚本：实现 8 方向移动。
    *   **关键架构**：建立一个有限状态机 (FSM) 管理玩家状态：`IDLE` (空闲), `RUN` (跑), `TOOL_USE` (使用农具)。
3.  **交互检测**：
    *   不使用 RayCast，推荐使用 **Mouse Position + Grid Snapping**。
    *   编写一个工具函数 `get_mouse_grid_pos()`，将鼠标坐标转化为 TileMap 的整数坐标 (Vector2i)。

#### 第二周：地图系统与井田制实现 (TileMap & Well-Field)
**重点**：利用 Godot 4 的 `TileMapLayer` 和 `Custom Data Layers`。这是游戏的核心技术壁垒。

1.  **TileMapLayer 设置**：
    *   创建两个层级：
        *   `Layer 0 (Ground)`: 泥土、草地。
        *   `Layer 1 (Crops)`: 种下的庄稼。
    *   **核心技术点：自定义数据层 (Custom Data Layers)**
        *   在 TileSet 编辑器中，添加一个布尔值属性：`is_public_field` (是否为公田)。
        *   绘制地图时，将中间的格子该属性设为 `true`，周围设为 `false`。
2.  **光标高亮系统**：
    *   创建一个“选框”Sprite，在 `_process` 中跟随鼠标，并吸附到网格。
    *   **UI反馈**：当光标移到“公田”上时，选框变为**金色**（提示这是国君的地）；移到“私田”变为**绿色**。
3.  **耕地逻辑**：
    *   点击鼠标 -> 获取当前格子的 TileData -> 检查是否可耕种 -> 替换 Tile 为“耕地”贴图。

#### 第三周：作物生长与数据驱动 (Crops & Resources)
**重点**：使用 `Resource` 及其继承类来管理物品数据，这是 Godot 的强项。

1.  **数据驱动物品系统**：
    *   创建脚本 `CropData.gd` (继承自 `Resource`)。
    *   变量：`crop_name`, `days_to_grow`, `seed_texture`, `stages_textures` (数组).
    *   在编辑器里创建资源文件：`res://resources/crops/millet.tres` (黍)。
2.  **作物管理器 (CropManager)**：
    *   不要给每个作物实例化一个节点（几百个节点会卡）。
    *   **优化方案**：使用 `Dictionary` 存储作物数据。
        *   `var active_crops = {}`
        *   Key: `Vector2i` (坐标)
        *   Value: `{ "data": CropData资源, "current_day": 0, "state": "watered/dry" }`
3.  **每日更新逻辑**：
    *   编写 `advance_day()` 函数：遍历 `active_crops` 字典，如果是“watered”状态，`current_day += 1`。检查是否达到成熟天数，如果是，更新 TileMapLayer 上的贴图。

#### 第四周：核心闭环与UI (The Loop & UI)
**重点**：收获判定与简单的经济反馈。

1.  **收获机制 (Harvesting Logic)**：
    *   玩家对成熟作物点击 -> 触发 `harvest(coords)`。
    *   **关键代码逻辑 (GDScript)**：
        ```gdscript
        func harvest(coords: Vector2i):
            var tile_data = ground_layer.get_cell_tile_data(coords)
            var is_public = tile_data.get_custom_data("is_public_field")
            
            if is_public:
                Global.king_storage += 1
                UI.show_popup("上缴公田产出 +1", Color.GOLD)
            else:
                Global.player_inventory += 1
                UI.show_popup("获得黍 +1", Color.GREEN)
                
            # 清除作物数据和图块
            remove_crop(coords)
        ```
2.  **简易UI**：
    *   左上角显示：时间（第几天）。
    *   左下角显示：体力条。
    *   右上角显示：【国库贡献度】 vs 【个人铜币】。
3.  **时间流逝**：
    *   做一个简单的黑屏过场动画，模拟“睡觉”。睡觉时触发 `advance_day()`。

---

### 技术栈推荐 (Godot 4.6+ Specifics)

1.  **GDScript 2.0 强类型**：
    *   务必在 Phase 1 就严格使用静态类型，这对于后期重构至关重要。
    *   例如：`func harvest(coords: Vector2i) -> void:` 而不是 `func harvest(coords):`。
2.  **Signal Bus (信号总线) 模式**：
    *   创建一个单例 `GameEvents.gd`。
    *   当发生收获时，发出 `GameEvents.crop_harvested.emit(is_public)`。
    *   UI 节点监听这个信号来更新数字，实现逻辑与表现解耦。
3.  **TileMapLayer 导航**：
    *   虽然 Phase 1 没有 NPC，但建议现在就在 TileSet 里画好 Navigation Layer（导航网格），为 Phase 2 的门客 AI 寻路做准备。

### 第一阶段交付物 (Deliverables)

1.  **可运行的 .exe / .apk**：
    *   包含一个 9x9 的测试地图（包含几个“井”字结构）。
    *   玩家可以无限次地“睡觉 -> 种地 -> 收获”。
2.  **验证结论**：
    *   公田和私田的产出分离是否在代码层面无 bug？
    *   操作手感（格子的选中判定）是否流畅？

完成这一步，你的《采邑春秋》的地基就打牢了，接下来就可以在第二阶段填充“门客AI”和“六艺系统”。