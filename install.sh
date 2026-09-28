#!/usr/bin/env sh
# install.sh — 安装 xiaoye-MapleStory-dev skill 到各 Agent 平台的 skills 目录
#
# 兼容 POSIX sh（bash / dash / Git-Bash / WSL / macOS）。
# 目标目录对照：
#   平台        用户级 (user)                项目级 (project)
#   codebuddy   ~/.codebuddy/skills/...      <项目>/.codebuddy/skills/...
#   cursor      ~/.cursor/skills/...         <项目>/.cursor/skills/...
#   claude      ~/.claude/skills/...         <项目>/.claude/skills/...
#   agents      ~/.agents/skills/...         不支持（仅用户级）

set -eu

SKILL_NAME="xiaoye-MapleStory-dev"
SKILL_FILES="SKILL.md checklist.md feature-doc-template.md toolchain.md ui-photoshop.md"

TARGET="codebuddy"
SCOPE="user"
PROJECT=""
FORCE=0
DRY_RUN=0
DO_CHECK=0

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# ---- 颜色 ----
if [ -t 1 ]; then
  C_INFO='\033[36m'; C_OK='\033[32m'; C_WARN='\033[33m'; C_ERR='\033[31m'; C_RST='\033[0m'
else
  C_INFO=''; C_OK=''; C_WARN=''; C_ERR=''; C_RST=''
fi

info() { printf '%b[info]%b %s\n' "$C_INFO" "$C_RST" "$1"; }
ok()   { printf '%b[ ok ]%b %s\n' "$C_OK"   "$C_RST" "$1"; }
warn() { printf '%b[warn]%b %s\n' "$C_WARN" "$C_RST" "$1"; }
err()  { printf '%b[fail]%b %s\n' "$C_ERR"  "$C_RST" "$1"; }
die()  { err "$1"; exit 2; }

usage() {
  cat <<'EOF'
用法: ./install.sh [选项]

选项:
  --target <codebuddy|cursor|claude|agents>   目标平台（默认 codebuddy）
  --scope  <user|project>                     作用域（默认 user）
  --project <path>                            Scope=project 时的项目根目录（默认当前目录）
  --force                                     覆盖已存在文件，不再询问
  --dry-run                                   演练：只打印将执行的动作，不写入
  --check                                     工具链自检（只检测，不自动安装）
  -h, --help                                  显示本帮助

示例:
  ./install.sh --target codebuddy --scope user
  ./install.sh --target codebuddy --scope project --project .
  ./install.sh --target cursor
  ./install.sh --check
EOF
}

# ---- 参数解析 ----
while [ $# -gt 0 ]; do
  case "$1" in
    --target)    [ $# -ge 2 ] || die "--target 缺少取值"; TARGET="$2"; shift 2 ;;
    --target=*)  TARGET="${1#*=}"; shift ;;
    --scope)     [ $# -ge 2 ] || die "--scope 缺少取值"; SCOPE="$2"; shift 2 ;;
    --scope=*)   SCOPE="${1#*=}"; shift ;;
    --project)   [ $# -ge 2 ] || die "--project 缺少取值"; PROJECT="$2"; shift 2 ;;
    --project=*) PROJECT="${1#*=}"; shift ;;
    --force)     FORCE=1; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --check)     DO_CHECK=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           err "未知参数: $1"; echo; usage; exit 2 ;;
  esac
done

case "$TARGET" in
  codebuddy|cursor|claude|agents) ;;
  *) die "未知 --target: $TARGET（可选: codebuddy|cursor|claude|agents）" ;;
esac
case "$SCOPE" in
  user|project) ;;
  *) die "未知 --scope: $SCOPE（可选: user|project）" ;;
esac

# ---- 工具链自检 ----
check_cmd() {
  _name="$1"; _desc="$2"; shift 2
  if command -v "$_name" >/dev/null 2>&1; then
    _ver=$("$_name" "$@" 2>&1 | head -n 1 || true)
    [ -n "$_ver" ] || _ver="已安装"
    ok "$(printf '%-12s %s' "$_name" "$_ver")"
  else
    err "$(printf '%-12s 缺失 — %s' "$_name" "$_desc")"
  fi
}

do_check() {
  info "工具链自检（仅检测，不自动安装；缺失项请按 toolchain.md 补齐）"
  echo
  check_cmd git         "版本控制"            --version
  check_cmd java        "JDK 21（服务端/orange-wz）" -version
  if command -v java >/dev/null 2>&1; then
    _jv=$(java -version 2>&1 | head -n 1 || true)
    case "$_jv" in
      *\"21*|*\"2[2-9]*|*\"3[0-9]*) ;;
      *) warn "java 主版本可能不是 21（$_jv）；服务端 / orange-wz 需 JDK 21" ;;
    esac
  fi
  check_cmd mvn         "Maven"               -v
  check_cmd node        "Node v20.15.0 LTS"   -v
  check_cmd yarn        "Yarn"                -v
  check_cmd mysql       "MySQL 8"             --version
  check_cmd uv          "uv（IDA MCP）"       --version
  check_cmd ida-pro-mcp "IDA MCP 服务"        --help
  echo
  warn "以下为重环境，需手动确认（自检不覆盖）："
  echo "  · Visual Studio 2019 + Windows SDK 10 + v142（编译插件 BeiDou-ijl15）"
  echo "  · IDA Pro 8.3+（推荐 9）并已激活 idalib"
  echo "  · MySQL 8 已启动（登录 8484 / API 8686 需服务端与库就绪）"
  echo "  · orange-wz MCP 是否已启动（端口见 mcp-runtime/endpoint.json）"
  echo "  · Adobe Photoshop + ~/.cursor/mcp.json 中 photoshop 项（见 toolchain.md §7）"
  echo
  info "完整获取 / 构建 / 启动 / MCP 接入步骤见 toolchain.md"
}

