完成了第一阶段（核心机制原型验证）后，你的游戏骨架已经搭建完毕：玩家能在格子上跑，能区分公田私田。

**第二阶段（Phase 2）的核心目标**是：**“门客入驻与经济闭环” (The Retainer & The Economy)**。

这一阶段要将游戏从“单人种田”转变为“管理者模式”，验证本作最大的卖点——**自动化管理**。如果不做这一步，这只是一个换皮的星露谷；做完这一步，它才是《采邑春秋》。

**建议周期**：4-6 周。

---

### 第二阶段开发计划表

#### 第一周：门客 AI 基础 (Basic Retainer AI)
**目标**：让一个 NPC 能够自动寻路并执行简单任务（如浇水）。

1.  **导航系统 (Navigation)**：
    *   **Godot 设置**：在 `TileMapLayer` 的 TileSet 中设置 **Navigation Layer**。确保耕地、平地是可行走的，障碍物（墙、水）是不可行走的。
    *   **节点**：给门客场景添加 `NavigationAgent2D`。
2.  **AI 状态机 (FSM)**：
    *   不要写复杂的行为树，先写一个简单的状态机脚本 `RetainerAI.gd`：
        *   `IDLE` (空闲)：等待指令或寻找工作。
        *   `MOVE` (移动)：利用 `NavigationAgent2D.target_position` 移动向目标。
        *   `WORK` (工作)：到达目标后，播放动画，执行逻辑（如作物 `state = watered`）。
        *   `REST` (休息)：晚上或体力耗尽时回房。
3.  **工作寻找逻辑**：
    *   使用 **Group** 系统。将所有干涸的耕地节点加入组 `dry_crops`。
    *   AI 逻辑：`if state == IDLE: target = get_tree().get_first_node_in_group("dry_crops")`。

#### 第二周：管理界面与指令系统 (Management UI)
**目标**：玩家不需要跑过去告诉 NPC 做什么，而是通过 UI 指派。

1.  **竹简管理 UI**：
    *   创建一个全屏 UI `ManagementPanel`。
    *   **左侧**：门客列表（头像、名字、职业图标）。
    *   **右侧**：当前封地地图的缩略图（使用 `SubViewport` 或简单的 Grid 映射）。
2.  **拖拽指派 (Drag & Drop)**：
    *   利用 Godot 的 `_get_drag_data` 和 `_drop_data` 函数。
    *   **玩法逻辑**：玩家将“墨家弟子”头像拖到“公田区域”，该 NPC 的 AI 状态就会锁定在公田区域工作。
3.  **门客属性数据**：
    *   扩展 `Resource`：创建 `RetainerData`。
    *   属性：`hunger` (饥饿度), `loyalty` (忠诚度), `efficiency` (工作效率)。

#### 第三周：经济循环与日结 (Economy Loop)
**目标**：种出来的东西有用处，门客需要吃饭。

1.  **仓库与消耗**：
    *   **公仓**：用于上缴任务。
    *   **私仓（粮仓）**：用于存放粮食。
    *   **每日结算逻辑**：
        *   天黑睡觉时，系统自动扣除 `私仓` 中的粮食 = `门客数量 * 1`。
        *   **反馈**：如果粮食不足 -> 门客忠诚度下降 -> 忠诚度过低 -> 门客消失（跑路）。
2.  **简单的订单系统 (The Market)**：
    *   不需要做一个复杂的商店行走。
    *   做一个“行商”界面：每隔几天有商人路过，可以用私田的产出换取“铜币”或“种子”。
3.  **失败判定**：
    *   引入第一个 Game Over 机制：如果连续 3 天无法缴纳公田产出（或被扣光声望），显示“褫夺封地”结局画面。

#### 第四周：视觉与氛围垂直切片 (Visual Vertical Slice)
**目标**：把方块变成真正的“春秋画风”。

1.  **美术资源替换**：
    *   画出（或找素材）第一版 TileSet：黄土路、青铜灯、篱笆。
    *   角色动画：简单的 4 方向行走和挥锄头。
    *   UI 皮肤：将默认的灰色按钮替换为竹简色/青铜色纹理（使用 `Theme` 资源全局替换）。
2.  **音效接入**：
    *   加入背景环境音（风声、鸟鸣）。
    *   加入 UI 交互音（竹简展开的清脆声，铜币的声音）。

---

### 关键技术难点与 Godot 解决方案

#### 1. 门客的性能优化 (AI Performance)
*   **问题**：如果后期有 20 个门客，每帧都做寻路计算会卡。
*   **Godot 4.6 方案**：
    *   不要在 `_physics_process` 里每帧调用 `get_next_path_position()`。
    *   使用 **Timer** 或 **计数器**，让 AI 每 0.1秒 或 0.2秒 更新一次路径。
    *   利用 `NavigationServer2D.map_get_path` 进行后台线程寻路（如果非常卡的话，初期不必）。

#### 2. 全局数据管理 (Singleton)
*   建立一个 `GameManager` 单例 (Autoload)。
*   它负责存储：`inventory` (背包), `retainers` (拥有的门客列表), `world_state` (公田私田状态)。
*   **一定要做 Save/Load 基础**：利用 Godot 的 `FileAccess` 将这些数据存为 JSON 或二进制，确保现在的架构支持存档。

#### 3. 拖拽系统的实现细节
*   在 `Control` 节点中：
    ```gdscript
    func _get_drag_data(at_position):
        var preview = TextureRect.new()
        preview.texture = npc_icon
        set_drag_preview(preview)
        return npc_data # 返回 NPC 的数据资源
    ```
*   在接受拖拽的目标（如地图区域槽位）中：
    ```gdscript
    func _can_drop_data(at_position, data):
        return data is RetainerData

    func _drop_data(at_position, data):
        assign_retainer_to_area(data)
    ```

---

### 第二阶段交付物 (Deliverables)

1.  **可玩 Demo**：
    *   开局拥有 1 名门客。
    *   玩家可以指派门客去种地，自己去钓鱼或发呆。
    *   晚上如果不给门客吃饭，第二天早上门客会发脾气或消失。
    *   画面不再是色块，而是具备了初步的“国风”美感。
2.  **核心验证**：
    *   验证了“甚至不需要玩家亲自动手”的玩法是否有趣？
    *   验证了“养活门客”的生存压力是否合适？

**下一步（第三阶段）预告**：
完成这些后，第三阶段将专注于 **“六艺成长”与“社交系统”**（如接待孔子、论道、升级爵位），以及扩展地图到**野外（攘夷战斗的前置）**。