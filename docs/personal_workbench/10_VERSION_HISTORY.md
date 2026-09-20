# Personal Workbench 版本历史

本文只记录历史，不作为当前实现规范。

## Phase 1–3

建立 Workspace、Task、Current Task、Markdown Note、Entity Link、Activity、Issue、Resource、Decision、Home、Continue、Quick Capture、Focus、Today。

## Phase 4

增加 Knowledge、Knowledge Distill、SQLite FTS5 Search、Search Result Routing。

## Phase 5

增加 AI Context Builder、Context Budget、Prompt Builder、Global AI、AI Thread / Message History、OpenAI-compatible Provider。

## Phase 6

增加 Developer Project、Developer Command、Developer Snippet、Developer Context、Search Integration、AI Developer Context。

## Phase 7

增加 Settings、Backup、Export、Restore、Data Safety、Provider Settings。

## v1.4 UI Consolidation

完成 Global Shell、Home、Workspace、Knowledge、Time、Developer、Tools、Settings、Dark Mode、Windows Window / Login Polish。

v1.4 通过 PR #1 合并到 main。

## 2026-09-20 Codebase Cleanup

在 `refactor/personal-workbench-cleanup` 分支进行：

- 清理 cloud disk 历史业务代码。
- 删除无效旧路由。
- 规范目录和 Dart 文件名。
- 清理历史依赖。
- 删除本机绝对路径测试脚本。
- 增加基础单元测试。
- Tray 从 NetDisk 改为 Personal Workbench。
- 当前代码不再继续使用 Phase 历史命名。
- 新增长期编码规范。

这次调整以“减少历史包袱，不改变当前业务行为”为原则。


## 2026-09-20 Analyzer / Workspace Cleanup

继续完成：

- Flutter 3.47.4 下 Analyzer issue 从 33 个清到 0。
- 当前 `flutter analyze` 为 `No issues found`。
- 当前 `flutter test` 为 4 tests passed。
- 删除未被引用的旧 `workbench_workspace_pages.dart`。
- Workspace 当前代码去掉 `V2` 历史命名。
- 当前 Workspace 页面命名恢复为正常业务语义，不再同时维护旧版 / 新版概念。


## 2026-09-20 Workspace / Settings File Split

继续做低风险结构整理：

- Settings 页面按 Sections / Navigation / Appearance / Components 拆文件。
- Workspace Overview 按 Navigation / Overview Content 拆文件。
- 保留原有 private Widget 和行为，不为了拆文件扩大 public API。
- 使用 Dart `part / part of` 维持同一个 library 内部的封装边界。


## 2026-09-20 AI Context Builder Split

继续做 AI 核心链路结构整理：

- `AIContextBuilder` 对外接口保持不变。
- Task / Workspace / Knowledge / Global Scope 逻辑独立组织。
- Context 收集、Entity 映射、文本格式化分别拆开。
- 没有新增无意义的 Service / Manager 层。
- Context 优先级、数量限制、搜索范围、include / exclude 和输出内容保持原逻辑。


## 2026-09-20 Global AI Drawer Split - Step 1

先做低风险拆分：

- UI helper 移到 `global_ai_drawer_widgets.dart`。
- 纯格式化函数移到 `global_ai_drawer_formatters.dart`。
- State、Conversation、Context 操作仍保留在主文件。
- `_contextPreview` 因为直接涉及 `setState`，暂不强拆。
- 不改变 AI Drawer 的交互和业务行为。


## 2026-09-20 Home Page Split

继续整理首页代码：

- `workbench_home_page.dart` 保留加载、状态和整体布局。
- Current Focus / Progress 拆到 `workbench_home_focus.dart`。
- Today / Recent Activity 拆到 `workbench_home_panels.dart`。
- Drawer Layer、Loading / Error、内部数据模型和格式化 helper 拆到 `workbench_home_support.dart`。
- 不改变首页 UI、路由、数据来源和交互。


## 2026-09-20 Knowledge Page Split

继续整理 Knowledge 页面：

- 主文件保留 load / search / category / distill / editor orchestration。
- Knowledge Card / Search Result 拆到 `workbench_knowledge_cards.dart`。
- Knowledge Editor Dialog 拆到 `workbench_knowledge_editor.dart`。
- Entity Label 等 helper 拆到 `workbench_knowledge_support.dart`。
- 不改变 SearchService、KnowledgeService、Distill 和页面交互行为。


## 2026-09-20 Developer Page Split

继续整理 Developer 页面：

- 主文件只保留 Context load / refresh 和页面骨架。
- Project / Command / Snippet CRUD 与 Dialog 拆到 `workbench_developer_actions.dart`。
- Projects / Commands / Snippets / Resources 展示拆到 `workbench_developer_sections.dart`。
- Command Category Label 等 helper 拆到 `workbench_developer_support.dart`。
- 不改变 DeveloperService 调用、CRUD 行为、复制、归档和页面交互。


## 2026-09-20 Developer State Boundary Fix

Developer 页面拆分后继续修正 State 边界：

- Action extension 不再直接调用 `State.setState`。
- 页面 State 增加统一的 `_reloadState()` 状态刷新入口。
- 修复 Flutter Analyzer 的 7 个 `invalid_use_of_protected_member`。
- 编码规范补充：part / extension 拆分时，protected State API 必须留在 State 子类内部。


## 2026-09-20 Core Test Hardening - Step 1

开始从结构重构转向自动化测试：

- 新增 AI Context Budget 单元测试。
- 新增 SearchService rebuild 行为测试。
- 覆盖 Search freshness window。
- 覆盖并发 rebuild 合并，避免重复重建。
- 覆盖 Search 参数透传。
- 测试不依赖真实 SQLite、外网、个人路径。
