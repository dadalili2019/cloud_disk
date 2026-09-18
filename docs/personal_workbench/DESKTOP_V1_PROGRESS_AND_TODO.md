# Personal Workbench — Windows Desktop V1 Progress & Todo

> 本文是 Personal Workbench Windows Desktop V1 的总进度与剩余工作基线。后续开发、验收与封版都按本文节奏推进，避免继续零散追加功能。

## 1. 产品目标

Personal Workbench 是一个本地优先的工作上下文系统，核心不是通用 Todo，而是帮助用户重新进入工作时快速恢复上下文：

```text
Workspace
  ↓
Current Task
  ├─ Note
  ├─ Issue
  ├─ Resource
  ├─ Decision
  └─ Knowledge
```

并在此基础上扩展 Home / Continue / Quick Capture / Focus、Knowledge + Search、AI Context、Developer Context、Settings、Backup、Export、Restore。

Windows Desktop V1 的封版目标：

```text
功能完整
+ 本地数据可恢复
+ 全局 UI 统一
+ Windows 实机回归通过
+ Baseline 固化
```

## 2. 阶段总体进度

| 阶段 | 内容 | 状态 |
|---|---|---|
| Phase 1 | Workspace / Task / Note / Entity Link / Overview | ✅ 已完成 |
| Phase 2 | Issue / Resource / Decision / Archive | ✅ 已完成 |
| Phase 3 | Home / Continue / Quick Capture / Focus / Today | ✅ 已封版 |
| Phase 4 | Knowledge + Search | ✅ 已封版 |
| Phase 5 | AI Context / Global AI / AI History | ✅ 已封版 |
| Phase 6 | Developer Context / Project / Command / Snippet | ✅ 已封版 |
| Phase 7 | Settings / Backup / Export / Restore | 🟡 功能实现基本完成，待最终验收 |
| Desktop V1 UI Final Pass | 全应用 UI 统一收口 | 🟡 UI.1 已完成，UI.2 进行中 |
| Windows Final Acceptance | Restore / Regression / Analyze | 🔴 未完成 |
| Desktop V1 Baseline | 最终封版 | 🔴 未完成 |
| Phase 8 | Mobile Adaptation | ⏳ 未开始 |

当前整体判断：

```text
核心功能        基本完成
数据安全        接近完成
整体 UI         进入系统收口
最终验收        未完成
Desktop V1      约 80%~85%
```

## 3. 已完成能力

```text
Workspace / Task / Current Task / Note / Entity Link
Issue / Resource / Decision / Archive
Home / Continue / Quick Capture / Focus / Today
Knowledge Markdown / FTS5 / BM25 Search
AI Context Builder / Budget / PromptBuilder / Global AI / History
Developer Project / Command / Snippet / Dev Resource
General / Appearance / Notes / AI / Data & Backup / Shortcuts
Manual Backup / Auto Backup / Safety Backup
Portable Export / Windows Save-As
Restore Validation / Pending Restore / Restart Apply / Search Rebuild
```

## 4. Desktop V1 Blockers

### 4.1 Desktop V1 UI Final Pass

当前最大剩余工作。过去 UI 按 Phase 分散实现，现在需要从整个产品视角统一收口。

执行顺序：

```text
UI.1 Global Shell + Home
UI.2 Workspace
UI.3 Knowledge + Search
UI.4 AI
UI.5 Settings Final Polish
UI.6 Windows Resize / Long Text / Empty / Loading / Error Review
```

统一检查：

```text
Sidebar / Header / Page Title
Content Max Width / Page Padding / Section Spacing
Card Radius / Border / Typography Hierarchy
Button Placement / Helper Text Density / Form Width
Empty / Loading / Error State
Scrollbar / Long Text / Narrow Window / Light-Dark Theme
```

原则：不重新设计产品、不改变已确认功能边界、不因视觉调整重写业务架构。

### 4.2 Notes Unsaved Protection

`Auto Save = OFF` 时需要补齐页面切换 / Note 切换边界的未保存保护。Desktop V1 优先采用 boundary save：不做 debounce 自动保存，但保留 Save / Ctrl+S，并在离开边界保护内容。

