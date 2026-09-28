#Requires -Version 5.1
<#
.SYNOPSIS
  安装 xiaoye-MapleStory-dev skill 到指定 Agent 平台的 skills 目录。

.DESCRIPTION
  把 SKILL.md / checklist.md / feature-doc-template.md / toolchain.md / ui-photoshop.md
  复制到 <目标 skills 根>/xiaoye-MapleStory-dev/。幂等，可重复执行。

  目标目录对照：
    平台        用户级 (user)                项目级 (project)
    codebuddy   ~/.codebuddy/skills/...      <项目>/.codebuddy/skills/...
    cursor      ~/.cursor/skills/...         <项目>/.cursor/skills/...
    claude      ~/.claude/skills/...         <项目>/.claude/skills/...
    agents      ~/.agents/skills/...         不支持（仅用户级）

.PARAMETER Target
  目标平台：codebuddy | cursor | claude | agents（默认 codebuddy）

.PARAMETER Scope
  作用域：user（用户级，默认）| project（项目级）

.PARAMETER ProjectPath
  Scope=project 时的项目根目录，默认当前目录。

.PARAMETER Force
  目标已存在同名文件时直接覆盖，不再询问。

.PARAMETER WhatIf
  演练：只打印将执行的动作，不写入任何文件。

.PARAMETER Check
  工具链自检：检测本机是否具备所需依赖（只检测，不自动安装）。

.EXAMPLE
  .\install.ps1 -Target codebuddy -Scope user

.EXAMPLE
  .\install.ps1 -Target codebuddy -Scope project -ProjectPath .

.EXAMPLE
  .\install.ps1 -Check
#>
param(
  [ValidateSet('codebuddy', 'cursor', 'claude', 'agents')]
  [string]$Target = 'codebuddy',

  [ValidateSet('user', 'project')]
  [string]$Scope = 'user',

  [string]$ProjectPath = '',

  [switch]$Force,
  [switch]$WhatIf,
  [switch]$Check
)

$ErrorActionPreference = 'Stop'

$SkillName  = 'xiaoye-MapleStory-dev'
$SkillFiles = @('SKILL.md', 'checklist.md', 'feature-doc-template.md', 'toolchain.md', 'ui-photoshop.md')
$SourceDir  = $PSScriptRoot
if (-not $SourceDir) { $SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path }

function Write-Info    { param([string]$m) Write-Host "[info] $m" -ForegroundColor Cyan }
function Write-Ok      { param([string]$m) Write-Host "[ ok ] $m" -ForegroundColor Green }
function Write-WarnMsg { param([string]$m) Write-Host "[warn] $m" -ForegroundColor Yellow }
function Write-ErrMsg  { param([string]$m) Write-Host "[fail] $m" -ForegroundColor Red }

function Get-UserHome {
  if ($env:USERPROFILE) { return $env:USERPROFILE }
  if ($HOME) { return $HOME }
  throw '无法解析用户主目录（USERPROFILE / HOME 均为空）'
}

# 依据 平台 + 作用域 计算目标 skill 目录（含 skill 名）
function Resolve-TargetDir {
  param([string]$T, [string]$S, [string]$Proj)

  if ($S -eq 'user') {
    $homeDir = Get-UserHome
    $sub = switch ($T) {
      'codebuddy' { '.codebuddy' }
      'cursor'    { '.cursor' }
      'claude'    { '.claude' }
      'agents'    { '.agents' }
    }
    $base = Join-Path (Join-Path $homeDir $sub) 'skills'
  }
  else {
    if ($T -eq 'agents') {
      throw '通用 .agents/skills 仅支持用户级（请使用 -Scope user）'
    }
    if ([string]::IsNullOrWhiteSpace($Proj)) { $Proj = (Get-Location).Path }
    if (-not (Test-Path -LiteralPath $Proj)) { throw "项目目录不存在: $Proj" }
    $root = (Resolve-Path -LiteralPath $Proj).Path
    $sub = switch ($T) {
      'codebuddy' { '.codebuddy' }
      'cursor'    { '.cursor' }
      'claude'    { '.claude' }
    }
    $base = Join-Path (Join-Path $root $sub) 'skills'
  }
  return (Join-Path $base $SkillName)
}

