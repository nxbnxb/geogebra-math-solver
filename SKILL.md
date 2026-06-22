---
name: geogebra-math-solver
description: 分析数学题目截图，自动生成带交互式 GeoGebra 演示的 HTML 文件。AI 直接分析截图，生成每一步的 GeoGebra 指令并注入 HTML，每步附定理详解（定理名称、完整表述、公式、应用方式），支持全部定理汇总。用户拿到文件后通过本地服务器访问即可使用，无需任何配置或服务器。
---

# GeoGebra 数学题目交互演示生成器

## 核心原则

**AI 直接分析截图 → 生成含完整指令的 HTML → 自动启动本地服务器 → 通过 http://localhost 访问。**
- 不需要任何 API Key
- **需要启动一次性本地 HTTP 服务器**（解决 `file://` 跨域问题）
- 不需要安装任何软件（用系统自带 Python 或 Node.js）
- 通过 `http://localhost:8081` 访问，无跨域问题
- **指令可编辑**：每步指令可展开查看、编辑、保存并重试
- **详细报错**：指令执行失败时显示具体原因（对象未定义、语法错误、数值错误等）
- **定理详解**：每步附"📖 涉及 N 条定理"折叠面板，列出该步用到的定理名称、完整表述、公式、在本步的应用方式
- **全部定理汇总**：顶部"📖 全部定理"按钮弹出模态层，汇总展示本题所有定理

> ⚠️ **为什么需要本地服务器？**
> 浏览器对 `file://` 协议有跨域安全限制，GeoGebra 的 `deployggb.js` 无法正确加载。
> 通过 `http://localhost` 访问则完全规避此问题。

---

## 触发条件

当用户提供以下任意输入时触发本 Skill：
- 上传数学题目截图（几何、代数、函数、解析几何等）
- 说"帮我生成 GeoGebra"、"把这道题目做成交互演示"
- 直接粘贴题目文字 + 要求生成可视化

---

## 完整工作流程

### 第一步：AI 直接分析截图

**不需要调用任何外部 API。** AI 直接读取截图内容，提取：
1. **题目类型**：几何证明、函数绘图、解析几何、代数运算等
2. **已知条件**：所有给定的数值、坐标、角度、长度
3. **求解目标**：题目要证明什么、求什么
4. **解题步骤**：把解题过程分解为 4-8 个有序步骤

### 第二步：设计步骤结构（含第 0 步）

**必须包含"第 0 步"**：展示题目的原始已知条件和图形设定，让学生先看到题目长什么样，再逐步推进。

```
第 0 步：题目已知条件（展示题设，不解题）
第 1 步：第一个解题动作
第 2 步：第二个解题动作
...
第 N 步：得出结论
```

### 第三步：提取涉及的数学定理

**这是讲解型演示的关键步骤。** 分析解题过程中每一步用到的定理，填入 `theorems` 字段。

每条定理的结构：
```javascript
{
  name: "定理名称（简练）",
  statement: "定理的完整表述（教科书级别的严谨定义）",
  application: "在本步骤中如何应用的说明",
  formula: "数学表达式（可选，LaTeX格式）"
}
```

**定理收集原则：**
- 每个步骤最多 4 条定理（不要堆砌无关定理）
- 优先列出当前步骤**直接用到**的定理
- 同一题目前后重复的定理只在首次出现时列出详情，后续出现简要引用
- 核心定理（如圆周角定理、切线性质）必须写「完整表述 + 应用说明 + 公式」
- 简单定理（如中点公式）可以只写「表述 + 公式」

### 第四步：生成 GeoGebra 指令序列

将每个步骤翻译成 GeoGebra 指令。**必须使用英文命令名**，参考下方「完整指令参考」。

**坐标处理规则：**
- 默认坐标系范围建议：-8 ≤ x ≤ 6，-6 ≤ y ≤ 6
- 如果题目数值较大（如 AP=10, OA=20），按合适比例缩放（如 1/5）后再输入坐标
- 缩放后需要在文字标注中说明实际数值

### 第五步：生成完整的 HTML 文件 + 启动脚本

将题目信息 + 所有步骤指令 + 定理数据注入 HTML 模板，生成完整的 HTML 文件。

**写入工作目录**，文件名格式：`geogebra-<题目关键词>.html`

**同时生成启动脚本** `start-geogebra.command`（Mac 双击可执行）：
```bash
#!/bin/bash
cd "$(dirname "$0")"
python3 -m http.server 8081 &
sleep 2
open http://localhost:8081/geogebra-<题目关键词>.html
wait
```

### 第六步：启动本地服务器并展示结果

1. **启动 HTTP 服务器**（端口 8081，如果占用则换 8082、8083...）
   ```bash
   # 优先使用 Node.js（沙箱兼容性更好，Python 后台进程可能无法绑定端口）
   cd <工作目录>
   node -e "
   const http=require('http');
   const fs=require('fs');
   const path=require('path');
   http.createServer((req, res) => {
     const filePath = path.join(process.cwd(), path.basename(req.url) || 'index.html');
     fs.readFile(filePath, (err, data) => {
       if (err) { res.writeHead(404); res.end('Not Found'); return; }
       res.writeHead(200, {'Content-Type': 'text/html; charset=utf-8'});
       res.end(data);
     });
   }).listen(8081, () => console.log('Server running at http://localhost:8081'));
   "
   ```
   > ⚠️ **如果在沙箱环境中运行**，Node.js 后台进程可能无法绑定端口，需先获取网络权限。
   >
   > 推荐方式：将服务器脚本写入 `/tmp/serve.js`，然后用 Bash 工具启动：
   ```javascript
   // /tmp/serve.js
   const http = require('http');
   const fs = require('fs');
   const path = require('path');
   const PORT = 8081;
   const ROOT = process.cwd();
   http.createServer((req, res) => {
     const filePath = path.join(ROOT, path.basename(req.url) || 'index.html');
     fs.readFile(filePath, (err, data) => {
       if (err) { res.writeHead(404); res.end('Not Found'); return; }
       res.writeHead(200, {'Content-Type': 'text/html; charset=utf-8'});
       res.end(data);
     });
   }).listen(PORT, '127.0.0.1', () => console.log('Server running at http://127.0.0.1:' + PORT));
   ```
   然后用 `Bash` 工具（dangerouslyDisableSandbox: true）启动：
   ```bash
   node /tmp/serve.js &
   ```

2. **用 `present_files` 工具打开** `http://localhost:8081/geogebra-<题目关键词>.html`
3. 附上题目分析摘要（中文，3-5 句话）+ 涉及的定理数量
4. 说明：通过 `http://localhost:8081` 访问，无跨域问题；指令可编辑；每步附定理详解

---

## HTML 模板（必须采用此模板）

此模板使用 **GGBApplet + deployggb.js**，通过本地服务器访问（`http://localhost:8081`），无跨域问题。

**新功能（已内置）：**
1. ✅ **指令全量展示**：每步指令完整显示，不再截断
2. ✅ **指令可编辑**：每步有「编辑指令」按钮，点击后可修改指令并保存重试
3. ✅ **详细报错**：指令执行失败时显示具体原因（对象未定义、语法错误、数值错误等）
4. ✅ **执行状态标记**：每条指令执行后显示 ✓ 或 ✗，鼠标悬停可看错误详情
5. ✅ **定理详解**：每步附"📖 涉及 N 条定理"折叠面板，展示定理名称、完整表述、公式、在本步的应用方式
6. ✅ **全部定理汇总**：顶部"📖 全部定理"按钮弹出模态层，去重汇总展示本题所有定理及首次出现位置
7. ✅ **单步执行**：每步下方有「▶ 执行此步」按钮，可单独执行当前步骤（不重置已构图）
8. ✅ **自适应视图**：每次执行后自动根据所有点的坐标缩放视图，编辑坐标值后无需手动调整


## 完整 HTML 模板

> ⚠️ 以下模板必须完整保留，不可删减。模板已内建所有 Bug 防御（SetColor 路由、fitView 纵横比修正等）。


