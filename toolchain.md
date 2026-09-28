# 配套工具链与集成指南（BeiDou / MapleStory v083）

> 本文件是 `xiaoye-MapleStory-dev` skill 的 **reference 文档**（按需加载，不必常驻上下文）。
> 目标：把「冒险岛全栈开发」所需的源码、客户端、插件、MCP 工具与 MySQL 工具一次说明白，
> 避免「装了 skill 却没有工具」或「不知道 MCP 怎么接」。
>
> 文内路径统一用 `~`（用户主目录）与 `<...>` 占位；Windows 命令以 `E:\project` 为示例根目录，请按自己机器替换。

---

## 快速导航

| 我想做的事 | 去看 |
| --- | --- |
| 备齐运行环境 | [0. 环境依赖总表](#0-环境依赖总表) |
| 跑起服务端 | [2. 服务端 BeiDou-Server](#2-服务端-beidou-server) |
| 安装客户端 | [3. 客户端](#3-客户端) |
| 编译并部署插件 | [4. 插件 BeiDou-ijl15](#4-插件-beidou-ijl15) |
| 让 AI 能读 IDA | [5. IDA MCP（ida-pro-mcp）](#5-ida-mcpida-pro-mcp) |
| 让 AI 能改 WZ/IMG | [6. orange-wz（资源修改器 + MCP）](#6-orange-wz资源修改器--mcp) |
| 让 AI 能画客户端 UI | [7. Photoshop MCP](#7-photoshop-mcp) |
| 启停 MySQL | [8. NapMysqlTool](#8-napmysqltool) |
| 接入 MCP 客户端 | [9. MCP 客户端配置模板](#9-mcp-客户端配置模板) |
| 按顺序启动整套环境 | [10. 推荐启动顺序](#10-推荐启动顺序) |
| 一次性就绪检查 | [11. 工具链就绪检查清单](#11-工具链就绪检查清单) |
| 排障 | [12. 常见故障排查](#12-常见故障排查) |

---

## 0. 环境依赖总表

| 依赖 | 版本要求 | 服务于 |
| --- | --- | --- |
| JDK | **OpenJDK / Temurin 21** | 服务端（BeiDou-Server）、orange-wz |
| Maven | 3.8+ | 服务端、orange-wz 构建 |
| MySQL | **8.x**（低于 8 不支持） | 服务端数据库 |
| Yarn | 1.x | `gms-ui` 包管理 |
| Visual Studio | **2019** + Windows SDK 10 + 工具集 **v142** | 插件 BeiDou-ijl15 |
| IDA Pro | **8.3+（推荐 9）**，**IDA Free 不支持** | IDA MCP 逆向校准 |
| Adobe Photoshop | 本机已安装（示例：Photoshop 2024） | Photoshop MCP 出图 |
| Node.js | **v20.15.0 LTS**（`npx` 可用） | `gms-ui`；Cursor 侧 Photoshop MCP（`npx @alisaitteke/photoshop-mcp`） |
| Python | **3.11+** | ida-pro-mcp；部分环境的 photoshop-mcp-server |
| uv | 最新版 | ida-pro-mcp / idalib |
| Git | 任意 | 拉取源码 |

> 提示：服务端与 orange-wz 都要求 **Java 21**；若系统默认 Java 为 1.8，请单独安装 21 并在启动脚本里显式指定 `java.exe` 路径。  
> Node 在环境表中既服务 `gms-ui`，也服务 Cursor 的 Photoshop MCP（stdio + `npx`）；勿重复安装冲突版本。

---

## 1. 组件总览

| # | 组件 | 用途 | 仓库 | 关键端口 / 产物 |
| --- | --- | --- | --- | --- |
| 1 | 服务端 BeiDou-Server | GMS083 Java 服务端（基于 Cosmic→HeavenMS 汉化优化，AGPL-3.0） | https://github.com/BeiDouMS/BeiDou-Server | 登录 **8484** / API **8686** |
| 2 | 客户端 | v083 客户端（与服务端配套发布） | 同一 Releases 页（见下） | `BeiDou-ClientV17.7z` |
| 3 | 插件 BeiDou-ijl15 | `ijl15.dll` 劫持插件（汉化 / 分辨率 / 上限突破等） | https://github.com/BeiDouMS/BeiDou-ijl15 | `out/Release/ijl15.dll` |
| 4 | IDA MCP | 让 AI 读 / 改 IDA Pro 的 MCP 服务 | https://github.com/mrexodia/ida-pro-mcp | SSE **8744** / headless **8745**（本机 Cursor 配置也可能是 HTTP 其它端口） |
| 5 | orange-wz | WZ / IMG 资源编辑器 **+ MCP 服务** | https://github.com/gujichu/orange-wz | HTTP MCP **10012–10029** |
| 6 | Photoshop MCP | 让 AI 驱动 Adobe Photoshop 绘制 / 生成客户端 UI 图 | npm：`@alisaitteke/photoshop-mcp`（Cursor）；或本机 `photoshop-mcp-server`（CodeBuddy 等） | **stdio**（无固定端口）；Cursor 工具侧标识常为 `user-photoshop` |
| 7 | NapMysqlTool | 图形化 MySQL 启停 / 多实例管理 | https://github.com/SleepNap/NapMysqlTool | Windows GUI |

**客户端下载地址**：服务端 Releases 页 `https://github.com/BeiDouMS/BeiDou-Server/releases`
（该页同时发布服务端包与客户端包；客户端命名形如 `BeiDou-ClientV17.7z`）。

---

## 2. 服务端 BeiDou-Server

**定位**：GMS v083 的 Java 服务端，模块为 `gms-server`（服务端）+ `gms-ui`（Web 前端）。

### 2.1 获取

两种方式二选一：

- **直接下载打包版（推荐新手）**：到 [Releases](https://github.com/BeiDouMS/BeiDou-Server/releases) 下载，产物命名规律：

  | 平台 | 文件 |
  | --- | --- |
  | Windows x64 | `BeiDou-Server-<版本>-x64.7z` |
  | Windows ARM64 | `BeiDou-Server-<版本>-arm64.7z` |
  | Linux x64 | `BeiDou-Server-<版本>-x64.tar.gz` |
  | Linux ARM64 | `BeiDou-Server-<版本>-arm64.tar.gz` |

  > 由 1.10 起提供 arm64 版本。部分版本附国内网盘镜像，下载前请自行核验来源。

- **源码构建**：`git clone https://github.com/BeiDouMS/BeiDou-Server.git`，需 JDK 21 + Maven。

### 2.2 环境与依赖

- JDK **21**、Maven、MySQL **8.x**。
- Web 前端 `gms-ui` 需 Node **v20.15.0** + Yarn；`gms-ui` 图片资源来自 `https://maplestory.io` 接口（需联网）。

### 2.3 启动与端口

1. 先确保 **MySQL 已启动**（可用 [NapMysqlTool](#7-napmysqltool)）。
2. 启动服务端：首次启动会**自动建库并执行初始化 SQL**，只需保证数据库可达。
3. 关键端口：

   | 用途 | 端口 |
   | --- | --- |
   | 游戏登录 | **8484** |
   | 管理 API / Swagger | **8686**（`http://localhost:8686/swagger-ui/index.html`） |

4. Web 前端（如需）：进入 `gms-ui` 目录 `yarn install` → `yarn dev`。

### 2.4 与 skill 的集成方式

- 服务端源码目录即为「当前打开项目」，遵守仓库内的 `AGENTS.md` / `CLAUDE.md` / README。
- 配置：数据库连接等运行参数按仓库 `application.yml` / 数据库配置；玩法倍率优先走库表/热更配置。
- 多语言资源：脚本与 WZ 按语言读取不同目录（如 `wz-zh-CN`、`wz-en-US`、`script-zh-CN`、`script-en-US`），改动资源时注意同步相应语言目录。

### 2.5 校验点

- [ ] `java -version` 为 21
- [ ] MySQL 8 已启动且可连接
- [ ] 服务端进程监听 8484
- [ ] Swagger 页面可打开（8686）

---

## 3. 客户端

**定位**：与上表服务端配套的 v083 客户端，从服务端 Releases 下载。

### 3.1 获取与版本对应

- 下载地址：`https://github.com/BeiDouMS/BeiDou-Server/releases`
- 命名规律：`BeiDou-ClientV<序号>.7z`，序号序列为 **V11 → V12 → V13 → V14 → V15 → V16.1 → V17**。
- **并非每个服务端版本都配新客户端**（例如某版服务端直接复用上一版客户端），以下载页说明为准。
- 补丁包：
  - `1.10.1` 为**客户端补丁**：解压后替换到**客户端根目录**即可；
  - `1.8.1` 为补丁包：直接覆盖对应服务端与客户端版本。

### 3.2 使用

1. 解压客户端包到独立目录（如 `...\BeiDou-ClientV17`）。
2. 按需替换/加装插件（见 [第 4 节](#4-插件-beidou-ijl15)）。
3. 网络指向本地服务端（登录端口 **8484**）。

### 3.3 与 skill 的集成方式

- 客户端资源目录（`Data\*.img`、WZ 等）的修改**必须走 MCP**（见 [第 6 节](#6-orange-wz资源修改器--mcp)），禁止文件系统裸拷 `.img`。
- 插件产物（`ijl15.dll`）修改后须同步到客户端目录（见第 4 节）。

---

## 4. 插件 BeiDou-ijl15

**定位**：`ijl15.dll` 劫持 DLL（v83 客户端），提供汉化、自由分辨率、属性上限突破、BossHP 百分比、免密等能力；继承上游 v1 分支单独开发（AGPL-3.0）。

### 4.1 获取

```bash
git clone https://github.com/BeiDouMS/BeiDou-ijl15.git
```

### 4.2 环境与构建

| 项 | 要求 |
| --- | --- |
| IDE | Visual Studio **2019** |
| SDK | Windows SDK **10** |
| 平台工具集 | **v142** |
| 构建配置 | **Release x86**（必须） |

用 VS 打开解决方案（`ezorsia.sln`），选择 **Release / x86** 生成；产物在 `out/Release/ijl15.dll`。

### 4.3 部署到客户端（三步）

1. 把客户端**原有的** `ijl15.dll` 重命名为 `2ijl15.dll`（保留原文件）。
2. 把新编译出的 `ijl15.dll` 拷贝到客户端根目录。
3. 把插件项目根目录下的 **`config.ini`** 一并拷贝到客户端根目录（具体配置都在 `config.ini`）。

### 4.4 与 skill 的集成方式

- 修改插件前必须用 **IDA MCP** 定位函数 / xref / 结构 / 字符串（见第 5 节），禁止凭记忆编造偏移与签名。
- 中文老客户端 narrow 文本多为 **GBK**，禁止用 UTF-8 源字面量直出 UI。
- **构建完成后自动同步到客户端目录**；若客户端正在运行导致占用，按 skill 的「插件同步与进程占用」策略处理。

### 4.5 校验点

- [ ] 方案以 Release x86 生成成功
- [ ] 客户端根目录存在新 `ijl15.dll`、被改名的 `2ijl15.dll` 与 `config.ini`
- [ ] 客户端可正常进入登录界面

---

## 5. IDA MCP（ida-pro-mcp）

**定位**：把 IDA Pro 暴露为 MCP 服务，让 AI 执行反编译 / 交叉引用 / 改名 / 补丁等逆向操作。

### 5.1 前置条件

| 项 | 要求 |
| --- | --- |
| IDA Pro | **8.3+，推荐 9**；**IDA Free 不支持** |
| Python | **3.11+**（用 `idapyswitch` 切到最新） |
| 其它 | 全局激活 **idalib**，并安装 **uv** |

激活 idalib（示例）：

```bash
# Windows
uv run "C:\Program Files\IDA Professional 9.3\idalib\python\py-activate-idalib.py"
# macOS
uv run "/Applications/IDA Professional 9.3.app/Contents/MacOS/idalib/python/py-activate-idalib.py"
# Linux
uv run "/path/to/idapro-9.3/idalib/python/py-activate-idalib.py"
```

### 5.2 安装

```bash
pip install https://github.com/mrexodia/ida-pro-mcp/archive/refs/heads/main.zip
ida-pro-mcp --install
```

> 安装后需**完全重启 IDA 与 MCP 客户端**（部分客户端常驻托盘，需彻底退出）。GUI 插件方式已被官方标记为弃用趋势，推荐 idalib-mcp。

### 5.3 客户端接入（按客户端三选一）

- **Claude Code**：
  ```bash
  claude plugin marketplace add mrexodia/claude-marketplace
  claude plugin install ida-pro-mcp@mrexodia
  ```
- **Codex**：
  ```bash
  codex plugin marketplace add mrexodia/codex-marketplace
  codex plugin add ida-pro-mcp@mrexodia
  ```
- **通用 MCP 客户端（含 CodeBuddy / Cursor 等）**：执行
  ```bash
  ida-pro-mcp --config
  ```
  得到 JSON 配置后，手动粘贴到对应客户端的 MCP 配置中（见 [第 8 节](#8-mcp-客户端配置模板)）。

### 5.4 运行方式

```bash
# 带 UI 的 SSE 服务
uv run ida-pro-mcp --transport http://127.0.0.1:8744/sse

# 无头（headless）模式：需先激活 idalib
uv run idalib-mcp --host 127.0.0.1 --port 8745 path/to/executable
uv run idalib-mcp --host 127.0.0.1 --port 8745     # 先起服务，之后用 idb_open(...) 打开文件
uv run idalib-mcp --stdio                          # stdio 客户端
```

### 5.5 与 skill 的集成方式

- headless 模式下，**每次工具调用必须显式携带 `database` 参数**（值为 `idb_open` 返回的 session id，不接受文件路径）。
- **进制转换一律使用 `int_convert` 工具**，不要让模型自行换算。
- 结论必须以反汇编 / 反编译与脚本推导为据；混淆代码应先脱壳再分析。

### 5.6 校验点

- [ ] `ida-pro-mcp --config` 能输出配置
- [ ] MCP 客户端中能看到 IDA 工具
- [ ] 能成功打开一个 `.exe` / `.dll` 并反编译

---

## 6. orange-wz（资源修改器 + MCP）

**定位**：WZ / IMG 资源编辑器，附带 **HTTP MCP 服务**，用于 `load → copy/paste → save` 的安全资源改写。**禁止**用 `Copy-Item` / `robocopy` 裸拷 `.img`。

### 6.1 获取与构建

```bash
git clone https://github.com/gujichu/orange-wz.git
cd orange-wz
# 需要 Java 21 + Maven（仓库自带 mvnw）
./mvnw -DskipTests package        # Windows: mvnw.cmd -DskipTests package
```

构建产物为 `target/` 下的 `OrzRepacker.jar`（或加密版 `OrzRepacker-encrypted.jar`），构建过程会一并复制 JRE 到 `target/jre`。

### 6.2 启动 MCP

```bat
:: Windows（推荐，自动挑空闲端口并写状态）
ensure-mcp.bat
:: 或
powershell -File ensure-mcp.ps1
```

### 6.3 端点解析（重要）

端口**不固定**，从 **10012 起自动顺延（10012–10029）**。请按以下优先级解析实际端点：

1. `mcp-runtime/endpoint.json` — 首选（字段 `url` 或 `port`）
2. `mcp-runtime/active-port.txt` — 纯端口号
3. 都缺失时回退 `http://127.0.0.1:10012/mcp`

`ensure-mcp.ps1` 可自动同步 `~/.cursor/mcp.json` 中的 `orange-wz` 项。启动参数等价于：

```bat
java -Xmx8g -XX:+UseG1GC -Dorange.gui.enabled=false -Dorange.mcp.http.enabled=true ^
     -Dserver.port=<端口> -javaagent:<jar> -jar <jar>
```

（可用环境变量 `ORANGE_WZ_XMX` 调整堆大小，默认 8g。）

### 6.4 与 skill 的集成方式

- WZ / IMG / XML / 密钥操作优先走本 MCP；改前查询 / dry-run，批量优于逐节点。
- **live 改写安全流**：先关闭客户端 → 复制 live 到 staging → `load_files` → `mutate_nodes` → `save_as` 到**不同** output 路径 → `unload_all` → 原子替换回 live。
- **禁止** `save_as` 回写与 loaded 根相同的路径（会破坏 live）。
- 图标建议默认 **ARGB4444**；`config.ini` 不要带 UTF-8 BOM。
- 只改 `Item` 不改 `String` / `Character` 会出现「无名称 / 无外观 / 穿不上」，须做双端同步。

### 6.5 校验点

- [ ] Maven 构建成功，`target/*.jar` 存在
- [ ] `ensure-mcp` 返回 `OK`
- [ ] `mcp-runtime/endpoint.json` 指向可用端口
- [ ] MCP 客户端可列出 orange-wz 工具

---

## 7. Photoshop MCP

**定位**：通过 MCP 驱动本机 **Adobe Photoshop**，供 AI 打开参考图、生成/绘制客户端 UI 位图、预览与导出。绘制规范见 [ui-photoshop.md](ui-photoshop.md)。

> 下文路径与配置片段来自本机实测（可按自己机器改 `PHOTOSHOP_PATH` / 可执行文件路径）。不同 Agent 客户端可能用**不同** Photoshop MCP 包，以各自 `mcp.json` 为准。

### 7.1 前置条件

| 项 | 要求 |
| --- | --- |
| Adobe Photoshop | 本机已安装并可手动启动（示例路径见下） |
| Node.js + `npx` | Cursor 使用 `@alisaitteke/photoshop-mcp` 时需要 |
| 或 Python 侧 MCP server | CodeBuddy 等可能直接跑 `photoshop-mcp-server.exe` |
| Agent MCP 开关 | 对应客户端已启用该 MCP，且工具列表可见 |

示例本机 Photoshop 可执行文件（Cursor `PHOTOSHOP_PATH`）：

```text
D:\software\Photoshop 25.12.4\Adobe Photoshop 2024\Photoshop.exe
```

出图前建议先**手动打开 Photoshop**（或确认 MCP 能拉起进程），再在对话里 `photoshop_ping`。

### 7.2 路径与命名对照（本机）

| 用途 | 路径 / 名称 |
| --- | --- |
| Cursor MCP 配置 | `%USERPROFILE%\.cursor\mcp.json`（即 `~/.cursor/mcp.json`） |
| CodeBuddy MCP 配置 | `%USERPROFILE%\.codebuddy\mcp.json` |
| Cursor 配置内 server 键名 | `photoshop` |
| Cursor 运行时 / 工具侧标识 | `user-photoshop`（见项目 MCP 描述符 `SERVER_METADATA.json` 的 `serverIdentifier`） |
| Cursor 工具描述符目录（本仓库工作区示例） | `%USERPROFILE%\.cursor\projects\e-project-xiaoye-MapleStory-dev\mcps\user-photoshop\` |
| 描述符内元数据 | 同目录 `SERVER_METADATA.json`（`serverName`: `photoshop`） |
| 服务说明 | 同目录 `INSTRUCTIONS.md` |
| 单工具 schema | 同目录 `tools\photoshop_*.json`（**调用前必读**） |

> 换工作区时，Cursor 的 `projects\<slug>\mcps\` 目录名会变；以当前打开项目对应的 `mcps\user-photoshop\` 为准。

### 7.3 接入方式（stdio）

Photoshop MCP 在本机为 **stdio**（`command` + `args`），**不是** HTTP 固定端口（与 orange-wz / 部分 IDA 配置不同）。

#### Cursor（本机实测）

文件：`~/.cursor/mcp.json`，`mcpServers.photoshop` 片段：

```json
{
  "mcpServers": {
    "photoshop": {
      "command": "npx",
      "args": ["-y", "@alisaitteke/photoshop-mcp"],
      "env": {
        "LOG_LEVEL": "1",
        "PHOTOSHOP_PATH": "D:\\software\\Photoshop 25.12.4\\Adobe Photoshop 2024\\Photoshop.exe"
      }
    }
  }
}
```

说明：

- 包名：`@alisaitteke/photoshop-mcp`（经 `npx -y` 拉取/执行）
- 必须把 `PHOTOSHOP_PATH` 改成你机器上真实的 `Photoshop.exe`
- 与同文件中的 `orange-wz`、`ida-pro-mcp` 并列即可（本机 Cursor 的 IDA 为 HTTP `http://127.0.0.1:13337/mcp`）

#### CodeBuddy（本机实测，另一套实现）

文件：`~/.codebuddy/mcp.json`：

```json
{
  "mcpServers": {
    "photoshop": {
      "command": "C:\\Users\\11036\\AppData\\Local\\Programs\\Python\\Python314\\Scripts\\photoshop-mcp-server.exe",
      "args": [],
      "env": {}
    }
  }
}
```

说明：走本机 Python Scripts 下的 `photoshop-mcp-server.exe`，路径随 Python 安装位置变化；接入前请确认该 exe 存在。

#### 通用注意

- 改完 `mcp.json` 后通常需**重载 MCP / 重启 Agent 客户端**，工具列表才会出现 `photoshop_*`
- 勿把 Cursor 的 `npx` 配置与 CodeBuddy 的 exe 配置混当成同一进程；两边可同时存在，但各自独立

### 7.4 会话用法（与 UI 规范配合）

绘制规范全文：[ui-photoshop.md](ui-photoshop.md)。**推荐：先读 ui-photoshop 的交互剧本（§1）、prompt 模板（§7）与状态派生（§9）**，再调 MCP。

工具链侧最短流程：

```text
1. 确认 Photoshop 已安装且（建议）已启动
2. 确认 MCP 已加载（Cursor 工具侧常见标识 user-photoshop）
3. 会话首次：photoshop_ping
4. 调用具体工具前：读取 mcps/user-photoshop/tools/<工具名>.json schema
5. 样式裁决 → 路径/样板 → 按模板生成 normal → PS 派生其它态
6. 需要时：photoshop_get_capabilities / photoshop_open_image / photoshop_generate_image …
7. 有意义改动后：photoshop_get_preview 自检（对照 ui-photoshop §12）
8. 导出整理到 docs/features/<功能名>/ui/<组件>/vN/ + manifest.md
9. 需入库 → orange-wz（第 6 节）：load → 写节点 → save_as → 原子替换，禁止裸拷 .img
```

### 7.5 与 skill 的集成方式

- 主规范门禁：见 [SKILL.md](SKILL.md)「客户端 UI 图走 Photoshop」
- 样式默认原生、参考图先问、样板库、版本目录 `v1→v2→v3…`、normal→派生多状态、验收清单：见 [ui-photoshop.md](ui-photoshop.md)
- 允许 AI 完整生成 **normal**，其它态优先规则派生；必须预览自检，避免「一眼 AI」观感

### 7.6 校验点

- [ ] Adobe Photoshop 可手动启动；`PHOTOSHOP_PATH`（若使用）指向真实 `Photoshop.exe`
- [ ] `~/.cursor/mcp.json`（或 CodeBuddy 对应文件）中存在 `photoshop` 项且配置正确
- [ ] Agent 中能看到 Photoshop 相关工具（Cursor 描述符目录存在 `mcps/user-photoshop/tools/`）
- [ ] `photoshop_ping` 成功
- [ ] 能 `photoshop_get_preview` 或打开一张图做冒烟

---

## 8. NapMysqlTool

**定位**：Windows 图形化 MySQL **启停 / 多实例管理**工具（含导入导出、异常关机「修复」功能，MIT）。

### 8.1 获取

到 [Releases](https://github.com/SleepNap/NapMysqlTool/releases) 下载**完整包**（默认分支 3.x）。

### 8.2 运行前提（缺一不可）

必须保留下述完整结构，**只下载 `NapMysqlTool.exe` 会启动失败**：

| 文件 / 目录 | 说明 |
| --- | --- |
| `NapMysqlTool.exe` | 主程序 |
| `jre/` | Java 运行环境 |
| `mysql-5.7.44-winx64/` | MySQL 5.7 |
| `mysql-8.0.39-winx64/` | MySQL 8.0 |
| `mysql-lib/` | MySQL 依赖库（含 VC++ 运行库） |

双击 `NapMysqlTool.exe` 即可，UI 中按实例启动 / 停止。

### 8.3 注意事项

- 若机器上已有 MySQL 注册为开机自启服务并占用 **3306**，需先关闭该服务自启。
- 异常关机导致 MySQL 起不来时，用「扩展功能 → 修复」。

### 8.4 校验点

- [ ] 完整包齐全（五个部分都在同一目录）
- [ ] 3306 无冲突
- [ ] UI 可启动 MySQL，服务端能连上（服务端要求 **MySQL 8**）

---

## 9. MCP 客户端配置模板

以下为通用 `mcpServers` 片段，按客户端写入对应配置文件。可与第 5–7 节各工具配置合并为同一文件。

### 9.1 CodeBuddy

文件：`~/.codebuddy/mcp.json`

```json
{
  "mcpServers": {
    "orange-wz": {
      "type": "http",
      "url": "http://127.0.0.1:10012/mcp"
    },
    "photoshop": {
      "command": "C:\\Users\\<你>\\AppData\\Local\\Programs\\Python\\Python314\\Scripts\\photoshop-mcp-server.exe",
      "args": [],
      "env": {}
    }
  }
}
```

> `photoshop` 的 `command` 以本机实际 exe 为准（见 [7.3](#73-接入方式stdio)）。

### 9.2 Cursor

文件：`~/.cursor/mcp.json`

本机完整结构示例（含 orange-wz / IDA / Photoshop；端口与路径请按本机改）：

```json
{
  "mcpServers": {
    "orange-wz": {
      "type": "http",
      "url": "http://127.0.0.1:10012/mcp"
    },
    "ida-pro-mcp": {
      "type": "http",
      "url": "http://127.0.0.1:13337/mcp"
    },
    "photoshop": {
      "command": "npx",
      "args": ["-y", "@alisaitteke/photoshop-mcp"],
      "env": {
        "LOG_LEVEL": "1",
        "PHOTOSHOP_PATH": "D:\\software\\Photoshop 25.12.4\\Adobe Photoshop 2024\\Photoshop.exe"
      }
    }
  }
}
```

### 9.3 Claude Code

```bash
claude mcp add --transport http orange-wz http://127.0.0.1:10012/mcp
```

Photoshop 若用 stdio，按 Claude Code 文档用 `command`/`args` 方式添加，勿硬套 HTTP。

### 9.4 IDA MCP 配置

通用客户端执行 `ida-pro-mcp --config` 生成，再把输出片段并入上面的 `mcpServers`。本机 Cursor 也可能已是 HTTP 形式（如 `http://127.0.0.1:13337/mcp`）。

> ⚠️ orange-wz 的 `url` 端口请以 `mcp-runtime/endpoint.json` 为准，上例 10012 仅为默认回退值。Photoshop 为 stdio，无 url 端口。

---

## 10. 推荐启动顺序

```text
1. 启动 MySQL（NapMysqlTool 或系统服务），确认 3306 可用、MySQL 8
2. 启动服务端 BeiDou-Server，确认监听 8484 / 8686
3. 启动 orange-wz MCP（ensure-mcp），确认 endpoint.json 端口可用
4. 启动 IDA（如需逆向），确认 ida-pro-mcp 已装载到 MCP 客户端
5. 需画客户端 UI 时：启动 Adobe Photoshop，确认 photoshop MCP 已加载（Cursor：user-photoshop）
6. 启动游戏客户端，指向本地服务端
7. 在 AI 客户端中确认 MCP 工具列表齐全（含 photoshop_*）
```

---

## 11. 工具链就绪检查清单

- [ ] JDK 21 可用（服务端 / orange-wz）
- [ ] Maven 可用
- [ ] MySQL 8 已启动（NapMysqlTool 完整包可用）
- [ ] Node v20.15.0 + Yarn（如需 `gms-ui`）；Cursor Photoshop MCP 时 `npx` 可用
- [ ] Visual Studio 2019 + SDK10 + v142（如需编译插件）
- [ ] IDA Pro 8.3+/9 + Python 3.11+ + uv + idalib 已激活（如需逆向）
- [ ] `ida-pro-mcp` 已接入，且 MCP 客户端已装载
- [ ] orange-wz 已构建，`ensure-mcp` 返回 OK，端点已写入 MCP 客户端配置
- [ ] Adobe Photoshop 可启动；`~/.cursor/mcp.json`（或 CodeBuddy）中 `photoshop` 配置正确；`photoshop_ping` 可用
- [ ] 服务端 8484 / API 8686 可达
- [ ] 客户端可启动并连接本地服务端

---

## 12. 常见故障排查

| 现象 | 可能原因 | 处理 |
| --- | --- | --- |
| 服务端起不来 | 系统 Java 非 21 | 安装 JDK 21 并在启动脚本指定 `java.exe` |
| 服务端连不上库 | MySQL 未启动 / 非 8.x | 用 NapMysqlTool 启动 MySQL 8，确认 3306 |
| `gms-ui` 依赖装不上 | Node 版本不对 | 使用 Node v20.15.0 LTS |
| 插件客户端崩溃 | 用了 v2 分支 / 非 Release x86 | 用继承 v1 的分支，Release x86 构建 |
| 插件未生效 | `config.ini` 未拷入客户端 | 补齐 `ijl15.dll` + `config.ini`，原 dll 改名 `2ijl15.dll` |
| IDA 工具看不到 | 未重启 / 未接 MCP | 彻底重启 IDA 与客户端；用 `--config` 核对配置 |
| headless 调用报错 | 未带 `database` | 每次调用显式传 session id |
| MCP 客户端连不上 orange-wz | 端口变了 | 读 `endpoint.json` / `active-port.txt` 更新 url |
| `.img` 改写后客户端报错 | 裸拷 / 回写 loaded 根 | 改走 MCP `load → copy/paste → save_as → 替换` |
| 道具无名称 / 穿不上 | 只改 Item 未同步 String/Character | 用 `analyze_resource_links` 做双端同步 |
| NapMysqlTool 启动失败 | 缺 jre / mysql 目录 | 下载完整包，五个部分齐全 |
| Photoshop 工具列表看不到 | `mcp.json` 未配 / 未重载 MCP | 检查 `~/.cursor/mcp.json` 的 `photoshop`；重载或重启 Cursor；确认 `mcps/user-photoshop/` 描述符存在 |
| `photoshop_ping` 失败 / 连不上 PS | Photoshop 未开或路径错 | 手动启动 PS；核对 `PHOTOSHOP_PATH` 指向真实 `Photoshop.exe` |
| `npx` 拉包失败 | 无 Node / 网络受限 | 安装 Node LTS；必要时配置 npm 镜像后再试 |
| CodeBuddy 与 Cursor 行为不一致 | 两边 MCP 实现不同 | 分别读各自 `mcp.json`，勿混用 command 路径 |
| 生成图不像原生 | 未遵 UI 规范 | 按 [ui-photoshop.md](ui-photoshop.md) 用模板约束 prompt、先 normal 再派生、对照样板与 §12 验收 |

---

## 延伸阅读

- [SKILL.md](SKILL.md) — 开发规范主体（门禁 / 计划 / 闭环）
- [checklist.md](checklist.md) — 交付检查清单
- [feature-doc-template.md](feature-doc-template.md) — 功能实现逻辑文档模板
- [ui-photoshop.md](ui-photoshop.md) — 客户端 UI 绘制规范（交互剧本 / 样板 / 模板 / 状态派生 / 验收入库）
