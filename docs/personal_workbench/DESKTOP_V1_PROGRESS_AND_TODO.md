# Personal Workbench — Windows Desktop V1 Progress & Todo

> 本文是 Personal Workbench Windows Desktop V1 的总进度与剩余工作基线。后续开发、验收与封版都按本文节奏推进，避免继续零散追加功能。
>
> Canonical UI Reference: `personal_workbench_full_v1_4_global_ai.html`
> Settings Detail Reference: `personal_workbench_full_v1_3_settings.html`
> 如原型之间存在冲突，以 `v1_4_global_ai` 为准。

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
| Workbench Core UI Pass | Home / Workspace / Knowledge / AI / Settings | ✅ 已完成 |
| Full App UI Implementation | Tools / Image / RAG / Game / Legacy Surfaces | 🟡 进行中 |
| Windows Final Acceptance | Restore / Regression / Analyze | 🔴 未完成 |
| Desktop V1 Baseline | 最终封版 | 🔴 未完成 |
| Phase 8 | Mobile Adaptation | ⏳ 未开始 |

当前整体判断：

```text
核心功能        基本完成
数据安全        接近完成
Workbench UI    已完成核心链路
全应用 UI       仍在进行
最终验收        暂缓
Desktop V1      先完成全部 UI 后再进入功能验收
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

### 4.1 Full App UI Implementation

当前最高优先级。Workbench 核心链路已经完成第一轮统一，但并不代表全应用 UI 已完成。

新的 UI First 顺序：

```text
UI.A Workbench Core                         ✅
    Home / Workspace / Knowledge / AI / Settings

UI.B Productivity Tools                     🟡
    Todo / Speed Test / JSON / Text Compare

UI.C Image Workbench                        🔴
    Convert / Watermark / Crop / Filter / Collage / Dedupe

UI.D RAG Knowledge                          🔴

UI.E Game                                   🔴

UI.F Legacy / Hidden Surfaces Review        🔴
    File / Photo / Share / Profile / Favorites / Recent
    Recycle / Device / Capacity / Subscribe / Password

UI.G Full App Responsive + State Review     🔴
    Resize / Long Text / Empty / Loading / Error
```

统一设计基线：

```text
Compact / Low Noise
统一 App Shell / Header / Page Title
统一 Content Max Width / Page Padding / Section Spacing
统一 Card Radius / Border / Typography Hierarchy
主操作位置一致
减少解释性文字，只保留标题 / 状态 / 关键数据 / 内容 / 操作
Tools 统一为工作台模式，不再每页一套视觉
Input / Output / Result / History 采用一致布局
Empty / Loading / Error / Success 状态一致
```

原则：先完成所有用户可见 UI，再继续功能细化与最终验收。

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
① Full App UI Implementation
   ├─ Workbench Core                ✅
   ├─ Productivity Tools
   ├─ Image Workbench
   ├─ RAG Knowledge
   ├─ Game
   ├─ Legacy / Hidden Surfaces Review
   └─ Full App Responsive / State Review

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
Full App UI Implementation
UI.B Productivity Tools
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

UI.2 Workspace
- 工作区列表统一
- Workspace 顶部 Tabs 统一
- Overview / Current Task 重排
- Task / Note / Issue / Resource / Decision 统一
- Developer Context 统一
- Windows 本机截图验收通过

UI.3 Knowledge + Search
- Knowledge / Search 单页结构统一
- 主搜索入口收口
- 知识卡片 / 分类 / 空状态统一
- Knowledge Editor 中文化
- Windows 本机验收通过

UI.4 AI
- Global AI Drawer 外壳统一
- Scope / Anchor Controls 统一
- Context Preview / Manage 统一
- Empty / Message / Thinking / Failure 状态统一
- Composer / History / Add Context 统一
- Windows 本机截图验收通过

UI.5 Settings Final Polish
- Settings 外壳 / 左侧导航统一
- General / Appearance / Notes / Shortcuts 收口
- AI Provider 设置中文化
- Data & Backup / Export / Restore 收口
- 主导航高亮修正
- Windows 本机截图验收通过

UI.6 Windows Resize / Long Text / Empty / Loading / Error Review
- Windows 窄窗口响应式切换通过
- AI Drawer 窄窗口布局通过
- 长路径换行与长标题截断加固
- Empty State 窄窗口布局加固
- Data & Backup 设置行响应式加固
- 未发现异常横向滚动 / 控件挤压
- Windows 本机截图验收通过

基础 UI 能力
- WorkbenchPage / WorkbenchSectionPage 响应式水平留白
- WorkbenchPageHeader 窄窗口 actions 堆叠
- WorkbenchCard 统一 radius / background / border
- WorkbenchInfoBlock 公共信息块
```

当前下一步：

```text
UI.B Productivity Tools
1. Todo UI
2. Speed Test UI
3. JSON Formatter UI
4. Text Compare UI
5. 四个工具统一 Page Shell / Input / Result / Action / Empty 状态

然后继续：
UI.C Image Workbench
UI.D RAG Knowledge
UI.E Game
UI.F Legacy / Hidden Surfaces Review
UI.G Full App Responsive / State Review

P7.7 Windows Final Acceptance 暂缓到全部 UI 完成之后。
```

## 9. 状态维护规则

后续每完成一个 Final Pass 子阶段，都更新本文的 Status / Completed / Pending / Known Issue / Next Step。任何新需求如果不属于当前 Desktop V1 封版范围，默认进入 Backlog，不直接打断 Final Pass 主线。