```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{TITLE}}</title>
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    body { font-family: -apple-system, "PingFang SC", "Microsoft YaHei", sans-serif; background:#f0f2f5; }
    .header { background:linear-gradient(135deg,#1a73e8,#4285f4); color:white; padding:14px 24px; }
    .header h1 { font-size:17px; font-weight:600; }
    .header p { font-size:12.5px; opacity:0.88; margin-top:5px; line-height:1.5; }
    .container { display:flex; height:calc(100vh - 56px); }
    .sidebar { width:420px; min-width:420px; background:white; border-right:1px solid #e0e0e0; display:flex; flex-direction:column; overflow:hidden; }
    .controls { padding:10px 14px; border-bottom:1px solid #e8e8e8; display:flex; gap:7px; flex-wrap:wrap; }
    .btn { border:none; padding:6px 13px; border-radius:6px; cursor:pointer; font-size:12.5px; font-weight:500; transition:all 0.18s; }
    .btn-primary { background:#1a73e8; color:white; }
    .btn-primary:hover { background:#1557b0; }
    .btn-secondary { background:#f1f3f4; color:#3c4043; }
    .btn-secondary:hover { background:#dde1e4; }
    .btn-theorem { background:#fef7e0; color:#e37400; border:1px solid #fdd663; }
    .btn-theorem:hover { background:#feefc3; }
    .btn-danger { background:#fce8e6; color:#c5221f; }
    .btn-danger:hover { background:#f8d7da; }
    /* 定理面板 */
    .thm-toggle { margin-left:27px; margin-top:5px; }
    .thm-toggle-link { font-size:11px; color:#e37400; cursor:pointer; text-decoration:none; display:inline-flex; align-items:center; gap:3px; }
    .thm-toggle-link:hover { text-decoration:underline; }
    .thm-toggle-link .arrow { font-size:9px; transition:transform 0.2s; }
    .thm-toggle-link.expanded .arrow { transform:rotate(90deg); }
    .thm-panel { margin-left:27px; margin-top:6px; display:none; }
    .thm-panel.show { display:block; }
    .thm-card { background:#fffbf0; border:1px solid #fdd663; border-radius:6px; padding:8px 10px; margin-bottom:6px; }
    .thm-card-name { font-size:12px; font-weight:600; color:#e37400; margin-bottom:4px; }
    .thm-card-name .badge { display:inline-block; background:#fdd663; color:#5f4b00; font-size:10px; padding:1px 6px; border-radius:3px; margin-right:4px; }
    .thm-card-statement { font-size:11px; color:#5f6368; line-height:1.45; margin-bottom:4px; padding-left:8px; border-left:2px solid #fdd663; }
    .thm-card-app { font-size:10.5px; color:#1a73e8; line-height:1.4; margin-top:4px; padding:4px 8px; background:#e8f0fe; border-radius:4px; }
    .thm-card-app::before { content:"🔗 本步应用："; font-weight:600; }
    .thm-card-formula { font-size:11px; font-family:"SF Mono","Fira Code",monospace; color:#188038; margin-top:4px; padding:3px 8px; background:#e6f4ea; border-radius:4px; }
    /* 全部定理模态 */
    .modal-overlay { position:fixed; inset:0; background:rgba(0,0,0,0.45); z-index:100; display:none; align-items:center; justify-content:center; }
    .modal-overlay.show { display:flex; }
    .modal { background:white; border-radius:12px; width:680px; max-height:80vh; display:flex; flex-direction:column; box-shadow:0 8px 40px rgba(0,0,0,0.2); }
    .modal-header { padding:16px 20px; border-bottom:1px solid #e0e0e0; display:flex; align-items:center; justify-content:space-between; }
    .modal-header h2 { font-size:15px; font-weight:600; }
    .modal-close { background:none; border:none; font-size:20px; cursor:pointer; color:#5f6368; padding:0 4px; }
    .modal-body { flex:1; overflow-y:auto; padding:16px 20px; }
    .modal-thm { background:#fffbf0; border:1px solid #fdd663; border-radius:8px; padding:12px 14px; margin-bottom:10px; }
    .modal-thm-name { font-size:14px; font-weight:600; color:#e37400; margin-bottom:6px; }
    .modal-thm-statement { font-size:12px; color:#5f6368; line-height:1.55; margin-bottom:6px; padding-left:10px; border-left:3px solid #fdd663; }
    .modal-thm-app { font-size:11px; color:#1a73e8; margin-top:6px; padding:6px 10px; background:#e8f0fe; border-radius:6px; line-height:1.45; }
    .modal-thm-meta { font-size:10.5px; color:#9aa0a6; margin-top:6px; }
    .steps-list { flex:1; overflow-y:auto; padding:4px 0; }
    .step { padding:10px 14px; border-bottom:1px solid #f0f0f0; cursor:pointer; transition:background 0.13s; }
    .step:hover { background:#f8f9fa; }
    .step.active { background:#e8f0fe; border-left:3px solid #1a73e8; }
    .step-num { display:inline-flex; align-items:center; justify-content:center; width:20px; height:20px; background:#1a73e8; color:white; border-radius:50%; font-size:10.5px; font-weight:600; margin-right:7px; flex-shrink:0; }
    .step.active .step-num { background:#1557b0; }
    .step.active .step-title { color:#0d47a1; }
    .step.active .step-desc { color:#37474f; }
    .step-title { font-size:13.5px; font-weight:500; color:#202124; }
    .step-desc { font-size:11.5px; color:#5f6368; margin-top:3px; margin-left:27px; line-height:1.35; }
    /* 指令列表样式 */
    .cmd-list { margin-top:6px; margin-left:27px; background:#f8f9fa; border:1px solid #e8e8e8; border-radius:5px; padding:6px 8px; max-height:180px; overflow-y:auto; }
    .cmd-item { font-size:11px; font-family:"SF Mono","Fira Code",monospace; color:#1a73e8; padding:2px 0; border-bottom:1px solid #eee; display:flex; align-items:flex-start; gap:4px; }
    .cmd-item:last-child { border-bottom:none; }
    .cmd-idx { color:#9aa0a6; font-size:10px; flex-shrink:0; margin-top:1px; }
    .cmd-text { flex:1; word-break:break-all; }
    .cmd-item.style-cmd { color:#888; font-style:italic; background:#f0f0f0; border-radius:3px; padding-left:4px; }
    .cmd-status { font-size:10px; flex-shrink:0; margin-left:4px; }
    .cmd-ok { color:#34a853; }
    .cmd-err { color:#ea4335; cursor:help; }
    /* 编辑区域样式 */
    .cmd-edit-area { margin-top:6px; margin-left:27px; }
    .cmd-textarea { width:100%; min-height:120px; font-size:11px; font-family:"SF Mono","Fira Code",monospace; color:#202124; border:1px solid #dadce0; border-radius:5px; padding:6px 8px; resize:vertical; line-height:1.4; }
    .cmd-textarea:focus { outline:none; border-color:#1a73e8; box-shadow:0 0 0 2px rgba(26,115,232,0.2); }
    .cmd-actions { margin-top:4px; display:flex; gap:5px; }
    .cmd-btn { border:none; padding:3px 10px; border-radius:4px; cursor:pointer; font-size:11px; font-weight:500; }
    .cmd-btn-save { background:#1a73e8; color:white; }
    .cmd-btn-cancel { background:#f1f3f4; color:#3c4043; }
    /* 错误面板 */
    .error-panel { margin-top:6px; margin-left:27px; background:#fce8e6; border:1px solid #f5c6cb; border-radius:5px; padding:8px 10px; font-size:11px; color:#c5221f; display:none; }
    .error-panel.show { display:block; }
    .ggb-area { flex:1; position:relative; background:white; }
    #ggb-app { width:100%; height:100%; border:none; }
    .loading { position:absolute; inset:0; display:flex; align-items:center; justify-content:center; background:rgba(255,255,255,0.94); font-size:14px; color:#5f6368; flex-direction:column; gap:11px; z-index:10; }
    .spinner { width:30px; height:30px; border:3px solid #e0e0e0; border-top-color:#1a73e8; border-radius:50%; animation:spin 0.75s linear infinite; }
    @keyframes spin { to { transform:rotate(360deg); } }
    .footer { padding:7px 14px; border-top:1px solid #f0f0f0; font-size:10.5px; color:#9aa0a6; text-align:center; }
  </style>
</head>
<body>

  <div class="header">
    <h1 id="title">📐 {{TITLE}}</h1>
    <p id="subtitle">{{DESC}}</p>
  </div>

  <div class="container">
    <div class="sidebar">
      <div class="controls">
        <button class="btn btn-primary" onclick="runAll()">▶ 运行全部</button>
        <button class="btn btn-secondary" onclick="resetAll()">↺ 重置</button>
        <button class="btn btn-theorem" onclick="showAllTheorems()">📖 全部定理</button>
      </div>
      <div class="steps-list" id="steps"></div>
      <div class="footer">GeoGebra 交互演示 · 可编辑指令 · 每步附定理详解</div>
  </div>

  <!-- 全部定理模态层 -->
  <div class="modal-overlay" id="theoremModal" onclick="if(event.target===this) hideAllTheorems()">
    <div class="modal">
      <div class="modal-header">
        <h2>📖 本题涉及的全部定理</h2>
        <button class="modal-close" onclick="hideAllTheorems()">✕</button>
      </div>
      <div class="modal-body" id="modalBody"></div>
    </div>
  </div>
    <div class="ggb-area">
      <div class="loading" id="loading"><div class="spinner"></div><span>GeoGebra 加载中...</span></div>
      <div id="ggb-app"></div>
    </div>
  </div>

  <script>
    // ====== 题目信息（由 AI 填充）======
    const PROBLEM_TITLE = "{{TITLE}}";
    const PROBLEM_DESC  = "{{DESC}}";

    // ====== 步骤数据（由 AI 填充）======
    // 每个 step 的 cmds 数组包含所有 GeoGebra 指令
    // 所有指令必须使用英文命令名
    const STEPS = [
      // 第 0 步（题目已知条件）—— 必须存在
      // {
      //   title: "题目已知条件",
      //   desc: "展示题设条件",
      //   cmds: ["A = (0, 0)", "B = (3, 0)"]
      // },
    ];

    // ====== 执行状态 ======
    let ggbApi = null;
    let stepResults = [];  // 每个步骤的执行结果 [{ok, err}, ...]

    // ====== 加载 GeoGebra ======
    function loadGGB() {
      const params = {
        appName: "classic",   // ← 关键：Classic 模式支持几何+代数所有指令（graphing 不支持 Circle/Segment 等）
        width: 1200,
        height: 800,
        showToolBar: true,
        showAlgebraInput: true,
        showMenuBar: false,
        showResetIcon: false,
        enableLabelDrags: true,
        enableShiftDragZoom: true,
        showZoomButtons: true,
        language: "zh_CN",
        appletOnLoad: function(api) {
          ggbApi = api;
          document.getElementById("loading").style.display = "none";
          if (STEPS.length > 0) executeUpTo(0);
        }
      };
      const ggb = new GGBApplet(params, true);
      ggb.inject("ggb-app");
    }

    // ====== 样式指令映射（API 方法而非 evalCommand）======
    // ⚠️ 关键：GeoGebra 的 evalCommand("SetColor(obj,R,G,B)") 使用 **0~1 的 RGB 范围**
    // 而 JS API 的 ggbApi.setColor(obj, R, G, B) 使用 **0~255 范围**
    // 因此 SetColor 等样式命令必须通过 JS API 调用，不能用 evalCommand
    // 否则传入 0~255 值会被截断为白色（#FFFFFF），导致对象不可见
    const STYLE_API_MAP = {
      'SetColor': { fn: 'setColor', parse: (args) => [args[0], parseInt(args[1]), parseInt(args[2]), parseInt(args[3])] },
      'SetLineThickness': { fn: 'setLineThickness', parse: (args) => [args[0], parseInt(args[1])] },
      'SetLineStyle': { fn: 'setLineStyle', parse: (args) => [args[0], parseInt(args[1])] },
      'SetPointStyle': { fn: 'setPointStyle', parse: (args) => [args[0], parseInt(args[1])] },
      'SetFilling': { fn: 'setFilling', parse: (args) => [args[0], parseFloat(args[1])] },
      'SetFixedSize': { fn: 'setFixedSize', parse: (args) => [args[0], parseInt(args[1])] },
      'SetCaption': { fn: 'setCaption', parse: (args) => [args[0], args[1]] },
      'ShowLabel': { fn: 'showLabel', parse: (args) => [args[0], parseInt(args[1])] },
      'Rename': { fn: 'renameObject', parse: (args) => [args[0], args[1]] },
    };

    function isStyleCmd(cmd) {
      const m = cmd.match(/^(\w+)\(/);
      return m && STYLE_API_MAP[m[1]];
    }

    function execStyleCmd(cmd) {
      const m = cmd.match(/^(\w+)\((.+)\)$/);
      if (!m) return { ok: false, err: "样式指令格式错误" };
      const name = m[1], argsStr = m[2];
      const spec = STYLE_API_MAP[name];
      if (!spec) return { ok: false, err: "未知的样式指令：" + name };
      const rawArgs = argsStr.match(/"[^"]*"|[^,]+/g) || [];
      const cleanArgs = rawArgs.map(a => a.trim().replace(/^"|"$/g, ''));
      const parsedArgs = spec.parse(cleanArgs);
      try {
        const fn = ggbApi[spec.fn];
        if (!fn) return { ok: false, err: "API 方法不存在：" + spec.fn };
        fn.apply(ggbApi, parsedArgs);
        return { ok: true, err: null };
      } catch(e) {
        return { ok: false, err: e.message || String(e) };
      }
    }

    // ====== 执行单条指令（带详细错误）======
    function execCmd(cmd, stepIdx, cmdIdx) {
      if (!ggbApi) return { ok: false, err: "GeoGebra 尚未加载" };
      // 样式指令走 API 方法，不走 evalCommand
      if (isStyleCmd(cmd)) return execStyleCmd(cmd);
      try {
        const result = ggbApi.evalCommand(cmd);
        if (result === false) {
          let detail = "指令执行失败";
          try { detail = ggbApi.evalCommandGetError(cmd) || detail; } catch(e2) {}
          return { ok: false, err: detail };
        }
        return { ok: true, err: null };
      } catch(e) {
        let msg = e.message || String(e);
        if (msg.includes("Undefined") || msg.includes("undefined")) {
          msg = "对象未定义（可能前一条指令静默失败，导致对象未创建）";
        } else if (msg.includes("Illegal") || msg.includes("syntax")) {
          msg = "指令语法错误（检查命令名是否英文、参数格式是否正确）";
        } else if (msg.includes("Number") || msg.includes("number")) {
          msg = "数值参数错误（检查坐标、数值是否合法）";
        }
        return { ok: false, err: msg };
      }
    }

    // ====== 执行到某步骤 ======
    function executeUpTo(target) {
      if (!ggbApi) { alert("GeoGebra 尚未加载完成，请稍候..."); return; }
      try { ggbApi.newConstruction(); } catch(e) {}

      stepResults = [];
      let hasError = false;
      let errorMsg = "";

      for (let i = 0; i <= target; i++) {
        const step = STEPS[i];
        const results = [];
        if (step.cmds) {
          for (let j = 0; j < step.cmds.length; j++) {
            const r = execCmd(step.cmds[j], i, j);
            results.push(r);
            if (!r.ok) {
              hasError = true;
              errorMsg += `步骤 ${i} 指令 ${j} 失败：${r.err}\n指令：${step.cmds[j]}\n\n`;
            }
          }
        }
        stepResults[i] = results;
      }

      const els = document.querySelectorAll(".step");
      for (let k = 0; k < els.length; k++) {
        els[k].classList.toggle("active", k <= target);
        updateCmdStatus(k);
      }

      if (hasError) {
        showError(errorMsg);
      } else {
        hideError();
        fitView();
      }
    }

    // ====== 自适应视图（修正纵横比 + 圆对象检测）======
    function fitView() {
      if (!ggbApi) return;
      try {
        const names = ggbApi.getAllObjectNames();
        let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
        let found = false;
        // 第一遍：收集点对象坐标
        for (let i = 0; i < names.length; i++) {
          try {
            const x = ggbApi.getXcoord(names[i]), y = ggbApi.getYcoord(names[i]);
            if (!isNaN(x) && !isNaN(y) && isFinite(x) && isFinite(y)) {
              minX = Math.min(minX, x); maxX = Math.max(maxX, x);
              minY = Math.min(minY, y); maxY = Math.max(maxY, y);
              found = true;
            }
          } catch(e) {}
        }
        // 第二遍：检测圆——从 getValueString 直接解析圆心和半径
        // ⚠️ 不能用 evalCommand("x(c)") — x()只用于点对象，对圆会触发GeoGebra报错对话框
        // getValueString 返回格式："c: x² + y² = 100" 或 "c: (x - 5)² + (y - 3)² = 16"
        for (let j = 0; j < names.length; j++) {
          try {
            const valStr = ggbApi.getValueString(names[j]);
            if (!valStr) continue;
            // 匹配圆方程末尾的 = r²
            const mR = valStr.match(/=\s*([\d.]+)\s*$/);
            if (!mR || !mR[1]) continue;
            const rSq = parseFloat(mR[1]);
            if (isNaN(rSq) || rSq <= 0) continue;
            const rad = Math.sqrt(rSq);
            let cx = 0, cy = 0;
            // 尝试匹配 (x ± h)² + (y ± k)² 形式
            const mC = valStr.match(/\(x\s*([+-])\s*([\d.]+)\)²\s*\+\s*\(y\s*([+-])\s*([\d.]+)\)²/);
            if (mC) {
              cx = (mC[1] === '-') ? parseFloat(mC[2]) : -parseFloat(mC[2]);
              cy = (mC[3] === '-') ? parseFloat(mC[4]) : -parseFloat(mC[4]);
            }
            // 否则 x² + y² 形式，圆心默认 (0,0)
            minX = Math.min(minX, cx - rad);
            maxX = Math.max(maxX, cx + rad);
            minY = Math.min(minY, cy - rad);
            maxY = Math.max(maxY, cy + rad);
            found = true;
          } catch(e2) {}
        }
        if (found) {
          let dxData = maxX - minX, dyData = maxY - minY;
          const MIN_SPAN = 20;
          if (dxData < 0.001) dxData = MIN_SPAN;
          if (dyData < 0.001) dyData = MIN_SPAN;
          const cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
          const padX = Math.max(dxData * 0.15, 5);
          const padY = Math.max(dyData * 0.15, 5);
          let x1 = cx - dxData/2 - padX, x2 = cx + dxData/2 + padX;
          let y1 = cy - dyData/2 - padY, y2 = cy + dyData/2 + padY;
          // 修正纵横比
          const w = ggbApi.getWidth(), h = ggbApi.getHeight();
          if (w && h && w > 0 && h > 0) {
            const canvasRatio = w / h;
            const dx = x2 - x1, dy = y2 - y1;
            if (dx > 0 && dy > 0) {
              const dataRatio = dx / dy;
              if (dataRatio > canvasRatio) {
                const newDy = dx / canvasRatio, extra = (newDy - dy) / 2;
                y1 -= extra; y2 += extra;
              } else if (dataRatio < canvasRatio) {
                const newDx = dy * canvasRatio, extra = (newDx - dx) / 2;
                x1 -= extra; x2 += extra;
              }
            }
          }
          // 安全兜底：至少30单位宽高
          if (x2 - x1 < 30) { const ex = (30 - (x2 - x1)) / 2; x1 -= ex; x2 += ex; }
          if (y2 - y1 < 30) { const ey = (30 - (y2 - y1)) / 2; y1 -= ey; y2 += ey; }
          ggbApi.setCoordSystem(x1, x2, y1, y2);
        } else {
          ggbApi.setCoordSystem(-20, 20, -20, 20);
        }
      } catch(e) {
        try { ggbApi.setCoordSystem(-20, 20, -20, 20); } catch(e2) {}
      }
    }

    // ====== 单独执行某一步（不重置构图）======
    function executeSingle(idx) {
      if (!ggbApi) { alert("GeoGebra 尚未加载完成，请稍候..."); return; }
      const step = STEPS[idx];
      if (!step.cmds || step.cmds.length === 0) return;
      const results = [];
      let hasError = false;
      let errorMsg = "";
      for (let j = 0; j < step.cmds.length; j++) {
        const r = execCmd(step.cmds[j], idx, j);
        results.push(r);
        if (!r.ok) { hasError = true; errorMsg += `步骤 ${idx} 指令 ${j} 失败：${r.err}\n指令：${step.cmds[j]}\n\n`; }
      }
      stepResults[idx] = results;
      const els = document.querySelectorAll(".step");
      for (let k = 0; k < els.length; k++) els[k].classList.toggle("active", k <= idx);
      updateCmdStatus(idx);
      if (hasError) showError(errorMsg); else { hideError(); fitView(); }
    }

    // ====== 运行全部 ======
    function runAll() {
      if (!ggbApi) { alert("GeoGebra 尚未加载完成，请稍候..."); return; }
      try { ggbApi.newConstruction(); } catch(e) {}
      for (let i = 0; i < STEPS.length; i++) {
        const idx = i;
        setTimeout(function() {
          const step = STEPS[idx];
          if (!step.cmds) return;
          const results = [];
          for (let j = 0; j < step.cmds.length; j++) {
            results.push(execCmd(step.cmds[j], idx, j));
          }
          stepResults[idx] = results;
          const els = document.querySelectorAll(".step");
          if (els[idx]) els[idx].classList.add("active");
          updateCmdStatus(idx);
        }, idx * 1200);
      }
      setTimeout(function() { fitView(); }, STEPS.length * 1200 + 200);
    }

    // ====== 重置 ======
    function resetAll() {
      if (!ggbApi) return;
      try { ggbApi.newConstruction(); } catch(e) {}
      const els = document.querySelectorAll(".step");
      for (let i = 0; i < els.length; i++) els[i].classList.remove("active");
      stepResults = [];
      if (STEPS.length > 0) {
        document.querySelectorAll(".step")[0].classList.add("active");
        executeUpTo(0);
      }
      hideError();
    }

    // ====== 指令状态显示 ======
    function updateCmdStatus(stepIdx) {
      const container = document.getElementById("step-cmds-" + stepIdx);
      if (!container) return;
      const results = stepResults[stepIdx];
      if (!results) {
        // 尚未执行，只显示指令文本
        return;
      }
      const cmds = STEPS[stepIdx].cmds;
      let html = "";
      for (let i = 0; i < cmds.length; i++) {
        const r = results[i];
        const statusClass = r ? (r.ok ? "cmd-ok" : "cmd-err") : "";
        const statusText = r ? (r.ok ? "✓" : "✗") : "";
        const errTitle = r && r.err ? ` title="${escapeHtml(r.err)}"` : "";
        html += `<div class="cmd-item">
          <span class="cmd-idx">${i}</span>
          <span class="cmd-text">${escapeHtml(cmds[i])}</span>
          <span class="cmd-status ${statusClass}"${errTitle}>${statusText}</span>
        </div>`;
      }
      container.innerHTML = html;
    }

    // ====== 编辑指令 ======
    function editStep(idx) {
      const wrap = document.getElementById("step-edit-" + idx);
      const list = document.getElementById("step-cmds-" + idx);
      if (!wrap || !list) return;
      wrap.style.display = "block";
      list.style.display = "none";
      const textarea = document.getElementById("step-textarea-" + idx);
      textarea.value = STEPS[idx].cmds.join("\n");
    }

    function saveStep(idx) {
      const textarea = document.getElementById("step-textarea-" + idx);
      const val = textarea.value.trim();
      const newCmds = val.split("\n").map(s => s.trim()).filter(s => s.length > 0);
      STEPS[idx].cmds = newCmds;

      const wrap = document.getElementById("step-edit-" + idx);
      const list = document.getElementById("step-cmds-" + idx);
      wrap.style.display = "none";
      list.style.display = "block";

      renderStepCmds(idx);

      // 如果当前步骤已执行，重新执行
      const activeEls = document.querySelectorAll(".step.active");
      let maxActive = -1;
      activeEls.forEach(el => {
        const idxAttr = el.getAttribute("data-idx");
        if (idxAttr) maxActive = Math.max(maxActive, parseInt(idxAttr));
      });
      if (maxActive >= idx) {
        executeUpTo(maxActive);
      }
    }

    function cancelEdit(idx) {
      const wrap = document.getElementById("step-edit-" + idx);
      const list = document.getElementById("step-cmds-" + idx);
      wrap.style.display = "none";
      list.style.display = "block";
    }

    // ====== 定理面板展开/折叠 ======
    function toggleTheorems(idx) {
      const panel = document.getElementById("thm-panel-" + idx);
      const link = document.getElementById("thm-link-" + idx);
      if (!panel) return;
      if (panel.classList.contains("show")) {
        panel.classList.remove("show");
        if (link) link.classList.remove("expanded");
      } else {
        panel.classList.add("show");
        if (link) link.classList.add("expanded");
      }
    }

    // ====== 全部定理模态 ======
    function showAllTheorems() {
      const modal = document.getElementById("theoremModal");
      const body = document.getElementById("modalBody");
      let html = "";
      // 收集去重后的所有定理
      const seen = {};
      const all = [];
      for (let i = 0; i < STEPS.length; i++) {
        const step = STEPS[i];
        if (step.theorems) {
          for (let j = 0; j < step.theorems.length; j++) {
            const thm = step.theorems[j];
            if (!seen[thm.name]) {
              seen[thm.name] = true;
              all.push({ ...thm, stepName: step.title });
            }
          }
        }
      }
      if (all.length === 0) {
        html = '<p style="color:#5f6368;text-align:center;padding:20px">暂无定理数据</p>';
      } else {
        for (let k = 0; k < all.length; k++) {
          const t = all[k];
          html += '<div class="modal-thm"><div class="modal-thm-name">' + (k+1) + '. ' + escapeHtml(t.name) + '</div>'
            + '<div class="modal-thm-statement">' + escapeHtml(t.statement) + '</div>';
          if (t.formula) html += '<div class="thm-card-formula" style="margin:4px 0">' + escapeHtml(t.formula) + '</div>';
          html += '<div class="modal-thm-app">' + escapeHtml(t.application) + '</div>'
            + '<div class="modal-thm-meta">首次出现在：' + escapeHtml(t.stepName) + '</div></div>';
        }
      }
      body.innerHTML = html;
      modal.classList.add("show");
    }

    function hideAllTheorems() {
      document.getElementById("theoremModal").classList.remove("show");
    }

    // ====== 渲染步骤的定理面板 ======
    function renderStepTheorems(idx) {
      const container = document.getElementById("thm-panel-" + idx);
      if (!container) return;
      const theorems = STEPS[idx].theorems || [];
      if (theorems.length === 0) { container.innerHTML = ""; return; }
      let html = "";
      for (let i = 0; i < theorems.length; i++) {
        const thm = theorems[i];
        html += '<div class="thm-card"><div class="thm-card-name"><span class="badge">定理</span>' + escapeHtml(thm.name) + '</div>'
          + '<div class="thm-card-statement">' + escapeHtml(thm.statement) + '</div>';
        if (thm.formula) html += '<div class="thm-card-formula">' + escapeHtml(thm.formula) + '</div>';
        html += '<div class="thm-card-app">' + escapeHtml(thm.application) + '</div></div>';
      }
      container.innerHTML = html;
    }

    // ====== 渲染步骤的指令列表 ======
    function renderStepCmds(idx) {
      const step = STEPS[idx];
      const container = document.getElementById("step-cmds-" + idx);
      if (!container) return;

      let html = "";
      const results = stepResults[idx] || [];
      for (let i = 0; i < step.cmds.length; i++) {
        const r = results[i];
        const statusClass = r ? (r.ok ? "cmd-ok" : "cmd-err") : "";
        const statusText = r ? (r.ok ? "✓" : "✗") : "";
        const errTitle = r && r.err ? ` title="${escapeHtml(r.err)}"` : "";
        const styleClass = isStyleCmd(step.cmds[i]) ? " style-cmd" : "";
        html += `<div class="cmd-item${styleClass}">
          <span class="cmd-idx">${i}</span>
          <span class="cmd-text">${escapeHtml(step.cmds[i])}</span>
          <span class="cmd-status ${statusClass}"${errTitle}>${statusText}</span>
        </div>`;
      }

      html += `<div style="margin-top:4px;display:flex;gap:5px;align-items:center;">
        <button class="cmd-btn" style="background:#e6f4ea;color:#188038;border:1px solid #ceead6;" onclick="event.stopPropagation();executeSingle(${idx})">▶ 执行此步</button>
        <button class="cmd-btn cmd-btn-save" onclick="editStep(${idx})">✎ 编辑指令</button>
      </div>`;

      container.innerHTML = html;
    }

    // ====== 错误面板 ======
    function showError(msg) {
      let panel = document.getElementById("error-panel");
      if (!panel) {
        panel = document.createElement("div");
        panel.id = "error-panel";
        panel.className = "error-panel show";
        document.querySelector(".steps-list").prepend(panel);
      }
      panel.className = "error-panel show";
      panel.innerHTML = `<strong>⚠️ 指令执行出错</strong><pre style="margin-top:6px;white-space:pre-wrap;font-size:11px;line-height:1.5">${escapeHtml(msg)}</pre>`;
    }

    function hideError() {
      const panel = document.getElementById("error-panel");
      if (panel) panel.className = "error-panel";
    }

    // ====== 渲染步骤列表 ======
    function renderSteps() {
      const container = document.getElementById("steps");
      container.innerHTML = "";
      for (let i = 0; i < STEPS.length; i++) {
        const idx = i;
        const step = STEPS[idx];
        const div = document.createElement("div");
        div.className = "step" + (idx === 0 ? " active" : "");
        div.setAttribute("data-idx", idx);
        div.onclick = function() { executeUpTo(idx); };

        // 定理折叠开关
        const thmCount = (step.theorems && step.theorems.length > 0) ? step.theorems.length : 0;
        let thmToggle = "";
        if (thmCount > 0) {
          thmToggle = '<div class="thm-toggle"><span class="thm-toggle-link" id="thm-link-' + idx + '" onclick="event.stopPropagation();toggleTheorems(' + idx + ')">'
            + '<span class="arrow">▶</span> 📖 涉及 ' + thmCount + ' 条定理</span></div>'
            + '<div class="thm-panel" id="thm-panel-' + idx + '"></div>';
        }

        let cmdHtml = "";
        if (step.cmds && step.cmds.length > 0) {
          cmdHtml = '<div class="cmd-list" id="step-cmds-' + idx + '">'
            + '</div>'
            + '<div class="cmd-edit-area" id="step-edit-' + idx + '" style="display:none">'
            + '<textarea class="cmd-textarea" id="step-textarea-' + idx + '" placeholder="每行一条 GeoGebra 指令"></textarea>'
            + '<div class="cmd-actions">'
            + '<button class="cmd-btn cmd-btn-save" onclick="saveStep(' + idx + ')">💾 保存并重试</button>'
            + '<button class="cmd-btn cmd-btn-cancel" onclick="cancelEdit(' + idx + ')">取消</button>'
            + '</div></div>';
        }

        div.innerHTML = '<div><span class="step-num">' + idx + '</span><span class="step-title">' + escapeHtml(step.title) + '</span></div>'
          + '<div class="step-desc">' + escapeHtml(step.desc) + '</div>'
          + thmToggle
          + cmdHtml;
        container.appendChild(div);

        // 渲染定理面板和指令列表
        if (thmCount > 0) renderStepTheorems(idx);
        if (step.cmds && step.cmds.length > 0) renderStepCmds(idx);
      }
    }

    function escapeHtml(s) {
      const d = document.createElement("div");
      d.textContent = s;
      return d.innerHTML;
    }

    // ====== 初始化 ======
    document.getElementById("title").textContent = "📐 " + PROBLEM_TITLE;
    document.getElementById("subtitle").textContent = PROBLEM_DESC;
    renderSteps();

    // 加载 GeoGebra
    const s = document.createElement("script");
    s.src = "https://www.geogebra.org/apps/deployggb.js";
    s.onload = loadGGB;
    document.head.appendChild(s);
  </script>
</body>
</html>
```
## 初中数学知识库（核心参考）