### 4.3 Restore Windows 实机验收

```text
Create Backup
→ 修改明显数据
→ Select Backup
→ Validation
→ Confirmation
→ Safety Backup
→ Pending Restore
→ 完全退出 App
→ 重新启动
→ 恢复到 Backup 状态
→ Search 正常
→ AI Context 正常
```

### 4.4 Phase 1–7 Final Smoke Regression

```text
Home
Workspace
Task
Note
Issue
Resource
Decision
Knowledge
Search
Developer
AI Drawer / History
Settings
Backup
Export
Restore
```

### 4.5 Final Flutter Analyze

```powershell
flutter analyze
```

封版标准：无 Desktop V1 Final Pass 新增 compile error。历史 info / warning 不要求在 V1 一次性清零。

### 4.6 Phase 7 / Desktop V1 Baseline

```text
Update PHASE7_ACCEPTANCE.md
→ Finalize PHASE7_BASELINE.md
→ Record final commit SHA
→ Seal Phase 7
→ Windows Desktop V1 Complete
```

## 5. 非阻塞 Backlog

```text
DeepSeek 真实 API Key 联调
Windows Secure Storage 保存 API Key
Global Search / Quick Capture / Open AI 全局快捷键
Danger Zone / Reset Local Data
历史 flutter analyze warning 清理
更多自动化测试
Developer Search 精确定位到具体卡片
Search Index 编辑后即时同步优化
AI Context relevance ranking
Snippet 大内容裁剪策略
更丰富的 Empty / Error / Loading 状态
```

## 6. Phase 8 — Mobile Adaptation

Windows Desktop V1 封版后单独进入，预计关注 Responsive Navigation、Mobile Layout、Touch Interaction、Small-screen Forms、AI Drawer 和 Workspace Navigation 的移动端行为。

## 7. 最终执行顺序

```text
① Desktop V1 UI Final Pass
   ├─ Global Shell + Home
   ├─ Workspace
   ├─ Knowledge + Search
   ├─ AI
   └─ Settings Final Polish

② Notes Unsaved Protection
③ Restore Windows Full Verification
④ Optional DeepSeek Real Connection Verification
⑤ Phase 1–7 Final Smoke Regression
⑥ flutter analyze
⑦ Update PHASE7_ACCEPTANCE.md
⑧ Finalize PHASE7_BASELINE.md
⑨ Windows Desktop V1 Complete
```

## 8. 当前下一步

当前正式进入：

```text
Desktop V1 UI Final Pass
UI.2 Workspace
```

工作内容：

```text
检查当前 Flutter Shell / Home
统一 Header / Sidebar / Content Width / Padding / Card Hierarchy
减少多余说明文字
检查 Home Continue / Current Task / Quick Capture / Today / Focus 的层级
处理 Resize / Scroll / Empty State
```

当前已确认完成：

```text
UI.1 Global Shell + Home
- Sidebar 路由高亮同步
- Topbar / Current Context 收口
- Home Current Task 主卡重排
- Quick Capture 简化
- Focus / Today 视觉统一
- Windows 本机截图验收通过

基础 UI 能力
- WorkbenchPage / WorkbenchSectionPage 响应式水平留白
- WorkbenchPageHeader 窄窗口 actions 堆叠
- WorkbenchCard 统一 radius / background / border
- WorkbenchInfoBlock 公共信息块
```

当前下一步：

```text
UI.2 Workspace
1. 工作区列表统一 WorkbenchPage / WorkbenchCard
2. Workspace 顶部 Tabs 统一视觉
3. Overview / Current Task 重排
4. Task / Note / Issue / Resource / Decision 统一布局
5. Developer Context 统一视觉
6. Windows 本机截图验收 UI.2
```

## 9. 状态维护规则

后续每完成一个 Final Pass 子阶段，都更新本文的 Status / Completed / Pending / Known Issue / Next Step。任何新需求如果不属于当前 Desktop V1 封版范围，默认进入 Backlog，不直接打断 Final Pass 主线。
