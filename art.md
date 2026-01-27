# 美术资源需求清单与提示词 (Art Assets & Prompts)

本文档列出了 Phase 5 及后续开发所需的核心美术资源，并提供了适用于 AI 绘画工具（如 Midjourney, Stable Diffusion）的提示词参考。

## 1. 总体风格指南 (Style Guide)

*   **核心风格**：**青绿山水 (Blue-Green Landscape)** 结合 **像素艺术 (Pixel Art)**。
*   **参考画作**：《千里江山图》。
*   **主色调**：
    *   **石青 (Mineral Blue)** - 用于水、天、远山。
    *   **石绿 (Mineral Green)** - 用于草地、树木、山峦。
    *   **赭石 (Ocher)** - 用于土地、建筑、树干。
    *   **青铜色 (Bronze)** - 用于金属器皿、UI 边框。
*   **通用提示词后缀 (Common Suffix)**：
    > `pixel art, game assets, top-down view, Chinese traditional painting style, blue-green landscape style, Spring and Autumn period vibes, ancient china, mineral colors, flat shading, minimal details --no text, realistic, 3d`

---

## 2. 地形与环境 (TileSets)

### 2.1 耕地与土壤
*   **需求**：
    *   生土 (Untilled Soil)
    *   熟土 (Tilled Soil)
    *   湿润耕地 (Watered/Irrigated Soil) - 用于水田
*   **提示词 (Prompt)**：
    > **生土/熟土**: `top-down game tileset, soil ground texture, ancient chinese agriculture field, yellow and ocher earth tone, seamless pattern, pixel art, 32x32`
    > **水田**: `top-down game tileset, wet soil with water reflection, paddy field, mud and water mixture, ancient agriculture, pixel art, seamless`

### 2.2 水利系统 (Water System)
*   **需求**：
    *   水渠 (Canal) - 直线、转弯、T型、十字交叉。
    *   河流 (River) - 宽阔的自然水域。
*   **提示词 (Prompt)**：
    > **水渠**: `top-down game tileset, ancient irrigation canal, narrow water ditch dug in earth, straight and corner pieces, mineral blue water, pixel art`
    > **河流**: `top-down game tileset, wide river bank, flowing water style of traditional chinese painting, mineral blue and white waves, seamless, pixel art`

### 2.3 植被 (Vegetation)
*   **需求**：
    *   桑树 (Mulberry Tree) - 不同生长阶段。
    *   普通树木 - 风格化的松/柳。
*   **提示词 (Prompt)**：
    > **桑树**: `single mulberry tree sprite, top-down view for rpg game, ancient chinese tree, broad green leaves, pixel art, isolated on white background`
    > **风格化松树**: `traditional chinese painting style pine tree, top-down game asset, twisted trunk, mineral green needles, pixel art`

---

## 3. 角色与生物 (Characters & Creatures)

### 3.1 门客 (Retainers)
*   **需求**：需区分不同学派的服装颜色/特征。
    *   **儒家**：宽袍大袖，配冠，浅色/白色。
    *   **墨家**：短褐，草鞋，深色/黑灰色。
    *   **兵家**：皮甲，持戈，红色/褐色。
    *   **农家**：斗笠，锄头，绿色/土色。
*   **提示词 (Prompt)**：
    > **儒家**: `game character sprite, ancient chinese scholar, confucian robe, white and light blue clothing, wearing a hat, walking animation sheet, top-down rpg style, pixel art`
    > **墨家**: `game character sprite, ancient chinese mohist, simple dark grey ragged clothes, straw sandals, ascetic look, walking animation sheet, top-down rpg style, pixel art`
    > **兵家**: `game character sprite, ancient chinese soldier, leather armor, holding a bronze dagger-axe (ge), red and brown tones, walking animation sheet, top-down rpg style, pixel art`

### 3.2 敌人与异兽 (Enemies & Beasts)
*   **需求**：
    *   **蛮族斥候**：披发左衽，兽皮装束。
    *   **夔牛 (Boss)**：单足，如牛，苍色，无角。
*   **提示词 (Prompt)**：
    > **蛮族**: `game character sprite, ancient barbarian warrior, animal skin clothes, messy hair, holding a wooden bow, wild look, top-down rpg style, pixel art`
    > **夔牛**: `mythical beast kui-ox from classic of mountains and seas, one-legged ox, storm and thunder theme, ancient bronze texture skin, blue-grey color, top-down game boss sprite, pixel art`

---

## 4. 建筑与设施 (Buildings & Facilities)

*   **需求**：
    *   **蚕室**：通风良好的木质建筑，有置蚕架。
    *   **烽火台**：高耸的土石结构，顶部有柴薪。
    *   **编钟架**：大型青铜乐器架。
*   **提示词 (Prompt)**：
    > **蚕室**: `ancient chinese sericulture house, wooden building with ventilation windows, rural architecture, top-down game asset, pixel art`
    > **烽火台**: `ancient chinese beacon tower, stone and earth structure, tall watchtower, military building, top-down game asset, pixel art`
    > **编钟**: `ancient chinese bronze chime bells set on wooden rack, bianzhong, musical instrument, detailed bronze texture, top-down game prop, pixel art`

---

## 5. 物品与图标 (Items & Icons)

### 5.1 桑蚕产物
*   **需求**：桑叶、蚕茧、生丝、绸缎卷。
*   **提示词 (Prompt)**：
    > **蚕茧**: `icon of a white silkworm cocoon, game item, pixel art, 32x32, white background`
    > **丝绸**: `icon of a roll of colorful silk fabric, ancient chinese luxury item, smooth texture, game item, pixel art`

### 5.2 六艺道具
*   **需求**：竹简、古琴、青铜剑、算筹。
*   **提示词 (Prompt)**：
    > **竹简**: `icon of ancient chinese bamboo slips scroll, calligraphy, game item, pixel art`
    > **青铜剑**: `icon of ancient bronze sword, oxidation green and gold color, game item, pixel art`

---

## 6. UI 界面元素 (UI Elements)

*   **风格**：青铜器铭文、饕餮纹、竹简质感。
*   **需求**：
    *   **主面板背景**：展开的竹简或青铜器皿表面。
    *   **按钮**：玉佩形状、印章形状。
    *   **边框**：回纹、云雷纹。
*   **提示词 (Prompt)**：
    > **竹简面板**: `game ui panel background, texture of ancient bamboo slips connected by strings, horizontal scroll, wood color, pixel art style`
    > **青铜边框**: `game ui border frame, ancient chinese bronze pattern, taotie motif, oxidized green metal texture, pixel art`
    > **印章按钮**: `game ui button, chinese seal style, red ink paste texture, square shape, pixel art`