> **为什么需要这个？**
> AI 生成 GeoGebra 指令时，必须先理解数学概念的含义、性质和定理，才能正确构造图形。
> 例如"切线"不只是 `Tangent(A, c)` 一条命令，而是：
> 切线⊥半径 → 切点唯一 → 切线长定理(PA=PB) → 弦切角定理 → 一整套推理链。
> **本章节就是这些推理链的完整参考。**

### 一、圆（中考重点，占比最高）

#### 1.1 切线

**定义**：直线与圆只有一个公共点（切点），且切点处切线⊥半径。

**核心性质**：
- 切线⊥半径（过切点的半径垂直于切线）：OA⊥PA
- 切线长定理：从圆外一点 P 作两条切线 PA、PB，则 PA=PB，且 OP 平分∠APB
- 弦切角定理：弦切角 = 所夹弧所对的圆周角（∠PAB = ∠ACB，其中 C 在弧 AB 上）

**GeoGebra 构造**：

```
// ★ 圆上点的切线（最常见，A 在圆上）
Tangent(A, c)         // A 在圆 c 上，返回过 A 的切线
                       // ⚠️ 注意：Tangent 是 evalCommand 命令，不是 API 方法
                       // ⚠️ 如果 Tangent 静默失败，备选方案：
                       //   已知切点 A 和圆心 O → 切线方向⊥OA
                       //   例：OA 沿 x 轴（O=(0,0), A=(r,0)）→ 切线是 x=r 处的竖直线
                       //   可用 Line(A, (x(A), y(A)+1)) 但需确保方向⊥OA

// ★ 圆外点的切线（P 在圆外，这是中考题最常见的情形）
// ⚠️ GeoGebra 中没有 "Tangents" 复数命令！只有 "Tangent"（单数）
// 过圆外点 P 的两条切线需要：先求两个切点，再用 Tangent(切点, c)
//
// 方法：设切点 Q(x,y)，解方程组：
//   (1) Q 在圆上：Distance(Q, O) = r，即 (x - Ox)² + (y - Oy)² = r²
//   (2) OQ ⊥ PQ：向量 OQ·PQ = 0
// 解完后用 Tangent(Q, c) 得到切线
//
// 实际中考题中，如果 P 坐标和圆都已知，通常可以：
//   方法1：用代数解出切点坐标，定义点 Q1, Q2，然后 Line(P, Q1), Line(P, Q2)
//   方法2：如果圆是 x²+y²=r² 且 P=(xp, yp)，切点坐标有公式：
//         切点满足：Q = (r²/Px, r²/Py) 类型的投影（需根据具体情况计算）
```

