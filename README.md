# xiaoye-MapleStory-dev

> 萧曳冒险岛（MapleStory）**全栈开发规范 Skill** —— 不绑定单一仓库，适用于任意 MapleStory 私服 / 工具链（OdinMS、HeavenMS、Cosmic、BeiDou、自定义端等）。

本仓库是一个 **Agent Skill（技能包）**：把冒险岛全栈开发中反复踩的坑与团队约定固化为规范，让 AI 在服务端、前端、客户端插件、资源、构建、文档与提交各环节都按统一门禁执行。

---

## 目录

- [这是什么](#这是什么)
- [核心规范速览](#核心规范速览)
- [文件结构](#文件结构)
- [快速开始](#快速开始)
- [集成方法（Agent 平台）](#集成方法agent-平台)
- [配套工具链](#配套工具链)
- [使用方式](#使用方式)
- [更新与卸载](#更新与卸载)
- [FAQ](#faq)
- [文档索引](#文档索引)

---

## 这是什么

一套覆盖冒险岛全栈开发的闭环规范，涉及范围：

| 层面 | 内容 |
| --- | --- |
| 服务端 | Java / Netty，或 Spring 管理端；OdinMS 系遗留代码兼容 |
| 管理后台 / 前端 | Vue / React + 既有组件库，文案国际化 |
| 客户端插件 | `ijl15.dll` 劫持插件、IDA 逆向校准 |
| 资源 | WZ / IMG / XML、密钥转换、跨版本同步 |
| 工程 | 编码分层、单测与构建、产物保留、功能文档、原子提交 |

它不是工具，而是一份**行为准则**：AI 加载后会按「先抉择 → 再计划 → 后实现 → 验证 → 归档 → 提交」的流程工作。

---

## 核心规范速览

- **先抉择、再计划、后实现**：收到需求先全面思考并列出决策点请用户抉择，再用 Plan 模式一次性给出完整计划，确认后才实现。
- **规范优先 + 最小改动**：贴合当前项目既有约定，禁止借新功能改动无关代码。
- **验证门禁**：完成后必须跑通相关单测，并完成该层打包 / 构建。
- **禁止想象修改**：插件 / 二进制 / 协议改动必须用 IDA MCP 校准，禁止臆造偏移与签名。
- **WZ / IMG / XML 走 MCP**：优先 orange-wz 等工具，禁止手改二进制猜字段。
- **资源同步意识**：多语言、多端、跨版本目录同步；道具资源保证完整性。
- **编码防乱码**：源码 / i18n 用 UTF-8，游戏封包与插件 narrow UI 多为 GBK。
- **闭环或显式预留**：逻辑 + 资源 + 配置 + i18n + 文档能齐则齐，否则写清预留与阻塞。
- **产物保留 + 最终实现文档**：可追溯、可回滚、可接续。
- **注释与分级日志**：关键节点打日志，调试期开 DEBUG，闭环后删除临时调试日志。
- **插件改完同步客户端**：占用冲突首遇询问，其后按用户选择执行。
- **同会话任务续作**：未完成任务主动防遗忘；用户叫停则标暂停不续作。
- **原子提交**：单一功能一次提交（仅在授权时）。

完整条款见 [SKILL.md](SKILL.md)。

---

## 文件结构

```text
xiaoye-MapleStory-dev/
├── SKILL.md                 # 主规范（含 frontmatter），AI 触发入口
├── checklist.md             # 交付检查清单
├── feature-doc-template.md  # 功能最终实现逻辑文档模板
├── toolchain.md             # 配套工具链集成指南（服务端/客户端/插件/MCP/MySQL 工具）
├── install.ps1              # 一键安装脚本（Windows / PowerShell）
└── install.sh               # 一键安装脚本（Linux / macOS / Git-Bash / WSL）
```

> ⚠️ 四个 Markdown **相互引用**（`SKILL.md` → `checklist.md` / `feature-doc-template.md` / `toolchain.md`）。
> 安装时请**整目录复制**，只复制 `SKILL.md` 会导致链接断链。

---

## 快速开始

### 方式一：一键安装脚本（推荐）

**Windows / PowerShell**

```powershell
# 安装到 CodeBuddy 用户级（默认）
.\install.ps1 -Target codebuddy -Scope user

# 安装到 Cursor 用户级
.\install.ps1 -Target cursor

# 安装到当前项目级
.\install.ps1 -Target codebuddy -Scope project -ProjectPath .

# 覆盖已存在文件时不再询问
.\install.ps1 -Force

# 演练：只打印将要执行的动作，不写入
.\install.ps1 -WhatIf

# 工具链自检（只检测与提示，不自动安装）
.\install.ps1 -Check
```

**Linux / macOS / Git-Bash / WSL**

```bash
./install.sh --target codebuddy --scope user
./install.sh --target cursor
./install.sh --target codebuddy --scope project --project .
./install.sh --force
./install.sh --dry-run
./install.sh --check
```

### 方式二：手动复制

将仓库内 **4 个 Markdown** 复制到目标 skill 目录下的 `xiaoye-MapleStory-dev/`。

以 CodeBuddy 用户级为例：

```bash
mkdir -p ~/.codebuddy/skills/xiaoye-MapleStory-dev
cp SKILL.md checklist.md feature-doc-template.md toolchain.md \
   ~/.codebuddy/skills/xiaoye-MapleStory-dev/
```

---

## 集成方法（Agent 平台）

### 目录对照

| 平台 | 用户级（全局，对本机所有项目生效） | 项目级（随仓库共享） |
| --- | --- | --- |
| **CodeBuddy** | `~/.codebuddy/skills/xiaoye-MapleStory-dev/` | `<工作区>/.codebuddy/skills/xiaoye-MapleStory-dev/` |
| **Cursor** | `~/.cursor/skills/xiaoye-MapleStory-dev/` | `<项目>/.cursor/skills/xiaoye-MapleStory-dev/` |
| **Claude Code** | `~/.claude/skills/xiaoye-MapleStory-dev/` | `<项目>/.claude/skills/xiaoye-MapleStory-dev/` |
| **通用（跨工具约定）** | `~/.agents/skills/xiaoye-MapleStory-dev/` | — |

> 每个 skill 是**一个独立目录**，目录内必须含 `SKILL.md`；目录名与 `SKILL.md` 的 `name` 保持一致（`xiaoye-MapleStory-dev`）。

### CodeBuddy

- **用户级 / 项目级**：按上表放置即可，无需注册命令。
- **IDE 图形化导入**：`设置（Settings）→ Skills 管理 → 「导入 Skill」`。
- **查看已加载**：输入 `/skills`，面板会列出所有 skill 及预估 token 数。
- **触发**：AI 按 `description` 自动判断调用；也可手动 `/xiaoye-MapleStory-dev`。
- **可见性控制**：在 `settings.json` 用 `skillOverrides` 调整（`on` / `name-only` / `user-invocable-only` / `off`）。

### Cursor

放到 `~/.cursor/skills/`（个人）或 `<项目>/.cursor/skills/`（项目）。
**不要**放进 `~/.cursor/skills-cursor/`（Cursor 内置保留目录）。

### Claude Code

放到 `~/.claude/skills/`（个人）或 `<项目>/.claude/skills/`（项目，可提交版本库共享）。
同名冲突优先级：**Enterprise > Personal > Project**。

### 通用 `.agents/skills`

`~/.agents/skills/` 是跨工具通用约定目录，多个 Agent（含 CodeBuddy）会识别其中的 skill。
若想让多个编辑器共用同一份 skill，优先装到这里。

---

## 配套工具链

本 skill 只提供**规范**；真正干活还需要一组源码与工具。完整获取 / 构建 / 启动 / MCP 接入说明见 **[toolchain.md](toolchain.md)**。

| 组件 | 用途 | 仓库 |
| --- | --- | --- |
| **服务端 BeiDou-Server** | GMS083 Java 服务端（登录 8484 / API 8686） | https://github.com/BeiDouMS/BeiDou-Server |
| **客户端** | v083 客户端（与服务端配套发布） | https://github.com/BeiDouMS/BeiDou-Server/releases |
| **插件 BeiDou-ijl15** | `ijl15.dll` 劫持插件（汉化 / 分辨率 / 上限突破） | https://github.com/BeiDouMS/BeiDou-ijl15 |
| **IDA MCP** | 让 AI 读 / 改 IDA Pro | https://github.com/mrexodia/ida-pro-mcp |
| **orange-wz** | WZ / IMG 资源编辑器 **+ MCP 服务** | https://github.com/gujichu/orange-wz |
| **NapMysqlTool** | 图形化 MySQL 启停 / 多实例管理 | https://github.com/SleepNap/NapMysqlTool |

**环境速记**：Java 21、MySQL 8、Node v20.15.0 + Yarn、Maven、Visual Studio 2019（SDK10 / v142）、IDA Pro 8.3+（推荐 9）、Python 3.11+ 与 uv。

> 不确定本机缺什么？运行 `.\install.ps1 -Check` 或 `./install.sh --check` 自检，并按 `toolchain.md` 补齐。

---

## 使用方式

- **自动触发**：在对话中提到冒险岛相关话题（开发功能、插件修改、WZ / IMG、道具、私服、开发计划等），即会被加载。
- **手动触发**：`/xiaoye-MapleStory-dev`。

---

## 更新与卸载

- **更新**：重新拉取本仓库，重跑安装脚本（幂等覆盖即可）。
- **卸载**：删除目标目录下的 `xiaoye-MapleStory-dev/` 文件夹。

---

## FAQ

**Q：只复制 `SKILL.md` 可以吗？**
A：不行。主文件引用了其余三个文档，必须整目录复制，否则链接失效。

**Q：CodeBuddy 与 Cursor 都装会冲突吗？**
A：不会，各平台目录相互独立。若希望统一维护，可只装到 `~/.agents/skills/`。

**Q：装了 skill 却提示缺工具 / 不会接 MCP？**
A：运行 `install.ps1 -Check`（或 `install.sh --check`）自检，再按 [toolchain.md](toolchain.md) 补齐服务端、插件、IDA MCP、orange-wz MCP、MySQL 工具。

**Q：skill 没被触发？**
A：确认目录名与 `SKILL.md` 的 `name` 一致；检查 `skillOverrides` 未被设为 `off`。

---

## 文档索引

| 文档 | 内容 |
| --- | --- |
| [SKILL.md](SKILL.md) | 开发规范主体：门禁、计划流程、闭环定义 |
| [toolchain.md](toolchain.md) | 配套工具链集成：服务端 / 客户端 / 插件 / IDA MCP / orange-wz MCP / MySQL 工具 |
| [checklist.md](checklist.md) | 交付前逐项检查清单 |
| [feature-doc-template.md](feature-doc-template.md) | 功能最终实现逻辑文档模板 |

---

## 许可证

本仓库规范文本可自由用于你的冒险岛项目。
引用的第三方项目各自遵循其许可证：BeiDou 系列为 **AGPL-3.0**，ida-pro-mcp 为 **MIT**，NapMysqlTool 为 **MIT**。
