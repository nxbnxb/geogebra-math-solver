#!/usr/bin/env bash
# ==============================================
#  geogebra-math-solver 安装脚本
#  支持多种 AI 工具（WorkBuddy / Codex / Claude / Cursor 等）
# ==============================================
set -e

SKILL_NAME="geogebra-math-solver"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📐 GeoGebra Math Solver"
echo "======================="
echo ""

# —— 检测平台 ——
DETECTED=""
if [ -d "$HOME/.workbuddy/skills" ]; then
  DETECTED="workbuddy"
elif command -v codex &>/dev/null; then
  DETECTED="codex"
elif [ -d "$HOME/.cursor" ] || [ -d "$HOME/.cursor-server" ]; then
  DETECTED="cursor"
elif [ -d "$HOME/.claude" ]; then
  DETECTED="claude"
fi

# —— 选择安装目标 ——
echo "检测到平台: ${DETECTED:-未检测到}"
echo ""
echo "请选择安装目标:"
echo "  1) WorkBuddy  (~/.workbuddy/skills/)"
echo "  2) Codex      (~/.codex/)"
echo "  3) Cursor     (~/.cursorrules 自定义指令)"
echo "  4) Claude     (自定义指令)"
echo "  5) 通用       (仅复制 SKILL.md 到当前目录)"
echo "  0) 退出"
echo ""
read -p "请输入数字 [1-5]: " CHOICE

case "$CHOICE" in
  1)
    TARGET="$HOME/.workbuddy/skills/${SKILL_NAME}"
    mkdir -p "$TARGET"
    cp "$SCRIPT_DIR/SKILL.md" "$TARGET/SKILL.md"
    echo "✅ 已安装到 $TARGET/SKILL.md"
    echo "   上传数学题目截图即可自动触发。"
    ;;
  2)
    TARGET="$PWD"
    cp "$SCRIPT_DIR/adapters/codex.md" "$TARGET/.codex.md"
    echo "✅ 已生成 $TARGET/.codex.md"
    echo "   在 Codex 项目中会自动加载。"
    ;;
  3)
    TARGET="$PWD"
    cp "$SCRIPT_DIR/adapters/generic.md" "$TARGET/.cursorrules"
    echo "✅ 已生成 $TARGET/.cursorrules"
    echo "   在 Cursor 中会自动加载。"
    ;;
  4)
    TARGET="$PWD"
    cp "$SCRIPT_DIR/adapters/generic.md" "$TARGET/claude-instructions.md"
    echo "✅ 已生成 $TARGET/claude-instructions.md"
    echo "   将内容粘贴到 Claude Desktop 自定义指令。"
    ;;
  5)
    TARGET="$PWD"
    cp "$SCRIPT_DIR/SKILL.md" "$TARGET/SKILL.md"
    echo "✅ 已复制到 $TARGET/SKILL.md"
    echo "   根据你的 AI 工具手册放置此文件。"
    ;;
  0)
    echo "已取消。"
    exit 0
    ;;
  *)
    echo "无效选择，退出。"
    exit 1
    ;;
esac

echo ""
echo "🚀 使用方式：上传数学题目截图，说「帮我生成 GeoGebra 交互演示」。"