**实际案例（北京中考第24题）**：
```
已知：圆 c: x²+y²=100（O=(0,0), r=10），P=(20,10) 在圆外
求：过 P 的两条切线

解法：
1. 设切点 A(x,y)，满足：
   x² + y² = 100      ...(1) A在圆上
   (x,y)·(x-20,y-10)=0 ...(2) OA⊥PA（向量点积=0）
2. 由(2)：x(x-20) + y(y-10) = 0 → x²-20x + y²-10y = 0
   代入(1)：100 - 20x - 10y = 0 → 2x + y = 10 → y = 10 - 2x
3. 代入(1)：x² + (10-2x)² = 100 → 5x² - 40x = 0 → x=0 或 x=8
   → A=(0,10), B=(8,-6)
4. GeoGebra 指令：
   A = (0, 10)
   B = (8, -6)
   PA = Line(P, A)    // 或 Tangent(A, c)
   PB = Line(P, B)    // 或 Tangent(B, c)
```

**常见题型推理链**：
```
题型：已知圆外点P和切线，求角度/长度
推理：
  ① P是圆外点 → PA,PB是切线 → PA⊥OA, PB⊥OB
  ② PA=PB（切线长定理）→ △OAP≌△OBP(HL) → OP平分∠APB
  ③ OA⊥PA → △OAP是直角三角形 → tan∠AOP = AP/OA

题型：证明某角等于某角（切线+圆周角）
推理：
  ① ∠PAB是弦切角 → ∠PAB = 弧AB所对的圆周角（弦切角定理）
  ② 或：∠ADB是圆周角 → ∠ADB = ½∠AOB（圆周角定理）
  ③ OP平分∠APB → ∠AOP = ½∠AOB
  ④ ∴ ∠ADB = ∠AOP（两者都等于½∠AOB）
```