if [ "$DO_CHECK" -eq 1 ]; then
  do_check
  exit 0
fi

# ---- 计算目标目录 ----
case "$TARGET" in
  codebuddy) SUB=".codebuddy" ;;
  cursor)    SUB=".cursor" ;;
  claude)    SUB=".claude" ;;
  agents)    SUB=".agents" ;;
esac

if [ "$SCOPE" = "user" ]; then
  [ -n "${HOME:-}" ] || die "无法解析用户主目录（HOME 为空）"
  BASE="$HOME/$SUB/skills"
else
  [ "$TARGET" = "agents" ] && die "通用 .agents/skills 仅支持用户级（请使用 --scope user）"
  [ -n "$PROJECT" ] || PROJECT="$(pwd)"
  [ -d "$PROJECT" ] || die "项目目录不存在: $PROJECT"
  PROJECT=$(cd "$PROJECT" && pwd)
  BASE="$PROJECT/$SUB/skills"
fi
DEST="$BASE/$SKILL_NAME"

info "源目录 : $SCRIPT_DIR"
info "目标   : $DEST"
info "平台   : $TARGET  作用域: $SCOPE"

# ---- 校验源文件 ----
MISSING=""
for f in $SKILL_FILES; do
  [ -f "$SCRIPT_DIR/$f" ] || MISSING="$MISSING $f"
done
if [ -n "$MISSING" ]; then
  err "源目录缺少文件:$MISSING"
  err "请在仓库根目录运行本脚本（或确认脚本与 SKILL.md 位于同一目录）"
  exit 3
fi

# ---- 目标已存在文件 ----
EXISTING=""
CNT=0
for f in $SKILL_FILES; do
  if [ -f "$DEST/$f" ]; then
    EXISTING="$EXISTING $f"
    CNT=$((CNT + 1))
  fi
done

# ---- 演练 ----
if [ "$DRY_RUN" -eq 1 ]; then
  warn "演练模式（--dry-run）：以下动作不会真正执行"
  echo "  将创建目录 : $DEST"
  for f in $SKILL_FILES; do echo "  将复制     : $f"; done
  [ "$CNT" -gt 0 ] && echo "  将覆盖     :$EXISTING"
  exit 0
fi

# ---- 覆盖确认 ----
if [ "$CNT" -gt 0 ] && [ "$FORCE" -eq 0 ]; then
  printf '目标已存在 %s 个同名文件，是否覆盖? [y/N] ' "$CNT"
  read -r ANSWER || ANSWER=""
  case "$ANSWER" in
    y|Y|yes|YES) ;;
    *) warn "已取消（未做任何修改）"; exit 0 ;;
  esac
fi

# ---- 复制 ----
mkdir -p "$DEST"
for f in $SKILL_FILES; do
  cp "$SCRIPT_DIR/$f" "$DEST/$f"
done

# ---- 校验 ----
ALL_OK=1
for f in $SKILL_FILES; do
  if [ ! -f "$DEST/$f" ]; then
    err "复制失败: $f"
    ALL_OK=0
    continue
  fi
  S1=$(wc -c < "$SCRIPT_DIR/$f" | tr -d ' ')
  S2=$(wc -c < "$DEST/$f" | tr -d ' ')
  if [ "$S1" != "$S2" ]; then
    err "大小不一致: $f ($S1 -> $S2)"
    ALL_OK=0
    continue
  fi
  ok "$f ($S2 bytes)"
done

[ "$ALL_OK" -eq 1 ] || exit 4

echo
ok "安装完成 -> $DEST"
printf '%b下一步：%b\n' "$C_INFO" "$C_RST"
case "$TARGET" in
  codebuddy) echo "  · 在 CodeBuddy 输入 /skills 确认已加载；或手动 /xiaoye-MapleStory-dev" ;;
  cursor)    echo "  · 在 Cursor 中确认 skill 已生效" ;;
  claude)    echo "  · 在 Claude Code 中输入 /xiaoye-MapleStory-dev" ;;
  agents)    echo "  · 通用目录，多个 Agent 共用此 skill" ;;
esac
echo "  · 工具链自检    : ./install.sh --check"
echo "  · 工具链与 MCP 接入详见仓库内 toolchain.md"
exit 0
