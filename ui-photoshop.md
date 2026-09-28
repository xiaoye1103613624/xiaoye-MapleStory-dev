# 客户端 UI 绘制规范（Photoshop MCP）

> 本文件是 `xiaoye-MapleStory-dev` skill 的 **reference 文档**（按需加载）。
> 绘制 / 重绘 / 生成冒险岛客户端 UI 图时**必读**；目标是完整还原原生观感，或按用户确认的参考图样式出图。

相关：工具接入路径与配置见 [toolchain.md §7 Photoshop MCP](toolchain.md#7-photoshop-mcp)；入库走 orange-wz（禁止裸拷 `.img`）。

---

## 0. 何时使用

用户提到或任务涉及下列任一情形时，加载本规范并走 Photoshop MCP：

- 新增 / 修改客户端窗体、按钮、页签、图标底板、边框等 **UI 位图**
- 「按原生样式画」「重绘这张图」「生成背包/技能/键盘… UI」
- 需要把生成图写入 `UI*.img` / 相关 WZ 节点

---

## 1. Agent 交互剧本（出图闭环）

按序执行；跳步须在 `manifest.md` 说明原因。

| 步 | 动作 | 阻塞 / 默认 |
| --- | --- | --- |
| 1 | **样式裁决**（§2） | 有参考图 → 先问「跟图 or 原生」；未答 → **默认原生** |
| 2 | **路径 / 样板**（§3–4） | 解析客户端路径；优先读落盘 notes；有路径则导出/登记样板；无样板 → v083 基线 + manifest 标注 |
| 3 | **分辨率**（§5） | 默认 **1x**；2x 须用户明确并在 manifest 标 `scale` |
| 4 | **版本目录**（§10） | 首次 `v1`，改动递增 `vN`；禁止覆盖旧版 |
| 5 | **模板生成**（§7–8） | 用组件 prompt 骨架生成 **`normal`（及静态件）** |
| 6 | **状态派生**（§9） | 优先 PS 规则从 `normal` 派生 `pressed` / `mouseOver` / `disabled`；不像原生再单态 AI 重生成 |
| 7 | **preview 验收**（§12） | `photoshop_get_preview` + 对照清单逐项过；不合格迭代 |
| 8 | **导出 vN** | PNG → `docs/features/<功能>/ui/<组件>/vN/` + `manifest.md` |
| 9 | **（可选）入库**（§11） | orange-wz：load → 写节点 → `save_as` → 原子替换 |

话术（参考图）：

> 你给了参考图。本次按**参考图样式**出，还是按客户端**原生**样式？未回复前我按原生处理。

---

## 2. 样式裁决（门禁）

| 情形 | 行为 |
| --- | --- |
| 用户**未**指定 UI 样式 | **默认原生**（按 §4–6 复刻） |
| 用户给了参考图，要求重绘或生成 | **先问**：按参考图样式，还是按原生？ |
| 已询问但用户未明确回复 | **默认原生** |
| 用户明确「跟图 / 按我给的图」 | 按参考图风格，仍须出齐多状态（§9）并做版本目录（§10） |

禁止在未裁决时擅自混用「现代扁平 + 原生边框」等折中方案。

---

## 3. 客户端路径与会话记忆

出图前须能对照原生资源（或用户确认的参考图）。**解析顺序**（自上而下，命中即用）：

1. **本会话已确认**的客户端 / `Data` 路径  
2. **产物 notes**：`docs/features/<功能名>/notes/client-path.md`（或同目录等价笔记）  
3. **项目约定**：`docs/features/_native-samples/` 旁的路径说明、或 `CLAUDE.md` / `AGENTS.md` / README / `docs/` 中的客户端路径  
4. **其它功能**产物 notes / 历史清单中的路径  
5. 仍未知 → **向用户索取**（示例：`E:\...\BeiDou-ClientV17\Data`）  
6. 用户暂不给路径 → 使用 §6 **v083 通用原生经验**，并在 `manifest.md` 标注「未实测采样」

### 3.1 必须落盘（避免重复追问）

用户一旦给出客户端 / `Data` 路径：

1. 写入 **`docs/features/<功能名>/notes/client-path.md`**（本功能）；若项目尚无全局约定，可同时写入 `docs/features/_native-samples/README.md` 或项目 notes 中的「默认客户端路径」
2. 内容至少含：绝对路径、确认日期/会话、适用版本线索（如 v083）
3. **后续会话优先读上述文件**，禁止在已有落盘记录时再次空问「客户端在哪」

有路径时：用 **orange-wz** 查询 / 导出相关 UI 节点 PNG，或读取用户已导出截图；实测尺寸与色板写入样板旁或该次 `manifest.md`（可覆盖 §6 经验值）。

---

## 4. 原生样板库约定

### 4.1 目录

业务项目内（优先）：

```text
docs/features/_native-samples/
  README.md              # 客户端路径、版本、导出说明
  palette.md             # 或嵌入 README：主色/辅色/高光/阴影 RGB
  sizes.md               # 或嵌入 README：常见控件尺寸表
  manifest-template.md   # 可复制的 manifest 骨架（见 §10.1）
  inventory/             # 背包样板 PNG + 可选 notes
  equip/
  skill/
  keyconfig/
  map/                   # 小地图 / 世界地图
  quest/
  shop/
  dialog/                # NPC 对话
  menu/
  hotkey/                # 快捷栏
  statusbar/             # 状态栏 / HUD
```

skill 包本身不附带像素资源；Agent 在业务项目中维护上述目录。跨项目复用时，可把样板说明路径写进项目文档并交叉引用。

### 4.2 核心窗体清单（应对齐）

| 样板目录 | 功能 | 关注点 |
| --- | --- | --- |
| `inventory/` | 背包 / 消耗 / 其他 | 格子、页签、金币栏、关闭钮 |
| `equip/` | 装备 | 槽位框、角色纸娃娃区、背景纹理 |
| `skill/` | 技能 | 技能格、等级字、页签 |
| `keyconfig/` | 键盘设置 | 键位格、说明区 |
| `map/` | 小地图 / 世界地图 | 边框、缩放钮、标记点 |
| `quest/` | 任务 | 列表、详情羊皮纸区 |
| `shop/` | 商店 / 交易 | 列表行高、确认钮 |
| `dialog/` | NPC 对话 | 立绘位、选项钮、名字牌 |
| `menu/` | 系统菜单 / 设置 | 竖排按钮、分隔 |
| `hotkey/` | 快捷栏 | 槽位 |
| `statusbar/` | 状态栏 / HUD | HP/MP 条底板 |

绘制任一新 UI 前，至少打开**同类**样板对照；缺哪类就补采哪类。

### 4.3 首次有客户端路径时

1. 按上表用 orange-wz（或已有导出）拉取代表性 PNG → 写入对应 `_native-samples/<类>/`
2. 更新 `README.md`：路径、版本、导出日期、节点线索
3. 色板 / 尺寸表写入样板旁（`palette.md` / `sizes.md`）或 README 表格
4. 之后出图**优先对照样板**，再对照单次功能的实测采样

### 4.4 无样板时

回退 §6 v083 经验基线；在该次 `manifest.md` 明确标注：

- `样板：无（v083 经验基线）`
- `采样：未实测`（若亦无客户端路径）

---

## 5. 分辨率约定

| 规则 | 说明 |
| --- | --- |
| **默认** | **1x 原生像素**（与经典客户端 UI 位图一致） |
| **2x / 高分** | 仅当用户**明确**要求（如插件高分、Retina 资源）时使用 |
| **manifest** | 必须写 `scale: 1x` 或 `scale: 2x`（及目标逻辑尺寸） |
| **禁止** | 无说明混用 1x/2x；禁止把 2x 图当 1x 节点入库 |

---

## 6. v083 通用原生绘制语言（无实测时的默认）

以下为经典 v083 系 UI **经验基线**；有实测 / 样板时以实测为准。

### 6.1 整体气质

- **像素游戏 UI**：1x 像素对齐；硬边；轻微斜切立体边（亮边在上/左，暗边在下/右）
- **材质**：木框、米黄羊皮纸、深蓝/青蓝标题条；偶见金属饰角
- **信息密度**：偏紧凑，少留大块空白；对齐格子与页签

### 6.2 常见配色倾向（非死板色号，生成时贴近）

| 角色 | 倾向 |
| --- | --- |
| 窗体边框 | 暖棕 / 深棕木纹感 |
| 内容底 | 米黄 / 浅褐羊皮纸，可有细纹理 |
| 标题栏 | 偏蓝或青蓝，标题字浅色 |
| 按钮默认 | 同系木色或灰蓝，有立体感 |
| 按钮按下 | 整体压暗或高光/阴影对调 |
| 禁用 | 降饱和、变灰、对比降低 |
| 强调 / 确认 | 可略偏亮黄或青绿，仍保持像素边 |

### 6.3 禁止（反「一眼 AI」）

- 紫–靛大渐变、霓虹描边、玻璃拟态、大面积高斯柔光
- 过度圆角胶囊钮、Material / iOS 扁平无边框
- 矢量光滑插画风、照片级材质、过厚投影
- 随机噪点「油画滤镜」、文字糊成抗锯齿光晕（标题可用清晰描边，勿发虚）

### 6.4 排版

- 标题居中或左对齐跟原生同类窗
- 关闭钮一般在标题栏右上
- 页签在内容区顶部；选中页签与内容底衔接无缝
- 滚动条：上/中/下/滑块分件，勿做成现代细条

---

## 7. Prompt / 生成模板

生成前把下列骨架填入 `photoshop_generate_image`（或等价）prompt；**必嵌**：目标尺寸、像素硬边、原生配色、禁项、状态说明。

### 7.1 公共前缀（所有组件）

```text
MapleStory classic v083-style game UI bitmap, exactly {W}x{H} px, 1x native pixels,
sharp pixel-hard edges, no anti-aliased glow, wood/parchment/UI chrome matching
classic MapleStory client, colors: {border/bg/title RGB or “match sample”}.
FORBIDDEN: purple-indigo gradients, glassmorphism, soft gaussian glow, neon outlines,
pill capsules, Material/iOS flat, photo-real materials, thick drop shadows, painterly noise.
Opaque or transparent BG as needed for control. Output clean sprite, no mockup chrome.
```

### 7.2 窗体九宫格

```text
{公共前缀}
Nine-slice window frame for MapleStory UI: separate or labeled tiles
nw/n/ne/w/c/e/sw/s/se. Corners fixed size; edges/center tileable without seam or blur.
Title bar {H}px, border thickness ~{N}px, parchment content area. Style: {native|ref}.
State: static frame (no button states). Match sample: {path or “v083 baseline”}.
```

### 7.3 四态按钮

```text
{公共前缀}
MapleStory UI button sprite, size {W}x{H}. Generate ONLY the “normal” state first:
beveled wood/blue-gray, light top-left / dark bottom-right. Label area empty or {text}.
Do NOT generate mouseOver/pressed/disabled in this pass — those will be derived in PS.
```

派生说明写入迭代笔记即可；若必须单态 AI 重生成，另开 prompt 并写清与 `normal` 的差分（见 §9.2）。

### 7.4 页签

```text
{公共前缀}
MapleStory tab control, size {W}x{H}. Unselected tab first (or selected if specified).
Selected tab must flush-seam with content panel top; unselected slightly recessed/dimmer.
Pixel edges; match inventory/skill tab samples if available.
```

### 7.5 勾选 / 开关

```text
{公共前缀}
MapleStory checkbox (or toggle), size {W}x{H}. Unchecked box with native bevel first;
checked = same box + clear checkmark/dot matching classic client. Hard pixels, no gloss.
```

### 7.6 状态差分（写入 prompt 或派生步骤）

| 状态 | 相对 `normal` |
| --- | --- |
| `mouseOver` | 略提亮或描边微变，外形不变 |
| `pressed` | 压暗 **或** 高光/阴影对调（凹下），与 normal **明显可辨** |
| `disabled` | 降饱和、变灰、对比降低，轮廓仍清晰 |

---

## 8. 窗体九宫格与可拉伸件

大窗体 / 可缩放面板按客户端既有命名导出；无既有名时用：

```text
nw  n  ne
w   c  e
sw  s  se
```

- 角块固定尺寸；边与中心可平铺/拉伸且不断纹
- 生成后检查拉伸缝：禁止明显拉伸模糊或接缝色差

---

## 9. 控件多状态与状态派生流水线

**凡可点击的图**必须出齐状态，禁止只交一张「好看的默认图」。

| 类型 | 最少状态 | 命名建议（对齐常见 WZ） |
| --- | --- | --- |
| 按钮 | `normal` / `mouseOver` / `pressed`（或 `mouseDown`）/ `disabled` | `BtXxx/normal` 等 |
| 页签 | 未选 + `selected`（及悬停若原生有） | 与现有 Tab 节点一致 |
| 勾选 | 未选 + `checked`（及禁用若需要） | |
| 开关 / 箭头 | 同按钮四态 | |

### 9.1 优先派生（不要四态各自全生成）

```text
1. AI / 绘制 → 仅产出高质量 normal（及静态件、九宫格）
2. Photoshop 规则派生其它态：
   - pressed  ：压暗，或高光↔阴影对调（模拟按下）
   - mouseOver：小幅提亮 / Curves 微抬
   - disabled ：去饱和 + 降对比
3. photoshop_get_preview 对照原生/样板
4. 仅当某态「不像原生」→ 对该单态单独 AI 重生成（带 §7.6 差分）
5. 导出各态 PNG 到 vN
```

### 9.2 推荐 Photoshop MCP 步骤顺序

1. `photoshop_ping`（本会话首次）
2. 需要时 `photoshop_get_capabilities`
3. 有参考/样板：`photoshop_open_image` 打开对照
4. `photoshop_get_state`；多文档时钉 `document_id`
5. `photoshop_generate_image`（或绘制）→ **仅 normal / 静态**
6. `photoshop_get_preview` 验收 normal
7. 派生其它态：优先 recipe / 调整层（亮度对比、曲线、色相饱和度）；细修可用原子工具；**整组包在可撤销步骤内**
8. 每态 `photoshop_get_preview`；不合格 → 单态重生成或再调
9. 导出 → 整理到 `ui/<组件>/vN/`

禁止默认对四态各跑一遍完整 AI 生成（费时且难对齐外形）。

---

## 10. 版本目录与 manifest

业务项目内路径：

```text
docs/features/<功能名>/ui/<组件名>/v1/
docs/features/<功能名>/ui/<组件名>/v2/
...
```

规则：

- **首次**输出落在 **`v1`**；同组件每次改动 → 连续递增，不跳号、不覆盖旧版
- 每版至少含：各状态 / 九宫格 PNG + **`manifest.md`**
- 用户另指定产物根时，仍保持 `ui/<组件>/vN/` 相对结构

### 10.1 manifest 必填字段

```markdown
# UI manifest — <组件名> / vN

- 样式来源：原生 | 跟图
- scale：1x | 2x
- 目标尺寸：WxH（逻辑像素；2x 时注明资源像素）
- 状态列表：normal, mouseOver, pressed, disabled, …
- 样板：_native-samples/<类>/… | 无（v083 经验基线）
- 采样路径 / 客户端：… | 未实测
- 目标节点路径：UIWindow.img/.../BtXxx/（已知时 **必填**；未知写「待定」）
- 文件→节点映射：见下表
- 生成说明：normal 生成 + 派生 / 单态重生成记录
- 验收：§12 清单已过 / 未过项
```

**目标节点路径**：已知时必须写入，便于 §11 入库；未知则标「待定」并在功能 README 跟踪。

---

## 11. 入库半自动 recipe（orange-wz）

生成验收通过后，若需进入客户端资源：

### 11.1 文件名 / 状态 → WZ 节点映射

| 产物文件（约定） | 典型 WZ 节点 |
| --- | --- |
| `normal.png` | `.../BtXxx/normal` 或 `.../normal/0`（以现有树为准） |
| `mouseOver.png` | `.../mouseOver` |
| `pressed.png` 或 `mouseDown.png` | `.../pressed` 或 `.../mouseDown` |
| `disabled.png` | `.../disabled` |
| `nw.png` … `se.png` | 与现有九宫格子节点同名 |
| `vN/` 目录名 | **不是** WZ 节点名；仅版本归档。入库用 manifest 内「目标节点路径」 |

以客户端已有 UI 树为准；冲突时记入 manifest「映射差异」。

### 11.2 推荐步骤（交叉 [toolchain.md](toolchain.md) orange-wz）

```text
1. 确认目标 .img 与节点路径（manifest）
2. orange-wz：load 资源（勿在客户端占用时强写 live）
3. 按映射写入/替换画布节点（PNG → 节点）
4. save_as 到「非 loaded 根」的临时/旁路路径
5. 原子替换到客户端 Data（关客户端或按占用策略）
6. 抽样 verify 节点；结果写入功能 README / patches
```

- **禁止**对 live `.img` 裸拷覆盖  
- 占用冲突：同主 skill「插件同步与进程占用」  
- 细节与端口：见 toolchain orange-wz 节

---

## 12. 验收自动化清单（交付前必过）

Agent **必须**在交付前逐项执行；任一项不合格 → 迭代后再交。

### 12.1 对照 manifest

- [ ] `scale` 已标且未混用 1x/2x
- [ ] 目标尺寸与导出 PNG 一致（像素）
- [ ] 状态齐全（可点控件：normal / mouseOver / pressed / disabled 等）
- [ ] `目标节点路径` 已填或明确「待定」
- [ ] 样板 / 采样来源已写（含「无样板 + v083 基线」）

### 12.2 禁区关键词 / 观感自检

对照 preview 与（若有）样板并排：

- [ ] 无紫–靛大渐变、玻璃拟态、大柔光、霓虹、胶囊 Material 风
- [ ] 硬边像素感；按下态可辨；禁用态可辨
- [ ] 九宫格（若有）接缝无模糊色差
- [ ] 与原生/样板并排不「一眼 AI 海报」

### 12.3 流程与产物

- [ ] 样式裁决正确（默认原生 / 已问跟图）
- [ ] 客户端路径已解析或已标注未实测；用户给过的路径已落盘 notes
- [ ] 已写入 `docs/features/<功能名>/ui/<组件>/vN/` + `manifest.md`
- [ ] 需入库：已走 §11 orange-wz 并抽样验证

---

## 13. Photoshop MCP 工作流（接入摘要）

**接入路径与配置模板（必读）**：[toolchain.md §7](toolchain.md#7-photoshop-mcp)。

**推荐**：出图前先读本文件 **§1 剧本、§7 模板、§9 状态派生**，再调 MCP。

- Cursor 配置键名多为 `photoshop`；工具侧常为 **`user-photoshop`**
- 传输 **stdio**；**调用前先读** schema（`mcps/user-photoshop/tools/`）
- 会话首次：`photoshop_ping` → 改文档前 `photoshop_get_state` → 生成后 `photoshop_get_preview`
- 允许 AI 完整生成 **normal**；其它态优先派生（§9）
- 默认 MCP 导出目录仅作中转 → 必须整理进 `ui/.../vN/`
- 最终交付以版本目录 + `manifest.md` + §12 清单为准

---

## 延伸阅读

- [SKILL.md](SKILL.md) — 主规范门禁与闭环
- [toolchain.md](toolchain.md) — Photoshop / orange-wz 接入
- [checklist.md](checklist.md) — 交付检查清单