#### 1.2 圆周角

**定义**：顶点在圆上，两边都和圆相交的角。

**核心定理**：
- 圆周角定理：圆周角 = ½同弧圆心角（∠ACB = ½∠AOB，C在圆上，A,B也在圆上）
- 同弧圆周角相等：同弧上的圆周角相等
- 半圆上的圆周角是直角：直径所对的圆周角 = 90°

**GeoGebra 构造**：
```
// 构造圆周角
Angle(A, C, B)              // ∠ACB，C是角的顶点（在圆上）
// 标注弧
Arc(c, A, B)                // 从A到B的弧
```

#### 1.3 弦与垂径定理

**定义**：连接圆上两点的线段叫弦。直径是最长的弦。

**垂径定理**：垂直于弦的直径，平分该弦及其所对的弧。
- 推论：弦的中垂线过圆心
- 推论：平分弦（不是直径）的直径垂直于该弦

**GeoGebra 构造**：
```
// 构造弦
AB_chord = Segment(A, B)    // A,B在圆上
// 弦的中垂线（过圆心）
midAB = Midpoint(A, B)
PerpendicularLine(midAB, AB_chord)
// 弦心距（圆心到弦的距离）
Distance(O, AB_chord)        // 或用坐标计算
```

#### 1.4 弧与扇形

**GeoGebra 构造**：
```
Arc(c, A, B)                // 圆c上从A到B的弧（逆时针）
Sector(c, A, B)             // 扇形
```

#### 1.5 圆与直线位置关系

| 关系 | 条件 | d=圆心到直线距离，r=半径 |
|------|------|--------------------------|
| 相离 | d > r | 无交点 |
| 相切 | d = r | 1个交点（切点） |
| 相交 | d < r | 2个交点 |

