# GeoGebra 数学题目交互演示生成器

> 📐 AI 驱动的数学题目可视化工具。上传题目截图 → 自动生成带 GeoGebra 交互演示的 HTML 文件，每步附定理详解。

[![Platform](https://img.shields.io/badge/AI_Tools-Codex_|_Claude_|_Cursor_|_Any-brightgreen)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

---

## ✨ 能做什么

- 📸 上传数学题目截图，AI 自动分析题型和已知条件
- 🎨 生成分步 GeoGebra 交互演示（第 0 步展示已知条件，后续逐步推进）
- 📖 每步附「定理详解」：定理名称、完整表述、公式、应用方式
- 📚 全部定理汇总（去重，含首次出现位置）
- ✏️ 指令可编辑、单步执行、详细报错
- 🔄 fitView 自动自适应视图 + 纵横比修正（圆不会变椭圆）

**适用题型**：中考/高考几何、函数图像、解析几何、动点轨迹、几何变换等。

---

## 🚀 安装方式

### 方式一：一键安装

```bash
# macOS / Linux（直接复制）
mkdir -p ~/.workbuddy/skills/geogebra-math-solver/ && \
curl -fsSL https://raw.githubusercontent.com/nxbnxb/geogebra-math-solver/main/SKILL.md \
  -o ~/.workbuddy/skills/geogebra-math-solver/SKILL.md

# 或克隆后交互安装（自动检测平台）
git clone https://github.com/nxbnxb/geogebra-math-solver.git
cd geogebra-math-solver && ./install.sh

# Windows
# 下载后双击 install.bat
```

### 方式二：ClawHub 安装

```bash
# 如果已发布到 ClawHub
clawhub install geogebra-math-solver
```

或在 AI 工具中直接说：「帮我安装 geogebra-math-solver」。

### 方式三：手动安装

```bash
mkdir -p ~/.workbuddy/skills/geogebra-math-solver/
cp SKILL.md ~/.workbuddy/skills/geogebra-math-solver/SKILL.md
```

安装后上传数学题目截图即可自动触发。

---

## 🔧 适配其他 AI 工具

本仓库提供多个 AI 平台的适配器，开箱即用：

| 平台 | 使用方式 |
|------|----------|
| **AI 对话工具** | 安装根目录的 `SKILL.md`（见上方安装方式） |
| **Codex / OpenAI** | 将 `adapters/codex.md` 的内容放入 `.codex.md` 或系统提示词 |
| **Claude Desktop** | 将 `adapters/generic.md` 作为系统提示词 |
| **Cursor / Windsurf** | 将 `adapters/generic.md` 内容放入 `.cursorrules` 或自定义指令 |
| **任何 AI 工具** | 将 `adapters/generic.md` 粘贴到工具的「自定义指令」字段 |

> ⚠️ **所有适配器均为自包含文件**，不引用任何外部文件。可以直接复制使用。

---

## 📁 仓库结构

```
geogebra-math-solver/
├── SKILL.md              # 主技能文件（自包含，完整 HTML 模板 + 知识库）
├── install.sh            # 一键安装脚本（macOS / Linux）
├── install.bat           # 一键安装脚本（Windows）
├── README.md             # 本文件
└── adapters/
    ├── codex.md          # Codex / OpenAI 适配（自包含，含精简 HTML 模板）
    └── generic.md        # 通用适配（Claude / Cursor / Windsurf 等）
```

> 所有文件均自包含，无跨文件引用。直接复制单个文件即可使用。

---

## 📖 ClawHub 发布指南

如果想将此 Skill 发布到 ClawHub（AI 技能市场），让其他用户一键安装：

### 前置准备

```bash
# 1. 安装 ClawHub CLI
curl -fsSL https://clawhub.ai/install.sh | bash

# 2. 登录（需要 GitHub 账号）
clawhub login

# 3. 验证登录
clawhub whoami
```

### 首次发布

```bash
# 在仓库根目录执行
clawhub publish . --slug geogebra-math-solver --version 2.0.0
```

参数说明：
- `--slug`：技能唯一标识符（小写字母+数字+连字符）
- `--version`：语义化版本号
- `--tags`：逗号分隔标签，如 `latest,math,geogebra,education`
- `--changelog`：更新日志

### 更新版本

```bash
# 修改 SKILL.md 后，更新版本号重新发布
clawhub publish . --slug geogebra-math-solver --version 2.0.1 --changelog "新增动点轨迹支持"
```

### 审核要点

- ✅ SKILL.md 放在仓库根目录
- ✅ frontmatter 包含 `name` 和 `description`
- ✅ 技能可独立运行，不依赖外部 API Key
- ✅ 不包含恶意代码

审核通过后，其他用户即可在 AI 工具中搜索并安装。

---

## 💡 技术要点

### 内建 Bug 防御（6 个实测坑）

| 陷阱 | 原因 | 防御方案 |
|------|------|----------|
| **SetColor 全白** | evalCommand 的 RGB 范围是 0~1，传入 0~255 被截断为白色 | 模板 execCmd 自动拦截 SetColor 并路由到 JS API 的 setColor() (0~255) |
| **圆看不见** | `x(c)` / `y(c)` 对圆对象无效，触发 GeoGebra 错误弹窗 | fitView 从 getValueString 正则解析圆方程 `(x-h)²+(y-k)²=r²` |
| **Tangents 不存在** | GeoGebra 无复数形式的切点命令 | 只用 `Tangent(A, c)`（单数），圆外点切线手动解切点坐标 |
| **圆变椭圆** | 画布纵横比 ≠ 1:1 | fitView 末尾根据容器尺寸补偿纵横比 |
| **按钮只响应最后一步** | var 闭包捕获最终值 | renderSteps 用 let 块级作用域 |
| **STYLE_CMDS undefined** | 变量定义在调用之后 | 所有样式相关变量在 execCmd 之前定义 |

### 为什么需要本地服务器？

GeoGebra 的 `deployggb.js` 在 `file://` 协议下有跨域安全限制。通过 `http://localhost:8081` 访问可完全规避。生成的 HTML 已自带服务启动提示。

---

## ✅ 已验证的题目

- **2024 北京中考第 24 题**（圆综合大题）：15 步完整解题链路，切线→圆周角→辅助线→相似→DE=44

---

## 📄 License

MIT