# 工具链自检：只检测与提示，不自动安装
function Check-Toolchain {
  Write-Info '工具链自检（仅检测，不自动安装；缺失项请按 toolchain.md 补齐）'
  Write-Host ''

  $checks = @(
    @{ Cmd = 'git';         Args = @('--version'); Desc = '版本控制' },
    @{ Cmd = 'java';        Args = @('-version');  Desc = 'JDK 21（服务端 / orange-wz）' },
    @{ Cmd = 'mvn';         Args = @('-v');        Desc = 'Maven' },
    @{ Cmd = 'node';        Args = @('-v');        Desc = 'Node v20.15.0 LTS（gms-ui）' },
    @{ Cmd = 'yarn';        Args = @('-v');        Desc = 'Yarn（gms-ui）' },
    @{ Cmd = 'mysql';       Args = @('--version'); Desc = 'MySQL 8' },
    @{ Cmd = 'uv';          Args = @('--version'); Desc = 'uv（IDA MCP）' },
    @{ Cmd = 'ida-pro-mcp'; Args = @('--help');    Desc = 'IDA MCP 服务' }
  )

  foreach ($c in $checks) {
    $found = Get-Command $c.Cmd -ErrorAction SilentlyContinue
    if (-not $found) {
      Write-Host ("  [ ] {0,-12} 缺失 — {1}" -f $c.Cmd, $c.Desc) -ForegroundColor Red
      continue
    }
    $ver = ''
    try {
      # java 的版本信息输出到 stderr，用 cmd 包裹最稳
      if ($c.Cmd -eq 'java') { $ver = (cmd /c "java -version 2>&1" | Select-Object -First 1) }
      else { $ver = (& $c.Cmd @($c.Args) 2>&1 | Select-Object -First 1) }
    }
    catch { $ver = '' }
    if (-not $ver) { $ver = '已安装' }
    Write-Host ("  [x] {0,-12} {1}" -f $c.Cmd, $ver) -ForegroundColor Green
    # 版本提示：服务端与 orange-wz 均需 JDK 21
    if ($c.Cmd -eq 'java' -and $ver -match 'version "(\d+)') {
      $major = [int]$Matches[1]
      if ($major -lt 21) {
        Write-Host ("  [!] {0,-12} 当前主版本 {1}，服务端 / orange-wz 需 JDK 21" -f 'java', $major) -ForegroundColor Yellow
      }
    }
  }

  Write-Host ''
  Write-WarnMsg '以下为重环境，需手动确认（自检不覆盖）：'
  Write-Host '  · Visual Studio 2019 + Windows SDK 10 + v142（编译插件 BeiDou-ijl15）'
  Write-Host '  · IDA Pro 8.3+（推荐 9）并已激活 idalib'
  Write-Host '  · MySQL 8 已启动（登录 8484 / API 8686 需服务端与库就绪）'
  Write-Host '  · orange-wz MCP 是否已启动（端口见 mcp-runtime/endpoint.json）'
  Write-Host '  · Adobe Photoshop + ~/.cursor/mcp.json 中 photoshop 项（见 toolchain.md §7）'
  Write-Host '  · （可选）dbx：用户同意后接入；~/.cursor/mcp.json 中 dbx 项（见 toolchain.md §8）'
  Write-Host ''
  Write-Info '完整获取 / 构建 / 启动 / MCP 接入步骤见 toolchain.md'
}

# ---------------- 主流程 ----------------

if ($Check) {
  Check-Toolchain
  exit 0
}

try {
  $dest = Resolve-TargetDir -T $Target -S $Scope -Proj $ProjectPath
}
catch {
  Write-ErrMsg $_.Exception.Message
  exit 2
}

Write-Info "源目录 : $SourceDir"
Write-Info "目标   : $dest"
Write-Info "平台   : $Target  作用域: $Scope"

# 校验源文件齐全
$missing = @()
foreach ($f in $SkillFiles) {
  if (-not (Test-Path -LiteralPath (Join-Path $SourceDir $f))) { $missing += $f }
}
if ($missing.Count -gt 0) {
  Write-ErrMsg ("源目录缺少文件: " + ($missing -join ', '))
  Write-ErrMsg "请在仓库根目录运行本脚本（或确认脚本与 SKILL.md 位于同一目录）"
  exit 3
}

# 目标已存在文件清单
$existing = @()
if (Test-Path -LiteralPath $dest) {
  foreach ($f in $SkillFiles) {
    if (Test-Path -LiteralPath (Join-Path $dest $f)) { $existing += $f }
  }
}

# 演练模式
if ($WhatIf) {
  Write-WarnMsg '演练模式（-WhatIf）：以下动作不会真正执行'
  Write-Host "  将创建目录 : $dest"
  foreach ($f in $SkillFiles) { Write-Host "  将复制     : $f" }
  if ($existing.Count -gt 0) {
    Write-Host ("  将覆盖     : " + ($existing -join ', ')) -ForegroundColor Yellow
  }
  exit 0
}

# 覆盖确认（-Force 跳过）
if ($existing.Count -gt 0 -and -not $Force) {
  $answer = Read-Host ("目标已存在 {0} 个同名文件，是否覆盖? [y/N]" -f $existing.Count)
  if ($answer -notmatch '^(y|yes)$') {
    Write-WarnMsg '已取消（未做任何修改）'
    exit 0
  }
}

# 复制
New-Item -ItemType Directory -Force -Path $dest | Out-Null
foreach ($f in $SkillFiles) {
  Copy-Item -LiteralPath (Join-Path $SourceDir $f) -Destination (Join-Path $dest $f) -Force
}

# 逐文件校验
$allOk = $true
foreach ($f in $SkillFiles) {
  $srcPath = Join-Path $SourceDir $f
  $dstPath = Join-Path $dest $f
  if (-not (Test-Path -LiteralPath $dstPath)) {
    Write-ErrMsg "复制失败: $f"
    $allOk = $false
    continue
  }
  $srcSize = (Get-Item -LiteralPath $srcPath).Length
  $dstSize = (Get-Item -LiteralPath $dstPath).Length
  if ($srcSize -ne $dstSize) {
    Write-ErrMsg "大小不一致: $f ($srcSize -> $dstSize)"
    $allOk = $false
    continue
  }
  Write-Ok "$f ($dstSize bytes)"
}

if (-not $allOk) { exit 4 }

Write-Host ''
Write-Ok "安装完成 -> $dest"
Write-Host '下一步：' -ForegroundColor Cyan
switch ($Target) {
  'codebuddy' { Write-Host '  · 在 CodeBuddy 输入 /skills 确认已加载；或手动 /xiaoye-MapleStory-dev' }
  'cursor'    { Write-Host '  · 在 Cursor 中确认 skill 已生效' }
  'claude'    { Write-Host '  · 在 Claude Code 中输入 /xiaoye-MapleStory-dev' }
  'agents'    { Write-Host '  · 通用目录，多个 Agent 共用此 skill' }
}
Write-Host '  · 工具链自检    : .\install.ps1 -Check'
Write-Host '  · 工具链与 MCP 接入详见仓库内 toolchain.md'
exit 0