**GeoGebra 构造**：
```
// 直线与圆的交点
Intersect(c, line)           // 返回两个交点
Intersect(c, line, 1)        // 第1个交点
Intersect(c, line, 2)        // 第2个交点
```

#### 1.6 两圆位置关系

| 关系 | 条件 | d=圆心距，r,R=半径 |
|------|------|---------------------|
| 外离 | d > R+r | 0交点 |
| 外切 | d = R+r | 1交点 |
| 相交 | R-r < d < R+r | 2交点 |
| 内切 | d = R-r | 1交点 |
| 内含 | d < R-r | 0交点 |

**GeoGebra 构造**：
```
Intersect(c1, c2)            // 两圆交点
Intersect(c1, c2, 1)         // 第1个交点
Intersect(c1, c2, 2)         // 第2个交点
```

---

### 二、三角形

#### 2.1 全等三角形

**判定方法**：
- SSS：三边对应相等
- SAS：两边和夹角对应相等
- ASA：两角和夹边对应相等
- AAS：两角和对边对应相等
- HL：直角三角形中斜边和一直角边对应相等

**GeoGebra 构造**：
```
// 构造两个三角形并标注对应边/角
Polygon(A, B, C)
Polygon(D, E, F)
// 标注边长
Segment(A, B)  // 自动显示长度
Angle(A, B, C) // 自动显示角度
```

#### 2.2 相似三角形

**判定方法**：
- AA：两角对应相等
- SAS：两边对应成比例且夹角相等
- SSS：三边对应成比例

**性质**：
- 对应边之比 = 相似比 k
- 对应角相等
- 面积之比 = k²

**GeoGebra 构造**：
```
// 构造相似三角形
// 方法1：Dilate（缩放）
Dilate(Polygon(A,B,C), k, O)  // 以O为中心缩放k倍，得到相似三角形
// 方法2：直接按比例算坐标
// 如果△ABC ~ △DEF，相似比=k，则D,E,F的坐标可以按比例计算
```

**常见题型推理链**：
```
题型：求线段长度（相似三角形）
推理：
  ① 找出相似三角形（AA/SAS/SSS判定）
  ② 列出对应边比例关系：AC/EC = AO/ED
  ③ 代入已知值求解
```

#### 2.3 等腰三角形

**性质**：
- 两腰相等
- 两底角相等（等边对等角）
- 底边上的中线、高线、角平分线三线合一
- 是轴对称图形（对称轴是底边上的中线）

**GeoGebra 构造**：
```
// 方法1：利用对称
A = (0, 0)
B = (3, 0)
symAxis = Line(A, (0, 3))      // 底边中垂线
C = Reflect(B, symAxis)        // C是B关于中垂线的对称点 → 等腰△ABC
// 方法2：指定顶角和腰长
// 例：顶角60°，腰长3 → 等边三角形
```

#### 2.4 直角三角形

**性质**：
- 勾股定理：a² + b² = c²
- 斜边中线 = 斜边的一半
- 30°角对边 = 斜边的一半

**GeoGebra 构造**：
```
// 构造直角三角形（∠A=90°）
A = (0, 0)
B = (b, 0)         // AB沿x轴
C = (0, c)          // AC沿y轴 → ∠A=90°
Polygon(A, B, C)
// 标注边长
Distance(A, B)      // = b
Distance(A, C)      // = c  
Distance(B, C)      // = √(b²+c²) 验证勾股定理
```

#### 2.5 等边三角形

**性质**：
- 三边相等，三角都是60°
- 是特殊的等腰三角形
- 有3条对称轴

**GeoGebra 构造**：
```
// 边长为a的等边三角形
A = (0, 0)
B = (a, 0)
C = (a/2, a*sqrt(3)/2)
Polygon(A, B, C)
```

#### 2.6 三角形中位线

**性质**：中位线平行于第三边，且等于第三边的一半。

**GeoGebra 构造**：
```
// D,E分别是AB,AC的中点
D = Midpoint(A, B)
E = Midpoint(A, C)
Segment(D, E)               // 中位线DE = ½BC
// 验证：DE ∥ BC
ParallelLine(D, Segment(B,C)) // 过D平行BC的线 → 应与DE重合
```

---

### 三、四边形

#### 3.1 平行四边形

**性质**：
- 两组对边平行且相等
- 对角相等
- 对角线互相平分

**判定**：
- 两组对边平行 / 两组对边相等 / 一组对边平行且相等 / 对角线互相平分

**GeoGebra 构造**：
```
// 方法1：给定3个顶点
A = (0, 0); B = (4, 0); C = (3, 3)
D = A + C - B               // D = (0+3-4, 0+3-0) = (-1, 3)
Polygon(A, B, C, D)
// 方法2：对角线互相平分
O = (0, 0)                  // 对角线交点
A = (2, 1); C = (-2, -1)    // A和C关于O对称
B = (3, -1); D = (-3, 1)    // B和D关于O对称
```

#### 3.2 矩形

**性质**：平行四边形 + 四个角都是直角 + 对角线相等。

**GeoGebra 构造**：
```
A = (0, 0); B = (a, 0)
C = (a, b); D = (0, b)     // 矩形
```

#### 3.3 菱形

**性质**：平行四边形 + 四边相等 + 对角线互相垂直。

**GeoGebra 构造**：
```
// 对角线互相垂直且平分
O = (0, 0)
A = (d1/2, 0); C = (-d1/2, 0)    // 长对角线
B = (0, d2/2); D = (0, -d2/2)    // 短对角线
Polygon(A, B, C, D)
```

#### 3.4 正方形

**性质**：矩形 + 菱形（四边相等，四角直角）。

**GeoGebra 构造**：
```
A = (0, 0); B = (a, 0)
C = (a, a); D = (0, a)
Polygon(A, B, C, D)
```

#### 3.5 梯形

**性质**：只有一组对边平行。等腰梯形：两腰相等，对角线相等。

**GeoGebra 构造**：
```
// 直角梯形
A = (0, 0); B = (4, 0); C = (3, 3); D = (0, 3)
// 等腰梯形
A = (0, 0); B = (6, 0); C = (5, 3); D = (1, 3)
```

---

### 四、函数

#### 4.1 一次函数 y = kx + b

**性质**：
- k>0 递增，k<0 递减
- b 是 y 轴截距
- |k| 越大越陡

**GeoGebra 构造**：
```
f(x) = 2*x + 1              // 一次函数
Intersect(f, yAxis)          // y轴交点（截距b）
Intersect(f, xAxis)          // x轴交点（零点）
```

**常见题型**：
- 两直线交点：`Intersect(f, g)`
- 求直线与坐标轴围成三角形面积

#### 4.2 二次函数 y = ax² + bx + c

**性质**：
- 顶点坐标：(-b/2a, c-b²/4a)
- a>0 开口向上（最小值），a<0 开口向下（最大值）
- 对称轴：x = -b/2a
- Δ=b²-4ac：Δ>0两个零点，Δ=0一个零点，Δ<0无零点

**GeoGebra 构造**：
```
f(x) = a*x^2 + b*x + c     // 二次函数
A = Root(f)                  // 零点（与x轴交点）
V = Extremum(f)              // 顶点（最大/最小值点）
Vertex(f)                    // 顶点（更明确的命令）
AxisOfSymmetry(f)            // 对称轴
```

**常见题型推理链**：
```
题型：已知二次函数三点坐标，求解析式
推理：设 y=ax²+bx+c → 代入三点 → 解三元一次方程组 → 得a,b,c

题型：求二次函数与x轴交点围成面积
推理：求零点A,B → 面积 = ½|AB|·|顶点y值|
```

#### 4.3 反比例函数 y = k/x

**性质**：
- 图象是双曲线，关于原点对称
- k>0在一三象限，k<0在二四象限
- |k|越大离轴越远

**GeoGebra 构造**：
```
f(x) = k / x                // 反比例函数
```

---

### 五、解析几何

#### 5.1 两点距离公式

d = √((x₂-x₁)² + (y₂-y₁)²)

**GeoGebra**：
```
Distance(A, B)               // 自动计算
```

#### 5.2 中点公式

M = ((x₁+x₂)/2, (y₁+y₂)/2)

**GeoGebra**：
```
M = Midpoint(A, B)
```

#### 5.3 直线方程

- 两点式：过A(x₁,y₁), B(x₂,y₂) → Line(A, B)
- 点斜式：过A斜率k → `Line(A, k*x)` 或 `f(x) = k*(x - x₁) + y₁`
- 斜率计算：k = (y₂-y₁)/(x₂-x₁)

**GeoGebra**：
```
Line(A, B)                   // 过两点
f(x) = k*x + b              // 斜率截距式
Slope(Segment(A, B))         // 计算斜率
```

#### 5.4 角度与方向

**GeoGebra**：
```
Angle(A, O, B)               // ∠AOB（O是角的顶点）
Angle(A, O, B, true)         // 有向角（0°~360°）
Angle(A, O, B, 180°)         // 指定方向的角
```

---

### 六、三角函数（初中水平）

**定义**（直角三角形中）：
- sinα = 对边/斜边
- cosα = 邻边/斜边
- tanα = 对边/邻边

**特殊角值**：
| 角 | sin | cos | tan |
|----|-----|-----|-----|
| 30° | 1/2 | √3/2 | 1/√3 |
| 45° | √2/2 | √2/2 | 1 |
| 60° | √3/2 | 1/2 | √3 |

**GeoGebra**：
```
// 在直角三角形中标注三角函数
// 例：∠AOP，OA=邻边，AP=对边，OP=斜边
Angle(A, O, P)               // 标注角度
Text("sin∠AOP = AP/OP", (x, y))
Text("tan∠AOP = AP/OA", (x, y))
```

---

### 七、几何变换

#### 7.1 轴对称（翻折/镜像）

**性质**：对应点到对称轴的距离相等，对应线段相等，对应角相等。

**GeoGebra**：
```
B = Reflect(A, line)         // A关于直线line的对称点B
// ⚠️ Reflect 的第二参数必须是 Line（直线），不能是 Segment（线段）！
// 如果只有 Segment，先用 Line(端点1, 端点2) 转成直线
```

#### 7.2 旋转

**GeoGebra**：
```
B = Rotate(A, α, O)          // A绕O旋转α弧度
// ⚠️ α是弧度！60° = π/3 ≈ 1.047
// 如果要用角度值：Rotate(A, α° * π/180, O)
// 或 GeoGebra 自动转换：Rotate(A, 60°, O) ← 注意°符号
```

#### 7.3 平移

**GeoGebra**：
```
B = Translate(A, (dx, dy))   // A平移(dx,dy)到B
// 或用向量
v = Vector(A, C)              // 向量AC
B = Translate(A, v)           // A按向量v平移到B
```

#### 7.4 位似（缩放）

**GeoGebra**：
```
B = Dilate(A, k, O)          // 以O为中心缩放k倍
// k>1放大，0<k<1缩小，k<0反向缩放
```

---

### 八、动点问题（中考压轴常见）

**核心思想**：用 Slider（滑动条）模拟动点，用 Locus（轨迹）画出路径。

**GeoGebra 构造**：
```
// Step 1: 创建滑动条 t（参数）
t = Slider(0, 10, 0.1)       // 范围0~10，步长0.1
// Step 2: 用 t 定义动点坐标
P = (t, t^2)                 // 动点P沿抛物线运动
// Step 3: 画轨迹
Locus(P, t)                  // P随t变化的轨迹
// ⚠️ Locus的第二参数必须是 Slider（自由参数）
```

**常见题型**：
- 动点在边上运动 → `P = (A_x + t*(B_x-A_x), A_y + t*(B_y-A_y))`（t从0到1）
- 动点沿抛物线运动 → `P = (t, a*t^2 + b*t + c)`
- 求动点使某面积最大 → 用 Slider + Text 标注面积变化

---

### 九、角与平行线

#### 9.1 平行线性质

- 两直线平行 → 同位角相等、内错角相等、同旁内角互补

**GeoGebra**：
```
ParallelLine(A, line)        // 过A作line的平行线
PerpendicularLine(A, line)   // 过A作line的垂线
Angle(B, A, C)               // 标注角度
```

#### 9.2 角平分线

**性质**：角平分线上的点到角两边距离相等。

**GeoGebra**：
```
bisector = AngleBisector(A, O, B)  // ∠AOB的平分线
P = Intersect(bisector, something) // 平分线上的点
```

---

### 十、坐标系与视图控制

**GeoGebra**：
```
SetCoordSystem(xMin, xMax, yMin, yMax)  // 设置坐标范围
// ⚠️ 这是 API 方法，不是 evalCommand 命令！
// 需要通过 ggbApi.setCoordSystem() 调用
// 建议坐标范围：-8 ≤ x ≤ 6, -6 ≤ y ≤ 6
```

---

### 十一、文字标注与公式显示

**GeoGebra**：
```
// Text 命令（必须在 evalCommand 中使用）
Text("文字内容", (x, y))              // 在坐标(x,y)处显示文字
Text("文字内容", (x, y), true)        // true=固定位置（不随视图缩放移动）
Text("OA = 20", (5, 0.5))            // 标注线段长度
Text("∠ADB = ∠AOP ✓", (5, 3))       // 标注结论

// ⚠️ Text 中的引号：
// 在 JS 字理面写 GeoGebra Text 指令时，外层用单引号或转义双引号
// 正确：Text(\"OA = 20\", (5, 0.5))
// 错误：Text("OA = 20", (5, 0.5)) ← JS语法冲突

// LaTeX 公式（GeoGebra 支持）
Text("\frac{1}{2}", (5, 0.5))        // 显示 ½
```

---

### 十二、常见题型 → GeoGebra 构造模式速查

| 题型 | 核心概念 | GeoGebra 构造模式 |
|------|----------|-------------------|
| **圆的切线** | 切线⊥半径、切线长定理 | `Circle(O, r)` + `Tangent(A, c)` 或 `Tangents(P, c)` + `Reflect(A, Line(O,P))` |
| **圆周角** | 圆周角=½圆心角 | `Circle(O, r)` + `Angle(A, C, B)` + `Angle(A, O, B)` |
| **三角形全等** | SSS/SAS/ASA/AAS/HL | 两个 `Polygon` + `Angle` + `Segment` 标注对应边角 |
| **三角形相似** | AA/SAS/SSS | `Dilate(Polygon, k, O)` 或手动按比例算坐标 |
| **等腰三角形** | 等边对等角、三线合一 | `Reflect(B, symAxis)` 构造对称点 |
| **直角三角形** | 勾股定理 | 坐标轴上构造 + `Distance` 标注 |
| **二次函数** | 顶点、零点、对称轴 | `f(x) = ax²+bx+c` + `Root(f)` + `Extremum(f)` |
| **动点问题** | 参数化运动 | `Slider(t)` + 参数化坐标 + `Locus(P, t)` |
| **解析几何** | 直线方程、交点 | `f(x)=kx+b` + `Intersect(f, g)` |
| **几何变换** | 对称、旋转、缩放 | `Reflect` + `Rotate` + `Dilate` |
| **梯形中位线** | 中位线=½(上底+下底) | `Midpoint` + `Segment` |

---

## 完整指令参考

> ⚠️ **所有命令必须使用英文名称**

### 点的定义
```
A = (0, 0)            // 自由点
M = Midpoint(A, B)    // 中点
```

### 线和线段
```
Segment(A, B)              // 线段
Line(A, B)                 // 直线
PerpendicularLine(A, line) // 过点A的垂线
ParallelLine(A, line)      // 过点A的平行线
PerpendicularBisector(A, B) // 中垂线
AngleBisector(A, B, C)    // ∠ABC平分线
```

### 圆
```
Circle(O, 3)           // 圆心O半径3
Circle(O, B)           // 圆心O过B点
Tangent(A, c)          // 过A（在圆上）的切线
                       // ⚠️ 不存在 Tangents 复数指令！
                       // 过圆外点P的切线需先求切点再 Tangent
```

### 多边形
```
Polygon(A, B, C)          // 三角形
RigidPolygon(A, B, C)    // 刚体三角形（边长不变）
```

### 交点
```
Intersect(line1, line2)    // 交点
Intersect(c, line)         // 圆与直线交点
```

### 变换
```
Reflect(obj, line)         // 轴对称
Rotate(obj, α, O)         // 绕O旋转α度
Translate(obj, v)          // 平移
Dilate(obj, k, O)         // 以O为中心缩放k倍
```

### 函数
```
f(x) = x^2 + 2*x + 1  // 定义函数
Root(f)                   // 零点
Extremum(f)               // 极值点
Derivative(f)             // 导数
Integral(f, a, b)        // 定积分
```

### 轨迹
```
Locus(P, A)              // P随A运动的轨迹（A必须是自由点）
```

### 样式

> ⚠️ **重要：样式指令必须用 JS API，不能用 evalCommand！**
> GeoGebra 的 `SetColor`/`SetLineThickness` 等是 **API 方法**，不是输入栏命令。
> - `evalCommand("SetColor(c, 66, 133, 244)")` → RGB 范围是 **0~1**，传入 >1 的值被截断为白色 ❌
> - `ggbApi.setColor("c", 66, 133, 244)` → RGB 范围是 **0~255** ✅
>
> 模板 `execCmd` 函数已内置拦截器，自动把 `SetColor(...)` 命令路由到 JS API。
> **AI 生成指令时仍写 `SetColor(c, 66, 133, 244)` 即可**，执行时会自动修正。

```
SetColor(obj, r, g, b)       // ✅ 写在 cmds 数组里，AI 生成时用 0~255 范围
                              //    执行时 execCmd 会自动调用 ggbApi.setColor(obj, r, g, b)
SetLineThickness(obj, n)     // 线宽（API 方法，0~10）
SetLineStyle(obj, n)         // 线型（API 方法，0=实线, 1=虚线, 2=点线）
SetPointStyle(obj, n)        // 点样式（API 方法，0=圆点, 1=十字, 2=叉, ...）
SetFilling(obj, a)           // 填充透明度（API 方法，0=无填充, 1=全填充）
```

**常用颜色（0~255 范围，AI 生成时用这些值）：**
```
蓝色（圆/主线）：  SetColor(c, 66, 133, 244)    // #4285F4
红色（切线/重点）：SetColor(tangent, 234, 67, 53) // #EA4335
绿色（辅助线）：   SetColor(aux, 52, 168, 83)    // #34A853
黄色（标注）：     SetColor(label, 251, 188, 4)  // #FBBC04
紫色（交点）：     SetColor(point, 156, 39, 176) // #9C27B0
```

---

## 常见错误

> 💡 **这些错误都是实际踩过的坑，生成指令前务必检查！**

| 错误 | 正确 |
|------|------|
| 用中文命令名 | 必须用英文 |
| **appName: "graphing" 不支持几何指令** | `Circle`、`Segment`、`Reflect`、`Intersect` 等几何命令在 graphing 模式全部失败！必须用 `appName: "classic"` |
| **SetColor 颜色全白（RGB 范围错误）** | `evalCommand("SetColor(c, 66, 133, 244)")` 中 RGB 范围是 **0~1**，传入 >1 的值被截断为白色 `#FFFFFF`！<br>✅ 正确：在 `execCmd` 中拦截 `SetColor(` 命令，改用 `ggbApi.setColor(obj, R, G, B)`（JS API 使用 0~255 范围）。模板 `execCmd` 已内置正则拦截器 `/^SetColor\s*\(\s*(\w+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)$/` |
| **`x(c)` / `y(c)` 对圆对象无效** | `x()` 和 `y()` 函数只能用于**点对象**，对圆调用会触发 GeoGebra 弹出"请检查输入内容"错误对话框。<br>fitView() 中必须从 `getValueString` 解析圆心坐标（正则匹配 `(x - h)² + (y - k)²` 或 `x² + y²`），**不能调用 evalCommand 创建临时对象** |
| **evalCommand 不抛异常** | `evalCommand()` 失败时返回 `false` 而非抛异常！必须检查返回值，用 `evalCommandGetError(cmd)` 获取详情 |
| **不存在 `Tangents` 复数命令** | GeoGebra 只有 `Tangent`（单数）。过圆外点 P 的两条切线需先求两个切点坐标，再用 `Tangent(切点, c)` 或 `Line(P, 切点)` |
| **步骤间对象依赖顺序错误** | 后续步骤不能引用尚未创建的对象。<br>❌ 错误：第11步用 `E`（但 E 在第12步才创建）→ 必须交换步骤11/12顺序 |
| **`renderSteps` 循环用 `var` 产生闭包捕获** | `for (var i=0; i<STEPS.length; i++)` 中 `var idx = i` 会被所有迭代共享，循环结束后 `idx` 恒为最终值，导致所有步骤点击都执行 `executeUpTo(最终值)`。<br>✅ 正确：用 IIFE 包裹 `(function(idx){ ... })(i)` 或用 `let`（块级作用域） |
| **`STYLE_CMDS` 定义在 `execCmd` 之后** | `var` 声明提升但赋值不提升，`execCmd` 中引用 `STYLE_CMDS` 会得到 `undefined`。<br>✅ 正确：把 `STYLE_CMDS` 定义放在 `execCmd` 之前（模板已修复） |
| **`fitView()` 只有点对象时圆不可见** | 只有圆心 O 一个点有坐标时，`getXcoord("c")` 对 Circle 返回 NaN，`fitView` 完全依赖 MIN_SPAN 兜底。<br>✅ 正确：fitView 必须两遍扫描——第一遍收集点坐标，第二遍从 `getValueString` 解析圆方程获取圆心和半径 |
| **MIN_SPAN 太小导致圆被纵向裁切** | 只有1个点时 dxData 被设为 MIN_SPAN，但纵横比修正可能压缩 y 范围。<br>❌ 旧版：MIN_SPAN=14, dyData=14×0.7=9.8 → 修正后 y∈[-7.9,7.9]，半径10的圆上下被裁<br>✅ 新版：MIN_SPAN=24，确保视口足够大 |
| **Text 中对象名引用语法** | 在 GeoGebra Text 指令中引用对象用名称（如 `Text("OA=" + OA, (5,0))`），不是 `Text("OA=" + x(O), ...)`。<br>如果只是要显示坐标，用 `x(O)` 是安全的 GeoGebra 表达式 |
| **旋转角度单位** | `Rotate(A, α, O)` 中 α 是**弧度**！60° = π/3 ≈ 1.047。<br>GeoGebra 输入栏支持 `Rotate(A, 60°, O)`（°符号），但 evalCommand 中推荐用弧度值 |
| **Reflect 的第二参数必须是 Line** | `Reflect(point, segment)` 会失败！必须用 `Line(O, P)` 把线段转成直线再作为反射轴 |
| 坐标太大撑爆视图 | 缩放坐标，建议范围 -8~6（或按比例缩放后标注实际数值） |

---

## 输出规范

`STEPS` 数组格式（**含 theorems 字段**）：

```javascript
const STEPS = [
  {
    title: "题目已知条件",
    desc: "已知直角三角形 ABC，∠A=90°，AB=3，AC=4",
    cmds: ["A = (0, 0)", "B = (3, 0)", "C = (0, 4)"],
    theorems: [
      {
        name: "勾股定理",
        statement: "直角三角形中，两直角边的平方和等于斜边的平方：a² + b² = c²。",
        application: "由AB=3, AC=4，计算斜边BC = √(3²+4²) = 5。",
        formula: "BC² = AB² + AC² = 9 + 16 = 25 → BC = 5"
      }
    ]
  },
  {
    title: "连接各边",
    desc: "画出三角形的三条边",
    cmds: ["Segment(A, B)", "Segment(A, C)", "Segment(B, C)"],
    theorems: []  // 无新定理时为空数组
  }
];
```

**theorems 字段规范：**
- `name`：定理名称，简练准确（如"切线性质"而非"圆的切线的性质定理"）
- `statement`：定理完整表述，教科书级别严谨
- `application`：在当前步骤中如何应用，必须具体（写出数值、指出图形元素）
- `formula`：数学表达式（可选），用纯文本写，不需要 LaTeX 渲染
- 每个步骤最多 4 条定理，同一题目前后重复的定理不重复写详情

---

## 质量检查清单

生成 HTML 前，确认：

**基础结构：**
- [ ] 第 0 步已添加（展示题目已知条件，不解题）
- [ ] 所有坐标合理（范围 -8~6，或已按比例缩放并标注实际数值）
- [ ] 指令无依赖错误（后续步骤不引用尚未创建的对象）
- [ ] 所有命令使用英文
- [ ] 题目信息已填入 `{{TITLE}}` 和 `{{DESC}}`

**定理详解：**
- [ ] **每个步骤已填写 theorems 字段（关键检查项）**
- [ ] 核心定理（圆相关的定理、全等/相似判定等）有完整表述+应用+公式
- [ ] 简单定理（中点公式、距离公式）至少有表述+公式
- [ ] 无新定理的步骤 theorems 为空数组 `[]`
- [ ] 每步 theorems 数量 ≤ 4 条（不堆砌无关定理）

**UI 功能：**
- [ ] HTML 可通过 `http://localhost:8081` 访问（无跨域问题）
- [ ] 指令可编辑（每步有「编辑指令」按钮）
- [ ] 定理可展开（每步有「📖 涉及 N 条定理」折叠面板）
- [ ] 全局「📖 全部定理」按钮可弹出模态层展示所有定理汇总
- [ ] 每步有「▶ 执行此步」按钮，用 `event.stopPropagation()` 防止触发步骤点击
- [ ] `fitView()` 函数已在 `executeUpTo`/`executeSingle`/`runAll` 成功后调用
- [ ] 出错时有详细错误信息（显示在具体步骤旁，而非只有全局 alert）

**JS 代码质量：**
- [ ] `renderSteps` 循环用了 IIFE 包裹（或用 `let` 替代 `var`），防止闭包捕获最终值
- [ ] `STYLE_CMDS`/`STYLE_API_MAP` 定义在 `execCmd` 之前（或在 `execCmd` 内不依赖外部变量）
- [ ] `execCmd` 函数已拦截 `SetColor(` 命令并路由到 `ggbApi.setColor()`（JS API，0~255 范围）
- [ ] `fitView()` 函数两遍扫描：第一遍收集点坐标，第二遍从 `getValueString` 解析圆方程
- [ ] `fitView()` 中**没有** `evalCommand("x(" + circleName + ")")` 调用（对圆无效）
- [ ] 隐藏元素 `#error-panel` 已在 HTML 中定义（或在 `showError()` 中动态创建）
- [ ] `.cmd-textarea` 的 `min-height` ≥ 120px（确保 8 条指令可见）

**GeoGebra 指令正确性：**
- [ ] 圆外点切线：先求切点坐标，再用 `Line(P, 切点)` 或 `Tangent(切点, c)`，不用 `Tangents`
- [ ] 样式指令写在 cmds 数组里即可（`SetColor(c, 66, 133, 244)`），`execCmd` 会自动路由
- [ ] 旋转命令 `Rotate(A, α, O)` 中 α 用弧度值（如 `Math.PI/3`），不用角度符号 `°`
- [ ] `Reflect(点, 轴)` 中轴必须是 `Line`（不是 `Segment`）

**实测验证（推荐在生成后用 playwright-cli 检查）：**
- [ ] 页面加载后 0 个 GeoGebra 错误对话框（`document.querySelectorAll('.dialogComponent').length === 0`）
- [ ] 圆 C 颜色正确（`ggbApi.getColor('c')` 返回非 `#FFFFFF` 的值）
- [ ] 「运行全部」后所有步骤执行成功（0 错误）
- [ ] 编辑指令后「保存并重试」能正确重新执行
